var exec = require('cordova/exec');

var PLUGIN_NAME = 'sbsync';

var sbsync = {

    sync: function(success, error) {
        exec(success, error, PLUGIN_NAME, "sync", []);
    },
    enqueue: function(data, model, shouldSync, success, error) {
          exec(success, error, PLUGIN_NAME, "enqueue", [data, model, shouldSync]);
    },
    onSyncSucces: function(success, error) {
        exec(success, error, PLUGIN_NAME, "onSyncSucces", []);
    },
    onAuthorizationError: function(success, error) {
        exec(success, error, PLUGIN_NAME, "onAuthorizationError", []);
    }
};


module.exports = sbsync;
