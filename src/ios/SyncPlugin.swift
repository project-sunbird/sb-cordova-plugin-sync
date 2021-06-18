import Foundation

// Method for SyncPlugin.
@objc(SyncPlugin) class SyncPlugin : CordovaPlugin {   

  // Method for Sync.

 @objc(sync:)
    func sync(_ command: CDVInvokedUrlCommand) {
      //TODO: will implement after undstanding it
      print("Successfully sync.")
        let pluginResult:CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Successfully sync")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    
        
    }


    // Method for enqueue.
     @objc(enqueue:)
    func enqueue(_ command: CDVInvokedUrlCommand) {
         var pluginResult:CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        let data = command.arguments[0] as? String ?? ""
        let model = command.arguments[1] as? String ?? ""
        let shouldSync = command.arguments[2] as? String ?? ""
            print("Start Scanning Successfully.")
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Start Scanning Successfully.")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)


    }


// Method for onSyncSucces.
     @objc(onSyncSucces:)
    func onSyncSucces(_ command: CDVInvokedUrlCommand) {
        
    }


    // Method for onAuthorizationError.
     @objc(onAuthorizationError:)
    func onAuthorizationError(_ command: CDVInvokedUrlCommand) {
        
    }


}