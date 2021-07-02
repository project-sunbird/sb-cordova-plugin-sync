import Foundation

protocol ApiService {
    func process(_ request: Request) -> HttpResponse
}

public class ApiServiceImpl: ApiService {

    private static let TAG: String = "SB-Sync-ApiServiceImpl"
    private var tlsConfiguration: Any

    init() {
        self.initializeTTLConfiguraion()
    }
    
    private func initializeTTLConfiguraion() {
        //TODO logic to add tls configuration
    }

    func process(_ request: Request) -> HttpResponse {
        let httpOperation = HttpOperation(request.getType(), request.getHost() + request.getPath(),
                request.getSerializer(), request.getBody(), request.getHeaders(), self.tlsConfiguration)
        return httpOperation.execute()
    }

}
