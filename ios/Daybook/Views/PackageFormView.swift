import SwiftData
import SwiftUI

struct PackageFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var packages: [ServicePackage]

    private let package: ServicePackage?

    @State private var name: String
    @State private var totalSessions: String
    @State private var errorMessage: String?

    init(package: ServicePackage? = nil) {
        self.package = package
        _name = State(initialValue: package?.name ?? "")
        _totalSessions = State(initialValue: package.map { String($0.totalSessions) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Package") {
                    TextField("Package name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Sessions included", text: $totalSessions)
                        .keyboardType(.numberPad)
                }

                Section {
                    Text("Package templates only apply to clients when selected. Editing a template won’t change existing client balances.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(package == nil ? "Add package" : "Edit package")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(
                            name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || (Int(totalSessions) ?? 0) < 1
                        )
                }
            }
            .alert(
                "Couldn’t save package",
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
        guard !cleanedName.isEmpty, let newTotal = Int(totalSessions), newTotal > 0 else { return }

        let duplicate = packages.contains {
            $0.id != package?.id
                && $0.name.localizedCaseInsensitiveCompare(cleanedName) == .orderedSame
        }
        guard !duplicate else {
            errorMessage = "A package with this name is already registered."
            return
        }

        if let package {
            let previousName = package.name
            let previousTotal = package.totalSessions
            package.name = cleanedName
            package.totalSessions = newTotal
            do {
                try modelContext.save()
                dismiss()
            } catch {
                package.name = previousName
                package.totalSessions = previousTotal
                errorMessage = error.localizedDescription
            }
        } else {
            let newPackage = ServicePackage(name: cleanedName, totalSessions: newTotal)
            modelContext.insert(newPackage)
            do {
                try modelContext.save()
                dismiss()
            } catch {
                modelContext.delete(newPackage)
                errorMessage = error.localizedDescription
            }
        }
    }
}
