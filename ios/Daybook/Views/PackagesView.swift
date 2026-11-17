import SwiftData
import SwiftUI

struct PackagesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \ServicePackage.name, order: .forward) private var packages: [ServicePackage]

    @State private var isShowingForm = false
    @State private var selectedPackage: ServicePackage?
    @State private var packageToDelete: ServicePackage?
    @State private var errorMessage: String?

    private var smoothAnimation: Animation? {
        reduceMotion ? nil : .snappy(duration: 0.24)
    }

    var body: some View {
        NavigationStack {
            Group {
                if packages.isEmpty {
                    ContentUnavailableView(
                        "No packages yet",
                        systemImage: "shippingbox",
                        description: Text("Add reusable package templates for client registration.")
                    )
                } else {
                    List {
                        ForEach(packages) { package in
                            Button {
                                selectedPackage = package
                                isShowingForm = true
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(package.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(package.totalSessions) sessions")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    packageToDelete = package
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    selectedPackage = package
                                    isShowingForm = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .animation(smoothAnimation, value: packages.map(\.id))
                }
            }
            .navigationTitle("Packages")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedPackage = nil
                        isShowingForm = true
                    } label: {
                        Label("Add package", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingForm, onDismiss: { selectedPackage = nil }) {
                PackageFormView(package: selectedPackage)
            }
            .confirmationDialog(
                "Delete package template?",
                isPresented: Binding(
                    get: { packageToDelete != nil },
                    set: { if !$0 { packageToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let target = packageToDelete {
                        delete(target)
                    }
                    packageToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    packageToDelete = nil
                }
            } message: {
                Text("Existing client packages and balances will remain unchanged.")
            }
            .alert(
                "Couldn’t save changes",
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

    private func delete(_ package: ServicePackage) {
        withAnimation(smoothAnimation) {
            modelContext.delete(package)
        }
        do {
            try modelContext.save()
        } catch {
            withAnimation(smoothAnimation) {
                modelContext.insert(package)
            }
            errorMessage = error.localizedDescription
        }
    }
}
