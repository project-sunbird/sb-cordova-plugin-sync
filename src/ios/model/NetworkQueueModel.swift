import Foundation

public class NetworkQueueModel { 

    private var msgId: String
    private  var type: String
    private var priority: Int64
    private  var eventCount: Int64
    private var timestamp: Int64
    public var request: [String: Any]
    private var config: [String: Any]?
    private var failedCount = 0

    init(_ msgId: String, _ type: String, _ priority: Int64, _ timestamp: Int64, _ config: [String: Any], _ eventCount: Int64, _ request: [String: Any], _ failedCount : Int) {
        self.msgId = msgId
        self.type = type
        self.priority = priority
        self.timestamp = timestamp
        self.request = request
        self.config = config
        self.eventCount = eventCount
        self.failedCount = failedCount
    }

    public func getId() -> String {
        return self.msgId
    }
    
    public func getFailedCount() -> Int {
        return self.failedCount
    }
    
    public func setFailedCount(_ count: Int) {
        self.failedCount = count
    }

    public func getType() -> String {
        return self.type
    }

    public func getPriority() -> Int64 {
        return self.priority
    }

    public func getTimestamp() -> Int64{
        return self.timestamp
    }

    public func getRequest() -> [String: Any] {
        return self.request
    }

    public func getEventCount() -> Int64 {
        return self.eventCount
    }

    public func getConfig() -> [String: Any]? {
        if let config = self.config {
            return config
        }
        return nil
    }
}
