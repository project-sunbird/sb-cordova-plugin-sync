import Foundation
// Method for SyncPlugin.
@objc(SyncPlugin) class SyncPlugin : CordovaPlugin {   

  // Method for Sync.
 @objc(sync:)
    func sync(_ command: CDVInvokedUrlCommand) {
        
    }

    // Method for enqueue.
     @objc(enqueue:)
    func enqueue(_ command: CDVInvokedUrlCommand) {
        
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