import Foundation


class Request {
    var host: String
    var path: String
    var type: String
    var headers: [String: Any]
    var body: [String: Any]
    var serializer: String
    var noOfFailureSync: Int

    init(_ host: String, _ path: String, _ type: String, _ headers: [String: Any], _ serializer: [String: Any], _ body: [String: Any]){
        self.host = host
        self.path = path
        self.type = type
        self.headers = headers
        self.serializer = serializer
        self.body = body
    }

    func getHost() -> String {
        return self.host;
    }

    func getPath() -> String {
        return self.path;
    }

    func getType() -> String {
        return self.type;
    }

    func getHeaders() -> [String: Any] {
        return self.headers;
    }

    func setHeaders(headers: [String: Any]) {
        self.headers = headers;
    }

    func getBody() -> [String: Any] {
    return self.body;
    }

    func getSerializer() -> String {
        return self.serializer;
    }

    func getNoOfFailureSync() -> Int {
        return self.noOfFailureSync;
    }

    func setNoOfFailureSync(_ noOfFailureSync: Int) {
        self.noOfFailureSync = noOfFailureSync;
    }

    override func toString() -> String {
            return "Request{" +
                    "host='" + host + "\'" +
                    ", path='" + path + "\'" +
                    ", type='" + type + "\'" +
                    ", headers=" + headers.toString() +
                    ", body='" + body + "\'" +
                    ", serializer='" + serializer + "\'" +
                    "}"
        }

    override func toJSON() -> [String: Any] {
        var request = [:]
        request["host"] = host
        request["type"] = type
        request["path"] = path
        request["headers"] = headers
        request["serializer"] = serializer
        request["body"] = body
        request["noOfFailureSync"] = noOfFailureSync
        return request
    }

}
