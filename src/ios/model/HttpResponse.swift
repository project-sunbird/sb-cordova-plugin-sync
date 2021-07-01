import Foundation

class HttpResponse {
    private var status: Int = 0
    private var url: String = ""
    private var headers: [String: [String]] = [:]
    private var body: String = ""
    private var rawData: [UInt8] = []
    private var fileEntry: [String: Any] = [:]
    private var hasFailed: Bool = false
    private var isFileOperation: Bool = false
    private var isRawResponse: Bool = false
    private var error: String = ""

    public func setStatus(_ status: Int) {
        self.status = status
    }

    public func setUrl(_ url: String) {
        self.url = url
    }

    public func setHeaders(_ headers: [String: [String]]) {
        self.headers = headers
    }

    public func setBody(_ body: String) {
        self.body = body
    }

    public func setData(_ rawData: [UInt8]) {
        self.isRawResponse = true
        self.rawData = rawData
    }

    public func setFileEntry(_ entry: [String: Any]) {
        self.isFileOperation = true
        self.fileEntry = entry
    }

    public func setErrorMessage(_ message: String) {
        self.hasFailed = true
        self.error = message
    }

    public func getHasFailed() -> Bool {
        return self.hasFailed
    }

    public func getStatus() -> Int {
        return self.status
    }

    public func  getUrl() -> String{
        return self.url
    }

    public func getHeaders() -> [String: String]{
        return self.headers
    }

    public func getBody() -> String {
        return self.body
    }

    public func getError() -> String {
        return self.error
    }

    public func toJSON() throws -> [String: Any] {
        var json: [String: Any] = [:]
        json["status"] = self.status
        json["url"] = self.url
        //TODO
//        if let headers = self.headers{
//            if !headers.isEmpty {
//                json["headers"] = getFilteredHeaders()
//            }
//        }
        if self.hasFailed {
            json["error"] = self.error
        } else if self.isFileOperation {
            json["file"] = self.fileEntry
        } else if self.isRawResponse {
            json["data"] = String(bytes: self.rawData, encoding: .utf8)
        } else {
            json["data"] = self.body
        }

        return json
    }

    private func getFilteredHeaders() -> [String: String] {
        var filteredHeaders: [String: String] = [:]
        // TODO Need to add the implementation 
        return filteredHeaders
    }
    
}
