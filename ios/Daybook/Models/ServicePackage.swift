import Foundation
import SwiftData

@Model
final class ServicePackage {
    var id: UUID
    var name: String
    var totalSessions: Int

    init(id: UUID = UUID(), name: String, totalSessions: Int) {
        self.id = id
        self.name = name
        self.totalSessions = totalSessions
    }
}
