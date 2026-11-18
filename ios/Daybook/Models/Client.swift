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
    var packagePaid: Bool = false
    var packagePaidAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        packageName: String,
        totalSessions: Int? = nil,
        sessionsRemaining: Int? = nil,
        packageCycleID: UUID? = nil,
        packagePaid: Bool = false,
        packagePaidAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.packageName = packageName
        self.totalSessions = totalSessions
        self.sessionsRemaining = sessionsRemaining
        self.packageCycleID = packageCycleID
        self.packagePaid = packagePaid
        self.packagePaidAt = packagePaidAt
    }
}
