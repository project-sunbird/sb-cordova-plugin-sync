    import Foundation
    
    @objc(SyncPlugin) class SyncPlugin : CDVPlugin {
        private static var TAG: String = "Cordova-Plugin-SYNC"
        private var mDbService: DbService?
        private var mNetworkQueue: NetworkQueue?
        private var mPreferenceService: PreferenceService?
        private var isSyncing: Bool = false
        private var isUnauthorizedErrorThrown: Bool = false
        private var mTraceId = ""
        private var mLastEvent: [String: Any]? = [:]
        private var mHandler : [String]?
        private var mLiveHandler: [String]?
        
        private func stringifyJSON(_ input: [String: Any]) -> String? {
            do {
                let data = try JSONSerialization.data(withJSONObject: input, options: .prettyPrinted)
                guard let result = String(data: data, encoding: .utf8) else {
                    print("ERROR: failed to cast data as string")
                    return nil
                }
                return result
            } catch let err {
                print("error with " + #function + ": " + err.localizedDescription)
                return nil
            }
        }
        
        override func pluginInitialize() {
            self.mHandler = []
            self.mLiveHandler = []
            self.mDbService = DbServiceImpl()
            self.mNetworkQueue = NetworkQueueImpl(mDbService!)
            self.mPreferenceService = PreferenceServiceImpl()
            if let traceId = mPreferenceService!.getTraceId() {
                self.mTraceId = traceId
            }
        }
        
        @objc
        func sync(_ command: CDVInvokedUrlCommand) {
            let dispatchGroup = DispatchGroup()

            var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
            self.commandDelegate.run(inBackground: {
                self.mNetworkQueue?.seed()
                while !self.mNetworkQueue!.isEmpty() {
                    self.isSyncing = false
                    if let networkQueueModel = self.mNetworkQueue!.peek() {
                        let request = networkQueueModel.getRequest()
                        if let host = request["host"] as? String, let path = request["path"] as? String, let type = request["type"] as? String {
                            let url = URL(string: host + path)!
                            var urlRequest = URLRequest(url: url)
                            urlRequest.httpMethod = type
                            
                            if let requestBody = request["body"]{
                                if let serializer = request["serializer"] as? String {
                                    if serializer.lowercased().elementsEqual("raw") {
                                        urlRequest.httpBody = Data(base64Encoded: requestBody as! String)
                                    } else if serializer.lowercased().elementsEqual("json") {
                                        urlRequest.httpBody = self.stringifyJSON(requestBody as! [String: Any])?.data(using: .utf8)
                                    }
                                }
                            }
                            
                            if let headers = request["headers"] as? [String: String] {
                                for (key, value) in headers {
                                    print(key, value)
                                    // if !["Accept", "Content-Type"].contains(key) {
                                        urlRequest.addValue(value, forHTTPHeaderField: key)
                                    // }
                                }
                            }
                        
                            let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: {(data, response, error) in
                                guard let data = data, let response = response as? HTTPURLResponse else {
                                    print(String(describing: error))
                                    return
                                }
                                do {
                                    let responseJSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                                    let statusCode = response.statusCode
                                    if let responseJSON = responseJSON {
                                        if statusCode >= 200 && statusCode <= 300 {
                                            self.handlePostAPIActions(networkQueueModel.getType(), response, responseJSON)
                                            self.mNetworkQueue?.dequeue(false)
                                            self.publishSuccessResult(networkQueueModel, responseJSON)
                                            dispatchGroup.leave()
                                        } else if statusCode == 400 {
                                            self.publishEvent("error", "BAD_REQUEST")
                                            self.mNetworkQueue?.dequeue(true)
                                            dispatchGroup.leave()
                                        } else if statusCode == 403 || statusCode == 401 {
                                            let failedCount = networkQueueModel.getFailedCount()
                                            if failedCount >= 2  {
                                                if !self.isUnauthorizedErrorThrown {
                                                    self.isUnauthorizedErrorThrown = true
                                                    if !self.isSametoken(networkQueueModel, responseJSON, response) {
                                                        self.publishAuthErrorEvents(responseJSON, response.statusCode)
                                                    }
                                                    self.handleUnAuthorizedError(networkQueueModel, response, responseJSON)
                                                    self.mNetworkQueue?.dequeue(true)
                                                } else {
                                                    self.handleUnAuthorizedError(networkQueueModel, response, responseJSON)
                                                    self.mNetworkQueue?.dequeue(true)
                                                }
                                            } else {
                                                let failedCount = networkQueueModel.getFailedCount()
                                                let updatedFailedCount = failedCount + 1
                                                networkQueueModel.setFailedCount(updatedFailedCount)
                                                self.handleUnAuthorizedError(networkQueueModel, response, responseJSON)
                                                var request = networkQueueModel.getRequest()
                                                request["noOfFailureSync"] = updatedFailedCount
                                                self.mDbService?.update("msg_id", [networkQueueModel.getId()], ["request": self.stringifyJSON(request)])
                                                self.mNetworkQueue?.dequeue(true)
                                            }
                                            dispatchGroup.leave()
                                        } else if statusCode == -3 {
                                            let type = networkQueueModel.getType()
                                            self.publishEvent(type + "_error", "NETWORK_ERROR")
                                            self.mNetworkQueue?.dequeue(true)
                                            dispatchGroup.leave()
                                        } else {
                                            let type = networkQueueModel.getType()
                                            //TODO get error from response
                                            self.publishEvent(type + "_error", "NETWORK_ERROR")
                                            self.mNetworkQueue?.dequeue(true)
                                            dispatchGroup.leave()
                                        }
                                    }
                                } catch let error {
                                    print(error)
                                    self.isSyncing = false
                                }
                            })
                            dispatchGroup.enter()
                            task.resume()
                            dispatchGroup.wait()
                        }
                    }
                }
            })
        }
        
        @objc
        func enqueue(_ command: CDVInvokedUrlCommand) {
            var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
            let data = command.arguments[0]
            var request = command.arguments[1] as! [String: Any]
            let shouldSync = command.arguments[2] as! Bool
            guard data != nil && request != nil && shouldSync != nil else {
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            self.commandDelegate.run(inBackground: {
                if let networkRequest = request["request"] as? String {
                    do {
                        var networkRequestObject = try JSONSerialization.jsonObject(with: networkRequest.data(using: .utf8)!, options: .allowFragments) as? [String: Any]
                        
                        if let serializer = networkRequestObject!["serializer"] as? String {
                            if serializer.lowercased().elementsEqual("raw") {
                                networkRequestObject?["body"] = (data as! NSData).base64EncodedString(options: [])
                            } else if serializer.lowercased().elementsEqual("json") {
                                networkRequestObject?["body"] = data as! [String: Any]
                            }
                        }
                        
                        if let networkRequestObjectStringified = self.stringifyJSON(networkRequestObject!) {
                            request["request"] = networkRequestObjectStringified
                            if let _ = self.mDbService?.insert(request) {
                                if shouldSync && !self.isSyncing {
                                    self.sync(command)
                                }
                            }
                        }
                        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK)
                        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                    } catch let error {
                        print(error)
                        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                    }
                }
            })
        }
        
        @objc
        func onSyncSucces(_ command: CDVInvokedUrlCommand) {
            if let _ = self.mHandler {
                self.mHandler?.append(command.callbackId)
            }
        }
        
        @objc
        func onAuthorizationError(_ command: CDVInvokedUrlCommand) {
            if let _ = self.mLiveHandler {
                self.mLiveHandler?.append(command.callbackId)
            }
        }
        
        
        private func publishEvent(_ key: String, _ value: Any) {
            self.mLastEvent = [key: value]
            self.consumeEvents()
        }
        
        private func postProcessTelemetrySync(_ httpResponse: [String: Any]) {
            if let result = self.mDbService?.read("SELECT value from no_sql where key = 'last_synced_device_register_is_successful'") {
                if let row = result.first {
                    let isDeviceRegisterSuccesfullDBObj = row
                    if let isDeviceRegisterSuccesfull = isDeviceRegisterSuccesfullDBObj["value"] as? String {
                        if isDeviceRegisterSuccesfull.lowercased().elementsEqual("false") {
                            if let ets = httpResponse["ets"] {
                                let serverTime = (ets as! NSNumber).uint64Value
                                let now = UInt64(Date().timeIntervalSince1970)
                                let currentOffset = serverTime - now
                                let allowedOffset = currentOffset > 86400000 ? currentOffset : 0
                                if allowedOffset > 0 {
                                    var insertObj: [String: String] = [:]
                                    insertObj["key"] = "telemetry_log_min_allowed_offset_key"
                                    insertObj["value"] = String(allowedOffset)
                                    self.mDbService?.insert(insertObj)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        public func publishSuccessResult(_ networkQueueModel: NetworkQueueModel, _ response: [String: Any]) {
            let config = networkQueueModel.getConfig()
            let type = networkQueueModel.getType()
            if let canPublishResult = config?["shouldPublishResult"] as? Bool {
                if canPublishResult {
                    if type.lowercased().elementsEqual("telemetry") {
                        self.publishEvent("syncedEventCount", networkQueueModel.getEventCount())
                    } else if type.lowercased().elementsEqual("course_progress") {
                        if let result = response["result"] {
                            self.publishEvent("courseProgressResponse", result as Any)
                        }
                    } else if type.lowercased().elementsEqual("course_assesment") {
                        if let result = response["result"] {
                            self.publishEvent("courseAssesmentResponse", result as Any)
                        }
                    }
                }
            }
        }
        
        private func handleUnAuthorizedError(_ networkQueueModel: NetworkQueueModel, _ httpResponse: HTTPURLResponse, _ responseObject: [String: Any]) {
            
            var request = networkQueueModel.getRequest()
            if var requestHeaders = request["headers"] as? [String: Any] {
                if self.isApiTokenExpired(responseObject, httpResponse.statusCode) {
                    if let token = self.mPreferenceService?.getBearerToken() {
                        requestHeaders["Authorization"] = "Bearer " + token
                    }
                }else {
                    if let userToken = self.mPreferenceService?.getUserToken() {
                        requestHeaders["X-Authenticated-User-Token"] = userToken
                    }
                    if let managedUserToken = self.mPreferenceService?.getManagedUserToken() {
                        requestHeaders["X-Authenticated-For"] = managedUserToken
                    }
                }
                
                request["headers"] = requestHeaders
            }
            
            self.mDbService?.update("msg_id", [networkQueueModel.getId()], ["request": request])
            
        }
        
        private func handlePostAPIActions(_ type: String, _ httpResponse: HTTPURLResponse, _ responseObject: [String: Any]) {
            self.setupTraceId(httpResponse)
            if type.lowercased().elementsEqual("telemetry") {
                self.postProcessTelemetrySync(responseObject)
            }
        }
        
        
        private func setupTraceId(_ httpResponse: HTTPURLResponse) {
            var responseTraceId: String?
            if #available(iOS 13.0, *) {
                if let xTraceEnabled = httpResponse.value(forHTTPHeaderField: "X-Trace-Enabled") {
                    responseTraceId = xTraceEnabled
                }
            } else {
                if let headers = httpResponse.allHeaderFields as? [String : Any] {
                    if let xTraceEnabled = headers["X-Trace-Enabled"] as? String {
                        responseTraceId = xTraceEnabled
                    }
                }
            }
            if responseTraceId != nil && self.mTraceId != responseTraceId {
                self.mPreferenceService!.setTraceId(responseTraceId!)
            }
        }
        
        private func consumeEvents() {
            if let mHandler = self.mHandler {
                if mHandler.isEmpty || self.mLastEvent == nil {
                    return
                }
                for callback in mHandler {
                    let pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: self.mLastEvent)
                    self.commandDelegate.send(pluginResult, callbackId: callback)
                }
                self.mHandler = []
                self.mLastEvent = nil
            }
        }
        
        private func publishAuthErrorEvents(_ responseObject : [String: Any], _ statusCode: Int) {
            if let mLiveHandler = self.mLiveHandler {
                if mLiveHandler.count == 0 {
                    return
                }
                let isApiTokenExpired = self.isApiTokenExpired(responseObject, statusCode)
                let result = ["network_queue_error": isApiTokenExpired ? "API_TOKEN_EXPIRED" : "USER_TOKEN_EXPIRED"]
                for callback in mLiveHandler {
                    let pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: result)
                    self.commandDelegate.send(pluginResult, callbackId: callback)
                }
            }
        }
        
        private func isSametoken(_ request: NetworkQueueModel, _ responseObject: [String: Any], _ response: HTTPURLResponse) -> Bool {
            var tokenInApp: String?, tokenInRequest: String?
            let request = request.getRequest()
            if let requestHeaders = request["headers"] as? [String: Any] {
                if self.isApiTokenExpired(responseObject, response.statusCode) {
                    if let token = mPreferenceService!.getBearerToken() {
                        tokenInApp = "Bearer " + token
                        tokenInRequest = requestHeaders["Authorization"] as? String
                    }
                } else {
                    if let token = mPreferenceService!.getUserToken(){
                        tokenInApp = token
                        tokenInRequest = requestHeaders["X-Authenticated-User-Token"] as? String
                    }
                }
            }
            
            if tokenInApp != nil && tokenInRequest != nil {
                return tokenInApp!.lowercased().elementsEqual(tokenInRequest!.lowercased())
            }
            
            return false
        }
        
        private func isApiTokenExpired(_ responseObject: [String: Any], _ statusCode: Int) -> Bool {
            var isTokenExpired = false
            if statusCode == 403 {
                isTokenExpired = true
            }
            if let message = responseObject["message"] as? String {
                isTokenExpired = message.lowercased().elementsEqual("unauthorized")
            }
            return isTokenExpired
        }
    }
    
