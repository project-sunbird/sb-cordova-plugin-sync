import Foundation

protocol DbService {
    func seed() throws -> [[String: Any]]
    func insert(_ request: [String: Any]) throws -> UInt64
    func delete(_ id: String) throws -> UInt64
    func update(_ columnName: String, _ whereArgs: [String], _ request: [String: Any]) throws -> UInt64
    func read(_ table: String, _ columns: [Sting], _ selection: String, _ selectionArgs: String) throws -> [[String: Any]]
}

class DbServiceImpl : DbService {

    func seed() throws -> [[String: Any]] {
        let resultArray = getOperator().execute("SELECT * from network_queue order by priority")
        return resultArray
    }

    func insert(_ request: [String: Any]) throws -> UInt64{
        let id = getOperator().insert("network_queue", request)
        return id
    }

    func delete(_ id: String) throws -> UInt64 {
        let resultArray = getOperator().execute("DELETE from network_queue where msg_id='" + id +"'")
        return 0
    }

    func update(_ columnName: String, _ whereArgs: [String], _ request: [String: Any]) throws -> UInt64{
        let result = getOperator().update("network_queue", columnName + " = ?", whereArgs, request)
        return result
    }

    func read(_ table: String, _ columns: [Sting], _ selection: String, _ selectionArgs: String) throws -> [[String: Any]] {
        let resultArray = getOperator().read(false, table, columns, selection, [selectionArgs], "", "", "", "")
        return resultArray
    }

    private func getOperator() -> OpaquePointer? {
        let instance = SunbirdDBPlugin.getInstance()
        return instance
    }

}
