import Foundation
import SwiftData

@Model
final class Booking {
    var id: UUID
    var clientName: String
    var clientID: UUID?
    var packageName: String?
    var packageBalance: Int = 10
    var packageCycleID: UUID?
    var startDate: Date
    var notes: String
    var isPaid: Bool

    init(
        id: UUID = UUID(),
        clientName: String,
        clientID: UUID? = nil,
        packageName: String? = nil,
        packageBalance: Int = 10,
        packageCycleID: UUID? = nil,
        startDate: Date,
        notes: String = "",
        isPaid: Bool = false
    ) {
        self.id = id
        self.clientName = clientName
        self.clientID = clientID
        self.packageName = packageName
        self.packageBalance = packageBalance
        self.packageCycleID = packageCycleID
        self.startDate = startDate
        self.notes = notes
        self.isPaid = isPaid
    }
}

enum PackagePayment {
    static func isPaid(for booking: Booking, clients: [Client]) -> Bool {
        guard let clientID = booking.clientID,
              let client = clients.first(where: { $0.id == clientID }) else {
            return booking.isPaid
        }

        guard let cycleID = booking.packageCycleID else {
            return client.packagePaid
        }

        return cycleID == client.packageCycleID ? client.packagePaid : booking.isPaid
    }
}
