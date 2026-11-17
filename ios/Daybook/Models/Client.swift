import Foundation
import SwiftData

@Model
final class Client {
    var id: UUID
    var name: String
    var packageName: String
    var totalSessions: Int?
    var sessionsRemaining: Int?
    var packageCycleID: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        packageName: String,
        totalSessions: Int? = nil,
        sessionsRemaining: Int? = nil,
        packageCycleID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.packageName = packageName
        self.totalSessions = totalSessions
        self.sessionsRemaining = sessionsRemaining
        self.packageCycleID = packageCycleID
    }
}
