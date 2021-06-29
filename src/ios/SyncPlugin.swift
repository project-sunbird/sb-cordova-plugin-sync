



import Foundation


@objc(SyncPlugin) class SyncPlugin : CDVPlugin { 


    private static TAG: String = "Cordova-Plugin-SYNC";
    private let mDbService: DbService
    private let mNetworkQueue: NetworkQueue
    private let mApiService: ApiService
    private let mPreferenceService: PreferenceService
    private var isSyncing: Bool

    private var mTraceId: String
    private var mHandler: [Any] = []
    private var mLiveHandler: [Any] = []
    private var mLastevent: [String: Any] = [:]

    @objc
    func sync(_ command: CDVInvokedUrlCommand) {
         var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        
    }

    @objc
    func enqueue(_ command: CDVInvokedUrlCommand) {
         var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        
    }

    @objc
    func onSyncSucces(_ command: CDVInvokedUrlCommand) {
        mLiveHandler.append(command.callbackId)        
    }

    @objc
    func onAuthorizationError(_ command: CDVInvokedUrlCommand) {
        mLiveHandler.append(command.callbackId)
    }


    private func handlePostAPIActions(_ type: String, _ httpResponse: HttpResponse) {
        setupTraceId(httpResponse)
        if type.lowercased.elementsEqual("telemetry") {
            postProcessTelemetrySync(httpResponse)
        }
    }


    private func setupTraceId(_ httpResponse){

        if httpResponse != nil && httpResponse.getHeaders() != nil {
            let headerList - httpResponse.getHeaders()["X-Trace-Enabled"]
            if headerList.count > 0 {
                let responseTraceId = headerList[0]
                if mTraceId != responseTraceId {
                    
                }
            }
        }
    }

    private func consumeEvents(){
        if mLiveHandler.count == 0 || mLastEvent == nil {
            return 
        }
        for callback in mHandler {
            var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: mLastEvent)
            self.commandDelegate.send(pluginResult, callbackId: callback)
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
            self.commandDelegate.send(pluginResult, callbackId: callback)
        }
    }

    private func isSametoken(_ request, _ httpResponse) -> Bool {
        var tokenInApp: String, tokenInRequest: String
        if isApiTokenExpired(httpResponse.getError(), httpResponse.getStatus()) {
            tokenInApp = "Bearer " + mPreferenceService.getBearerToken()
            tokenInRequest = request.getHeaders()["Authorization"]
        } else {
            if mPreferenceService.getUserToken() != nil {
                tokenInApp = mPreferenceService.getUserToken()
                tokenInRequest = request.getHeaders()["X-Authenticated-User-Token"]
            }
        }
        
        return tokenInApp != nil && tokenInRequest != nil && (tokenInApp.lowercased().elementsEqual(tokenInRequest.lowercased()))
    }

    private func isApiTokenExpired(_ error: String, _ statusCode: Int) -> Bool {
        if statusCode == 403 || error.isEmpty {
            return true
        }

        let errorObject: [String, Any]  = [:]
        guard errorObject["message"] != nil else {
            return false
        }

        return "unauthorized".elementsEqual((errorObject["message"] as! String).lowercased())
    }
}