import Foundation 

public class HttpOperation {

    static let TAG: String = "Cordova-Plugin-SYNC"
    private var method: String
    private var url: String
    private var data: [String: Any]
    private var serializer: String = "none"
    private var responseType: String = "text"
    private var headers: [String: Any]
    private var timeout: Int = 60000
    private var followRedirects: Bool = true
    private var tlsConfiguration: Any

    init(_ method: String, _ url: String, _ serializer: String, _ data: String, _ headers: [String: Any], _ tlsConfiguration: Any) {
        self.method = method
        self.url = url
        self.serializer = serializer
        self.data = data
        self.headers = headers
        self.tlsConfiguration = tlsConfiguration
    }

    public func execute() -> HttpResponse {
        let response: HttpResponse = HttpResponse()
        do {
            let request: HttpRequest = self.createRequest()
            try self.prepareRequest(request)
            try self.sendBody(request)
            try self.processResponse(request, response)
            
        } catch error {
            print("HttpOperation: execute error \(error)")
            response.setStatus(-1)
            response.setErrorMessage(e) // TODO
        }
    
        return response

    }
    public func createRequest() -> HttpRequest {
        return HttpRequest(self.url, self.method)
    }
    public func prepareRequest(_ request: Request) throws {
        request.followRedirects(self.followRedirects)
        request.readTimeout(self.timeout)
        request.acceptCharset("UTF-8")
        request.uncompress(true)
        //TODO

        self.setContentType(request)
    }
    public func setContentType(_ request: Request) throws {
        if "json".elementsEqual(self.serializer) {
            request.contentType("application/json", "UTF-8")
        } else if "raw".elementsEqual(self.serializer) {
            request.contentType("application/octet-stream")
        }
    }
    public func sendBody(_ request: Request) throws {}
    public func processResponse(_ request: Request, _ response: HttpResponse) throws {}



}