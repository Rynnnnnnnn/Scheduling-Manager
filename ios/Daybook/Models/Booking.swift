import Foundation
import SwiftData

@Model
final class Booking {
    var id: UUID
    var clientName: String
    var clientID: UUID?
    var packageName: String?
    var packageCycleID: UUID?
    var startDate: Date
    var notes: String
    var isPaid: Bool

    init(
        id: UUID = UUID(),
        clientName: String,
        clientID: UUID? = nil,
        packageName: String? = nil,
        packageCycleID: UUID? = nil,
        startDate: Date,
        notes: String = "",
        isPaid: Bool = false
    ) {
        self.id = id
        self.clientName = clientName
        self.clientID = clientID
        self.packageName = packageName
        self.packageCycleID = packageCycleID
        self.startDate = startDate
        self.notes = notes
        self.isPaid = isPaid
    }
}
