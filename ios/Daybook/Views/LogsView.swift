import SwiftData
import SwiftUI

struct LogsView: View {
    @Query(sort: \Client.name, order: .forward) private var clients: [Client]
    @Query(sort: \Booking.startDate, order: .forward) private var bookings: [Booking]

    var body: some View {
        NavigationStack {
            Group {
                if clients.isEmpty {
                    ContentUnavailableView(
                        "No clients yet",
                        systemImage: "person.2",
                        description: Text("Register a client to track their consumed sessions.")
                    )
                } else {
                    List {
                        ForEach(clients) { client in
                            let sessions = logs(for: client)
                            NavigationLink {
                                ClientLogDetailView(client: client, sessions: sessions)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(client.name)
                                        .font(.headline)
                                    Text(client.packageName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("\(sessions.count) \(sessions.count == 1 ? "session" : "sessions") logged")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Logs")
        }
    }

    private func logs(for client: Client) -> [SessionLog] {
        let related = bookings
            .filter { $0.clientID == client.id }
            .sorted { $0.startDate < $1.startDate }
        return related.enumerated().reversed().map { item in
            SessionLog(booking: item.element, sessionNumber: item.offset + 1)
        }
    }
}

private struct SessionLog {
    let booking: Booking
    let sessionNumber: Int
}

private struct ClientLogDetailView: View {
    let client: Client
    let sessions: [SessionLog]

    var body: some View {
        List {
            Section("Client") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(client.name)
                        .font(.title3.weight(.semibold))
                    Text(client.packageName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let total = client.totalSessions, let remaining = client.sessionsRemaining {
                        Text("\(remaining) of \(total) sessions left · \(total - remaining) used")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Session balance not set")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent(
                        "Package payment",
                        value: client.packagePaid ? "Paid" : "Awaiting payment"
                    )
                    .font(.subheadline)
                }
            }

            Section("Sessions consumed") {
                if sessions.isEmpty {
                    Text("No sessions consumed yet.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(sessions, id: \.booking.id) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Session \(log.sessionNumber)")
                                    .font(.headline)
                                Spacer()
                                let isPaid = PackagePayment.isPaid(for: log.booking, clients: [client])
                                Text(isPaid ? "Package paid" : "Unpaid")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(isPaid ? Color.green : Color.orange)
                            }
                            Text(log.booking.startDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                            Text("\(log.booking.startDate.formatted(date: .omitted, time: .shortened)) – \(log.booking.startDate.addingTimeInterval(60 * 60).formatted(date: .omitted, time: .shortened))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let packageName = log.booking.packageName, !packageName.isEmpty {
                                Text("Package: \(packageName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("Balance: \(log.booking.packageBalance)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Session log")
        .navigationBarTitleDisplayMode(.inline)
    }
}
