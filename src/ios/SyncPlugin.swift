    import Foundation
    
    @objc(SyncPlugin) class SyncPlugin : CDVPlugin {
        
        private static var TAG: String = "Cordova-Plugin-SYNC"
        private var mDbService: DbService?
        private var mNetworkQueue: NetworkQueue?
        private var mApiService: ApiService?
        private var mPreferenceService: PreferenceService?
        private var isSyncing: Bool = false
        private var isUnauthorizedErrorThrown: Bool = false
        
        private var mTraceId: String = ""
        private var mHandler: [Any] = []
        private var mLiveHandler: [Any] = []
        private var mLastEvent: [String: Any]? = [:]
        
        override func pluginInitialize() {
            mDbService = DbServiceImpl()
            mNetworkQueue = NetworkQueueImpl(mDbService as! DbService)
            mApiService = ApiServiceImpl()
            mPreferenceService = PreferenceServiceImpl()
            if let traceId = mPreferenceService!.getTraceId() {
                self.mTraceId = traceId
            }
        }
        
        @objc
        func sync(_ command: CDVInvokedUrlCommand) {
            var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
            
            self.commandDelegate.run(inBackground: {
                self.mNetworkQueue!.seed()
                while !self.mNetworkQueue!.isEmpty() {
                    self.isSyncing = true
                    let networkQueueModel = self.mNetworkQueue!.peek() as? NetworkQueueModel
                    var httpResponse: HttpResponse
                    if networkQueueModel != nil {
                        httpResponse = self.mApiService!.process(networkQueueModel!.getRequest())
                        if httpResponse != nil {
                            let status = httpResponse.getStatus()
                            if status >= 200 && status < 300 {
                                self.handlePostAPIActions(networkQueueModel!.getType(), httpResponse)
                                self.mNetworkQueue!.dequeue(false)
                                self.publishSuccessResult(networkQueueModel!, httpResponse)
                            } else if status == 400 {
                                //                            self.publishEvent("error", "BAD_REQUEST")
                                self.mNetworkQueue!.dequeue(true)
                                continue
                            } else if status == 401 || status == 403 {
                                if networkQueueModel!.getRequest().getNoOfFailureSync() >= 2 {
                                    if !self.isUnauthorizedErrorThrown {
                                        self.isUnauthorizedErrorThrown = true
                                        if !self.isSametoken(networkQueueModel!.getRequest(), httpResponse) {
                                            self.publishAuthErrorEvents(httpResponse.getError(), httpResponse.getStatus())
                                        }
                                        self.handleUnAuthorizedError(networkQueueModel!, httpResponse)
                                        self.mNetworkQueue!.dequeue(true)
                                    } else {
                                        self.handleUnAuthorizedError(networkQueueModel!, httpResponse)
                                        self.mNetworkQueue!.dequeue(true)
                                    }
                                    
                                } else {
                                    let request = networkQueueModel!.getRequest()
                                    var noOfFailureSyncs: Int = request.getNoOfFailureSync() + 1
                                    request.setNoOfFailureSync(noOfFailureSyncs)
                                    noOfFailureSyncs = noOfFailureSyncs + 1
                                    let model = ["request": request.toJSON().description]
                                    // TODO logic to update the DB
                                    self.handleUnAuthorizedError(networkQueueModel!, httpResponse)
                                    self.mNetworkQueue!.dequeue(true)
                                }
                                continue
                            } else if status == -3 {
                                //                            self.publishEvent(networkQueueModel!.getType() + "_error", "NETWORK_ERROR")
                                self.mNetworkQueue!.dequeue(true)
                                break
                            } else {
                                //                            self.publishEvent(networkQueueModel!.getType() + "_error", httpResponse.getError())
                                self.mNetworkQueue!.dequeue(true)
                                continue
                            }
                        }
                    }
                }
                self.isSyncing = false
                pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                
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
                        var networkRequestObject = try? JSONSerialization.jsonObject(with: networkRequest.data(using: .utf8)!, options: .allowFragments) as? [String: Any]
                        networkRequestObject?["body"] = data
                        request["request"] = networkRequestObject?.description
                        // Insert to DB
                        if shouldSync && !self.isSyncing {
                            self.sync(command)
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
            mLiveHandler.append(command.callbackId)
        }
        
        @objc
        func onAuthorizationError(_ command: CDVInvokedUrlCommand) {
            mLiveHandler.append(command.callbackId)
        }
        
        
        private func publishEvent(_ key: String, _ value: Any) {
            mLastEvent = [key: value]
            consumeEvents()
        }
        
        private func postProcessTelemetrySync(_ httpResponse: HttpResponse) {
            let jsonArray: [[String: Any]] = []
            if jsonArray != nil && jsonArray[0] != nil {
                let isDeviceRegisterSuccesfullDBObj = jsonArray[0] as? [String: Any]
                let isDeviceRegisterSuccesfull = isDeviceRegisterSuccesfullDBObj!["value"] as! String
                if isDeviceRegisterSuccesfull.lowercased().elementsEqual("false") {
                    if httpResponse != nil {
                        let responseStr = httpResponse.getBody()
                        do {
                            var networkRequestObject = try? JSONSerialization.jsonObject(with: responseStr.data(using: .utf8)!, options: .allowFragments) as? [String: Any]
                            if networkRequestObject != nil {
                                if let ets = networkRequestObject?["ets"] {
                                    let serverTime = UInt64((ets as! String))!
                                    let now = UInt64(Date().timeIntervalSince1970)
                                    let currentOffset = serverTime - now
                                    let allowedOffset = currentOffset > 86400000 ? currentOffset : 0
                                    if allowedOffset > 0 {
                                        var insertObj: [String: String] = [:]
                                        insertObj["key"] = "telemetry_log_min_allowed_offset_key"
                                        insertObj["value"] = String(allowedOffset)
                                        // TODO logic to insert into the DB
                                    }
                                }
                            }
                        } catch let error {
                            print("Error in postProcessTelemetrySync \(error)")
                        }
                    }
                }
            }
        }
        
        public func publishSuccessResult(_ networkQueueModel: NetworkQueueModel, _ response: HttpResponse) {
            let config = networkQueueModel.getConfig()
            let type = networkQueueModel.getType()
            if config != nil {
                let shouldPublishResult = config?["shouldPublishResult"] as! Bool
                if shouldPublishResult {
                    if type.elementsEqual("telemetry") {
                        self.publishEvent("syncedEventCount", networkQueueModel.getEventCount())
                    } else if type.elementsEqual("course_progress") {
                        let responseStr: String = response.getBody()
                        let result = self.getResultFromAPIResponse(responseStr)
                        self.publishEvent("courseProgressResponse", result as Any)
                    } else if type.elementsEqual("course_assesment") {
                        let responseStr: String = response.getBody()
                        let result = self.getResultFromAPIResponse(responseStr)
                        self.publishEvent("courseAssesmentResponse", result as Any)
                    }
                }
            }
        }
        
        private func getResultFromAPIResponse(_ body: String) -> Any? {
            do {
                let result = try? JSONSerialization.jsonObject(with: body.data(using: .utf8)!, options: .allowFragments) as? [String: Any]
                if result?["result"] != nil {
                    return result?["result"]
                }
                return nil
            } catch let error {
                print(error)
                return nil
            }
        }
        
        private func handleUnAuthorizedError(_ networkQueueModel: NetworkQueueModel, _ httpResponse: HttpResponse) {
            let request: Request = networkQueueModel.getRequest()
            var headers = request.getHeaders()
            
            if isApiTokenExpired(httpResponse.getError(), httpResponse.getStatus()) {
                if let token = mPreferenceService!.getBearerToken() {
                    headers["Authorization"] = "Bearer " + token
                }
            } else {
                
                if let token = mPreferenceService!.getUserToken() {
                    headers["X-Authenticated-User-Token"] = token
                }
                
                if let token = mPreferenceService!.getManagedUserToken() {
                    headers["X-Authenticated-For"] = token
                }
            }
            request.setHeaders(headers)
            let model = ["request": request.toJSON().description]
            // TODO logic to update the DB
        }
        
        private func handlePostAPIActions(_ type: String, _ httpResponse: HttpResponse) {
            setupTraceId(httpResponse)
            if type.lowercased().elementsEqual("telemetry") {
                postProcessTelemetrySync(httpResponse)
            }
        }
        
        
        private func setupTraceId(_ httpResponse: HttpResponse) {
            
            if httpResponse != nil && httpResponse.getHeaders() != nil {
                let headersList = httpResponse.getHeaders()
                guard headersList != nil && !(headersList.isEmpty ?? true) else {
                    return
                }
                
                let responseTraceId = headersList["X-Trace-Enabled"]?.first
                if responseTraceId != nil && self.mTraceId != responseTraceId {
                    mPreferenceService!.setTraceId(responseTraceId!)
                }
            }
        }
        
        private func consumeEvents(){
            if mLiveHandler.count == 0 || mLastEvent == nil {
                return
            }
            for callback in mHandler {
                var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: mLastEvent)
                self.commandDelegate.send(pluginResult, callbackId: callback as? String)
            }
            if mHandler != nil {
                mHandler = []
            }
            mLastEvent = nil
        }
        
        private func publishAuthErrorEvents(_ error: String, _ statusCode: Int) {
            if mLiveHandler.count == 0 {
                return
            }
            
            var liveJSONObject: [String: Any] = [:]
            liveJSONObject["network_queue_error"] = isApiTokenExpired(error, statusCode) ? "API_TOKEN_EXPIRED" : "USER_TOKEN_EXPIRED"
            
            for callback in mLiveHandler {
                var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: liveJSONObject)
                self.commandDelegate.send(pluginResult, callbackId: callback as? String)
            }
        }
        
        private func isSametoken(_ request: Request, _ httpResponse: HttpResponse) -> Bool {
            var tokenInApp: String? = nil, tokenInRequest: String? = nil
            if isApiTokenExpired(httpResponse.getError(), httpResponse.getStatus()) {
                if let token = mPreferenceService!.getBearerToken() {
                    tokenInApp = "Bearer " + token
                    tokenInRequest = (request.getHeaders()["Authorization"] as? String)!
                }
            } else {
                if let token = mPreferenceService!.getUserToken(){
                    tokenInApp = token
                    tokenInRequest = (request.getHeaders()["X-Authenticated-User-Token"] as? String)!
                }
            }
            return tokenInApp != nil && tokenInRequest != nil && (tokenInApp!.lowercased().elementsEqual(tokenInRequest!.lowercased()))
        }
        
        private func isApiTokenExpired(_ error: String, _ statusCode: Int) -> Bool {
            if statusCode == 403 || error.isEmpty {
                return true
            }
            
            let errorObject: [String: Any]  = [:]
            guard errorObject["message"] != nil else {
                return false
            }
            
            return "unauthorized".elementsEqual((errorObject["message"] as! String).lowercased())
        }
    }
    
