import SwiftData
import SwiftUI

struct ClientFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var clients: [Client]
    @Query(sort: \ServicePackage.name, order: .forward) private var packages: [ServicePackage]

    private let client: Client?

    @State private var name: String
    @State private var packageName: String
    @State private var totalSessions: String
    @State private var selectedPackageID: UUID?
    @State private var renewPackage: Bool
    @State private var errorMessage: String?

    init(client: Client? = nil) {
        self.client = client
        _name = State(initialValue: client?.name ?? "")
        _packageName = State(initialValue: client?.packageName ?? "")
        if let total = client?.totalSessions {
            _totalSessions = State(initialValue: String(total))
        } else {
            _totalSessions = State(initialValue: "")
        }
        _selectedPackageID = State(initialValue: nil)
        _renewPackage = State(initialValue: false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Client name", text: $name)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                }

                Section("Package") {
                    Picker("Package template", selection: $selectedPackageID) {
                        Text("Custom package").tag(UUID?.none)
                        ForEach(packages) { package in
                            Text("\(package.name) · \(package.totalSessions) sessions")
                                .tag(Optional(package.id))
                        }
                    }
                    .onChange(of: selectedPackageID) { _, packageID in
                        guard let packageID,
                              let package = packages.first(where: { $0.id == packageID }) else { return }
                        packageName = package.name
                        totalSessions = String(package.totalSessions)
                    }
                    TextField("Package availed", text: $packageName)
                        .textInputAutocapitalization(.words)
                    TextField("Sessions in package", text: $totalSessions)
                        .keyboardType(.numberPad)

                    if let client {
                        if let total = client.totalSessions, let remaining = client.sessionsRemaining {
                            LabeledContent("Sessions remaining", value: "\(remaining) of \(total)")
                            LabeledContent("Sessions used", value: "\(total - remaining)")
                        } else {
                            Text("Session balance not set")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Toggle("Renew package and reset balance", isOn: $renewPackage)
                    }

                    Text("Changing the package name or session count resets the balance to the full amount.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Package templates only fill these details; editing a template won’t change existing client balances.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(client == nil ? "Add client" : "Edit client")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let total = Int(totalSessions),
                   let package = packages.first(where: { $0.name == packageName && $0.totalSessions == total }) {
                    selectedPackageID = package.id
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(
                            name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || packageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || (Int(totalSessions) ?? 0) < 1
                        )
                }
            }
            .alert(
                "Couldn’t save client",
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
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedPackage = packageName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty, !cleanedPackage.isEmpty, let newTotal = Int(totalSessions), newTotal > 0 else { return }

        let duplicate = clients.contains {
            $0.id != client?.id
                && $0.name.localizedCaseInsensitiveCompare(cleanedName) == .orderedSame
        }
        guard !duplicate else {
            errorMessage = "A client with this name is already registered."
            return
        }

        if let client {
            let previousName = client.name
            let previousPackage = client.packageName
            let previousTotal = client.totalSessions
            let previousRemaining = client.sessionsRemaining
            let previousCycle = client.packageCycleID
            let packageChanged = client.packageName != cleanedPackage || client.totalSessions != newTotal
            client.name = cleanedName
            client.packageName = cleanedPackage
            client.totalSessions = newTotal
            if packageChanged || renewPackage || client.sessionsRemaining == nil || client.packageCycleID == nil {
                client.sessionsRemaining = newTotal
                client.packageCycleID = UUID()
            }
            do {
                try modelContext.save()
                dismiss()
            } catch {
                client.name = previousName
                client.packageName = previousPackage
                client.totalSessions = previousTotal
                client.sessionsRemaining = previousRemaining
                client.packageCycleID = previousCycle
                errorMessage = error.localizedDescription
            }
        } else {
            let newClient = Client(
                name: cleanedName,
                packageName: cleanedPackage,
                totalSessions: newTotal,
                sessionsRemaining: newTotal,
                packageCycleID: UUID()
            )
            modelContext.insert(newClient)
            do {
                try modelContext.save()
                dismiss()
            } catch {
                modelContext.delete(newClient)
                errorMessage = error.localizedDescription
            }
        }
    }
}
