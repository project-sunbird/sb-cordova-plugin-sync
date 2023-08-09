# sb-cordova-plugin-sync
A plugin to sync telemetry events and course progress.

## Installation

    cordova plugin add https://github.com/project-sunbird/sb-cordova-plugin-sync.git#<branch_name>

To install it locally 

Clone the repo then execute the following command
    
    cordova plugin add <location_of plugin>/sb-cordova-plugin-sync

# API Reference

* [sbsync](#module_sbsync)
    * [.sync(successCallback, errorCallback)](#module_sbsync.sync)
    * [.enqueue(data, model, shouldSync, successCallback, errorCallback)](#module_sbsync.enqueue)
    * [.onSyncSucces( successCallback, errorCallback)](#module_sbsync.onSyncSucces)
    * [.onAuthorizationError(successCallback, errorCallback)](#module_sbsync.onAuthorizationError)


## sbsync
### sbsync.sync(successCallback, errorCallback)

Syncs event to the platform

### sbsync.enqueue(data, model, shouldSync, successCallback, errorCallback)

Add the events to the queue to be synced.

- `data` represents  data to be synced.
- `model` represents  the model of events to be synced.
- `shouldSync` represents  whether the events to be synced or not.

### db.onSyncSucces(filePath, successCallback)
When telemetry events are synced this callback is fired.

- `filePath` represents filePath of the database file.

### db.onAuthorizationError(isExternalDb, successCallback)
When there is an authorization error this.



