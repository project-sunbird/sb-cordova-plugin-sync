import Foundation

protocol PreferenceService {
    func getBearerToken() -> String?
    func getUserToken() -> String?
    func getManagedUserToken() -> String?
    func getTraceId() -> String?
    func setTraceId(_ traceId: String)
}

class PreferenceServiceImpl: PreferenceService{

    private var mSharedPrefs: UserDefaults?
    
    init(_ context: Any) {
//        mSharedPrefs = UserDefaults.standard
        self.mSharedPrefs = UserDefaults(suiteName: "org.ekstep.genieservices.preference_file")

    }
    
    func getBearerToken() -> String? {
        let bearerToken = mSharedPrefs?.string(forKey: "api_bearer_token_v2")
        return bearerToken
    }

    func getUserToken() -> String? {
        let oauthToken = mSharedPrefs?.string(forKey: "oauth_token")
        if let oauthToken = oauthToken {
            do {
                if let oauthTokenJson = try JSONSerialization.jsonObject(with: oauthToken, options: []) {
                    return oauthTokenJson["access_token"] as? String
                }
            } catch let error {
                print("Failed to load JSON: \(error)")
                return nil
            }
        }
        return nil
    }

    func getManagedUserToken() -> String? {
        let oauthToken = mSharedPrefs?.string(forKey: "oauth_token")
        if let oauthToken = oauthToken {
            do {
                if let oauthTokenJson = try JSONSerialization.jsonObject(with: oauthToken, options: []) {
                    return oauthTokenJson["managed_access_token"] as? String
                }
            } catch let error {
                print("Failed to load JSON: \(error)")
                return nil
            }
        }
        return nil
    }

    func getTraceId() -> String? {
        let traceId = mSharedPrefs?.string(forKey: "trace_id") as? String
        return traceId
    }

    func setTraceId(_ traceId: String) {
        mSharedPrefs?.set(traceId, forKey: "trace_id")
    }
}
