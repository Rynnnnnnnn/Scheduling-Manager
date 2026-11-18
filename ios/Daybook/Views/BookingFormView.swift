import SwiftData
import SwiftUI

struct BookingFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var bookings: [Booking]
    @Query(sort: \Client.name, order: .forward) private var clients: [Client]
    @Query(sort: \ServicePackage.name, order: .forward) private var packages: [ServicePackage]

    private let booking: Booking?

    @State private var clientName: String
    @State private var clientID: UUID?
    @State private var packageName: String
    @State private var selectedPackageID: UUID?
    @State private var packageBalance: Int
    @State private var startDate: Date
    @State private var notes: String
    @State private var errorMessage: String?

    private var matchingClients: [Client] {
        let query = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return clients }
        return clients.filter { $0.name.localizedStandardContains(query) }
    }

    private var selectedClient: Client? {
        let query = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        return clients.first { $0.name.localizedCaseInsensitiveCompare(query) == .orderedSame }
    }

    private var isNewClientName: Bool {
        !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedClient == nil
    }

    private func selectPackage(named name: String) {
        let package = packages.first { $0.name == name }
        selectedPackageID = package?.id
        packageName = name
        packageBalance = package?.totalSessions ?? 10
    }

    private func clearPackage() {
        selectedPackageID = nil
        packageName = ""
        packageBalance = 10
    }

    init(booking: Booking? = nil) {
        self.booking = booking
        _clientName = State(initialValue: booking?.clientName ?? "")
        _clientID = State(initialValue: booking?.clientID)
        _packageName = State(initialValue: booking?.packageName ?? "")
        _selectedPackageID = State(initialValue: nil)
        _packageBalance = State(initialValue: booking?.packageBalance ?? 10)
        _startDate = State(initialValue: booking?.startDate ?? .now)
        _notes = State(initialValue: booking?.notes ?? "")
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
                            if let client {
                                selectPackage(named: client.packageName)
                            } else {
                                clearPackage()
                            }
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
                                    selectPackage(named: client.packageName)
                                }
                            }
                        } label: {
                            Label("Choose a saved client", systemImage: "chevron.down")
                        }
                    }

                    if isNewClientName {
                        Text("This name will be added to Clients when you save.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Package") {
                    Picker("Package availed", selection: Binding(
                        get: { selectedPackageID },
                        set: { newID in
                            if let newID,
                               let package = packages.first(where: { $0.id == newID }) {
                                selectedPackageID = newID
                                packageName = package.name
                                packageBalance = package.totalSessions
                            } else {
                                clearPackage()
                            }
                        }
                    )) {
                        Text("No package selected").tag(Optional<UUID>.none)
                        ForEach(packages) { package in
                            Text("\(package.name) · \(package.totalSessions) sessions")
                                .tag(Optional(package.id))
                        }
                    }

                    HStack {
                        Text("Package balance")
                        Spacer()
                        TextField("10", value: $packageBalance, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: packageBalance) { _, newValue in
                                if newValue < 0 { packageBalance = 0 }
                            }
                    }

                    if let selectedClient {
                        LabeledContent(
                            "Package payment",
                            value: selectedClient.packagePaid ? "Paid" : "Awaiting payment"
                        )
                        Text("Payment is managed once on the client’s package.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
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
            }
            .onAppear {
                if selectedPackageID == nil {
                    selectedPackageID = packages.first { $0.name == packageName }?.id
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

        let cleanedPackage = packageName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedBalance = max(0, packageBalance)
        let bookingPackageName = cleanedPackage.isEmpty ? "Custom package" : cleanedPackage

        let matchedClient = clients.first {
            $0.name.localizedCaseInsensitiveCompare(cleanedName) == .orderedSame
        }
        let newClient: Client?
        let targetClient: Client?
        if let matchedClient {
            newClient = nil
            targetClient = matchedClient
        } else {
            let client = Client(
                name: cleanedName,
                packageName: bookingPackageName,
                totalSessions: max(1, cleanedBalance),
                sessionsRemaining: max(0, cleanedBalance - 1),
                packageCycleID: UUID(),
                packagePaid: false
            )
            modelContext.insert(client)
            newClient = client
            targetClient = client
        }
        let isNewClient = newClient != nil
        let targetClientID = targetClient?.id
        let changesClient = booking?.clientID != targetClientID

        if let targetClient, !isNewClient, changesClient {
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

        if let booking {
            let oldValues = (
                booking.clientName,
                booking.clientID,
                booking.packageName,
                booking.packageBalance,
                booking.packageCycleID,
                booking.startDate,
                booking.notes,
                booking.isPaid
            )
            let previousBalances = clients.map { ($0.id, $0.sessionsRemaining) }

            if changesClient {
                restoreSession(for: booking)
                if let targetClient, !isNewClient {
                    targetClient.sessionsRemaining = (targetClient.sessionsRemaining ?? 0) - 1
                }
            }

            booking.clientName = cleanedName
            booking.clientID = targetClientID
            booking.packageName = bookingPackageName
            booking.packageBalance = cleanedBalance
            booking.packageCycleID = targetClientID == oldValues.1
                ? oldValues.4
                : targetClient?.packageCycleID
            booking.startDate = startDate
            booking.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            booking.isPaid = targetClient?.packagePaid ?? oldValues.7

            do {
                try modelContext.save()
                dismiss()
            } catch {
                booking.clientName = oldValues.0
                booking.clientID = oldValues.1
                booking.packageName = oldValues.2
                booking.packageBalance = oldValues.3
                booking.packageCycleID = oldValues.4
                booking.startDate = oldValues.5
                booking.notes = oldValues.6
                booking.isPaid = oldValues.7
                for (id, remaining) in previousBalances {
                    if let client = clients.first(where: { $0.id == id }) {
                        client.sessionsRemaining = remaining
                    }
                }
                if let newClient {
                    modelContext.delete(newClient)
                }
                errorMessage = error.localizedDescription
            }
        } else {
            let newBooking = Booking(
                clientName: cleanedName,
                clientID: targetClientID,
                packageName: bookingPackageName,
                packageBalance: cleanedBalance,
                packageCycleID: targetClient?.packageCycleID,
                startDate: startDate,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                isPaid: targetClient?.packagePaid ?? false
            )
            let previousRemaining = targetClient?.sessionsRemaining
            if let targetClient, !isNewClient {
                targetClient.sessionsRemaining = (targetClient.sessionsRemaining ?? 0) - 1
            }
            modelContext.insert(newBooking)

            do {
                try modelContext.save()
                dismiss()
            } catch {
                modelContext.delete(newBooking)
                if let newClient {
                    modelContext.delete(newClient)
                } else if let targetClient {
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
