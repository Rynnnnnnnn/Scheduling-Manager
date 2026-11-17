import SwiftData
import SwiftUI

struct BookingFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var bookings: [Booking]
    @Query(sort: \Client.name, order: .forward) private var clients: [Client]

    private let booking: Booking?

    @State private var clientName: String
    @State private var clientID: UUID?
    @State private var packageName: String
    @State private var startDate: Date
    @State private var notes: String
    @State private var isPaid: Bool
    @State private var errorMessage: String?

    private var matchingClients: [Client] {
        let query = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return clients }
        return clients.filter { $0.name.localizedStandardContains(query) }
    }

    private var selectedClient: Client? {
        guard let clientID else { return nil }
        return clients.first { $0.id == clientID }
    }

    private var sessionBalanceLabel: String {
        guard let remaining = selectedClient?.sessionsRemaining else { return "Not tracked" }
        return String(remaining)
    }

    init(booking: Booking? = nil) {
        self.booking = booking
        _clientName = State(initialValue: booking?.clientName ?? "")
        _clientID = State(initialValue: booking?.clientID)
        _packageName = State(initialValue: booking?.packageName ?? "")
        _startDate = State(initialValue: booking?.startDate ?? .now)
        _notes = State(initialValue: booking?.notes ?? "")
        _isPaid = State(initialValue: booking?.isPaid ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Client name", text: $clientName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .onChange(of: clientName) { _, newName in
                            let normalizedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                            let client = clients.first {
                                $0.name.localizedCaseInsensitiveCompare(normalizedName) == .orderedSame
                            }
                            clientID = client?.id
                            packageName = client?.packageName ?? ""
                        }

                    if clients.isEmpty {
                        Text("Register clients in the Clients tab to add their packages here.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if matchingClients.isEmpty {
                        Text("No saved clients match this name.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Menu {
                            ForEach(matchingClients) { client in
                                Button("\(client.name) — \(client.packageName)") {
                                    clientName = client.name
                                    clientID = client.id
                                    packageName = client.packageName
                                }
                            }
                        } label: {
                            Label("Choose a saved client", systemImage: "chevron.down")
                        }
                    }

                    LabeledContent("Package availed", value: packageName.isEmpty ? "Not selected" : packageName)
                    LabeledContent("Sessions remaining", value: sessionBalanceLabel)
                }

                Section("Date and time") {
                    DatePicker(
                        "Booking",
                        selection: $startDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    LabeledContent(
                        "Ends at",
                        value: startDate.addingTimeInterval(60 * 60).formatted(date: .omitted, time: .shortened)
                    )
                    LabeledContent("Session length", value: "1 hour")
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                Section("Payment") {
                    Toggle("Payment received", isOn: $isPaid)
                }
            }
            .navigationTitle(booking == nil ? "New booking" : "Edit booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert(
                "Couldn’t save booking",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }

    private func save() {
        let cleanedName = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else { return }
        guard !hasOverlap(at: startDate, excluding: booking?.id) else {
            errorMessage = "This time overlaps another 1-hour booking. Choose a different time."
            return
        }

        let targetClient = clients.first {
            $0.id == clientID && $0.name.localizedCaseInsensitiveCompare(cleanedName) == .orderedSame
        }
        let targetClientID = targetClient?.id
        let changesClient = booking?.clientID != targetClientID

        if let targetClient, changesClient {
            guard let remaining = targetClient.sessionsRemaining,
                  let total = targetClient.totalSessions,
                  targetClient.packageCycleID != nil,
                  remaining <= total else {
                errorMessage = "Set this client’s package session count before booking."
                return
            }
            guard remaining > 0 else {
                errorMessage = "No sessions remain. Renew this client’s package before booking."
                return
            }
        }

        let cleanedPackage = packageName.trimmingCharacters(in: .whitespacesAndNewlines)

        if let booking {
            let oldValues = (
                booking.clientName,
                booking.clientID,
                booking.packageName,
                booking.packageCycleID,
                booking.startDate,
                booking.notes,
                booking.isPaid
            )
            let previousBalances = clients.map { ($0.id, $0.sessionsRemaining) }

            if changesClient {
                restoreSession(for: booking)
                if let targetClient {
                    targetClient.sessionsRemaining = (targetClient.sessionsRemaining ?? 0) - 1
                }
            }

            booking.clientName = cleanedName
            booking.clientID = targetClientID
            booking.packageName = cleanedPackage.isEmpty ? nil : cleanedPackage
            booking.packageCycleID = targetClientID == oldValues.1
                ? oldValues.3
                : targetClient?.packageCycleID
            booking.startDate = startDate
            booking.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            booking.isPaid = isPaid

            do {
                try modelContext.save()
                dismiss()
            } catch {
                booking.clientName = oldValues.0
                booking.clientID = oldValues.1
                booking.packageName = oldValues.2
                booking.packageCycleID = oldValues.3
                booking.startDate = oldValues.4
                booking.notes = oldValues.5
                booking.isPaid = oldValues.6
                for (id, remaining) in previousBalances {
                    if let client = clients.first(where: { $0.id == id }) {
                        client.sessionsRemaining = remaining
                    }
                }
                errorMessage = error.localizedDescription
            }
        } else {
            let newBooking = Booking(
                clientName: cleanedName,
                clientID: targetClientID,
                packageName: cleanedPackage.isEmpty ? nil : cleanedPackage,
                packageCycleID: targetClient?.packageCycleID,
                startDate: startDate,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                isPaid: isPaid
            )
            let previousRemaining = targetClient?.sessionsRemaining
            if let targetClient {
                targetClient.sessionsRemaining = (targetClient.sessionsRemaining ?? 0) - 1
            }
            modelContext.insert(newBooking)

            do {
                try modelContext.save()
                dismiss()
            } catch {
                modelContext.delete(newBooking)
                if let targetClient {
                    targetClient.sessionsRemaining = previousRemaining
                }
                errorMessage = error.localizedDescription
            }
        }
    }

    private func hasOverlap(at candidateStart: Date, excluding bookingID: UUID?) -> Bool {
        let candidateEnd = candidateStart.addingTimeInterval(60 * 60)
        return bookings.contains { existing in
            if existing.id == bookingID { return false }
            let existingEnd = existing.startDate.addingTimeInterval(60 * 60)
            return candidateStart < existingEnd && existing.startDate < candidateEnd
        }
    }

    private func restoreSession(for booking: Booking) {
        guard let clientID = booking.clientID,
              let packageCycleID = booking.packageCycleID,
              let client = clients.first(where: { $0.id == clientID }),
              client.packageCycleID == packageCycleID,
              let remaining = client.sessionsRemaining,
              let total = client.totalSessions else { return }
        client.sessionsRemaining = min(total, remaining + 1)
    }
}
