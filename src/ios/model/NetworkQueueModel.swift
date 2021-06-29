import Foundation

public class NetworkQueueModel { 

    private var msgId: String
    private  var type: String
    private var priority: Int
    private  var eventCount: Int
    private timestamp: UInt8
    private var request: Request
    private var config: String

    init(_ msgId: String, _ type: String, _ priority: Int, _ timestamp: UInt8, _ config: String, _ eventCount: Int, _ request: Request) {
        self.msgId = msgId
        self.type = type
        self.priority = priority
        self.timestamp = timestamp
        self.request = request
        self.config = config
        self.eventCount = eventCount
    }

    public func getId() -> String {
        return self.msgId
    }

    public func getType() -> String {
        return self.type
    }

    public func getPriority() -> Int {
        return self.priority
    }

    public func getTimestamp() -> UInt8{
        return self.timestamp
    }

    public func getRequest() -> Request {
        return self.request
    }

    public func getEventCount() -> Int {
        return self.eventCount
    }

    public func getConfig() throws -> [String: Any]? {
        if let config = self.config {
            do {
                if let configJSON = try JSONSerialization.jsonObject(with: config, options: []) {
                    return configJSON
                }
            } catch let error {
                print("Failed to load JSON: \(error)")
                return nil
            }
        }
        return nil
    }

    override public func compareTo(_ networkQueueModel: NetworkQueueModel) -> Int {

        let currentFailedSyncCount = self.getRequest().getNoOfFailureSync() as! Int
        let failedSyncCount = networkQueueModel.getRequest().getNoOfFailureSync() as! Int

        let currentPriority = self.getPriority() + currentFailedSyncCount
        let priority = networkQueueModel.getPriority() + failedSyncCount

        if (priority < currentPriority) {
            return 1
        } else if (priority > currentPriority) {
            return -1
        }
        return 0
    }

    override public func toString() -> String {
        return "NetworkQueueModel{" +
                "msgId='" + self.msgId + "\'" +
                "}"
    }

}

//TODO needs to check the comparable interface implementation in swift