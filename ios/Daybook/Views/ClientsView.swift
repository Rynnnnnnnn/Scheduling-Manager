import SwiftData
import SwiftUI

struct ClientsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Client.name, order: .forward) private var clients: [Client]
    @Query(sort: \Booking.startDate, order: .forward) private var bookings: [Booking]

    @State private var isShowingForm = false
    @State private var selectedClient: Client?
    @State private var clientToDelete: Client?
    @State private var errorMessage: String?

    private var smoothAnimation: Animation? {
        reduceMotion ? nil : .snappy(duration: 0.24)
    }

    var body: some View {
        NavigationStack {
            Group {
                if clients.isEmpty {
                    ContentUnavailableView(
                        "No clients yet",
                        systemImage: "person.2",
                        description: Text("Add clients and their packages to select them when booking.")
                    )
                } else {
                    List {
                        ForEach(clients) { client in
                            Button {
                                selectedClient = client
                                isShowingForm = true
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(client.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(client.packageName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    if let total = client.totalSessions, let remaining = client.sessionsRemaining {
                                        Text("\(remaining) of \(total) sessions left · \(total - remaining) used")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        if remaining > 0 && remaining <= 2 {
                                            Label("Almost done", systemImage: "exclamationmark.circle.fill")
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(.orange)
                                        } else if remaining == 0 {
                                            Label("Package used · renew to book", systemImage: "exclamationmark.circle.fill")
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(.orange)
                                        }
                                    } else {
                                        Text("Session balance not set")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Label(
                                        client.packagePaid ? "Package paid" : "Awaiting payment",
                                        systemImage: client.packagePaid ? "checkmark.circle.fill" : "clock"
                                    )
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(client.packagePaid ? .green : .orange)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    setPackagePaid(for: client, paid: !client.packagePaid)
                                } label: {
                                    Label(
                                        client.packagePaid ? "Mark unpaid" : "Mark paid",
                                        systemImage: client.packagePaid ? "xmark.circle" : "checkmark.circle"
                                    )
                                }
                                .tint(client.packagePaid ? .orange : .green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    clientToDelete = client
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    selectedClient = client
                                    isShowingForm = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .animation(smoothAnimation, value: clients.map(\.id))
                    .animation(smoothAnimation, value: clients.map(\.sessionsRemaining))
                    .animation(smoothAnimation, value: clients.map(\.packagePaid))
                }
            }
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedClient = nil
                        isShowingForm = true
                    } label: {
                        Label("Add client", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingForm, onDismiss: { selectedClient = nil }) {
                ClientFormView(client: selectedClient)
            }
            .confirmationDialog(
                "Delete client?",
                isPresented: Binding(
                    get: { clientToDelete != nil },
                    set: { if !$0 { clientToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let target = clientToDelete {
                        delete(target)
                    }
                    clientToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    clientToDelete = nil
                }
            } message: {
                Text("This removes the client from your list. Their saved bookings will remain.")
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

    private func setPackagePaid(for client: Client, paid: Bool) {
        let previousPaid = client.packagePaid
        let previousPaidAt = client.packagePaidAt
        let previousBookingStatus = Dictionary(uniqueKeysWithValues: bookings.map { ($0.id, $0.isPaid) })

        withAnimation(smoothAnimation) {
            client.packagePaid = paid
            client.packagePaidAt = paid ? Date() : nil
            for booking in bookings {
                guard booking.clientID == client.id,
                      booking.packageCycleID == nil || booking.packageCycleID == client.packageCycleID else { continue }
                booking.isPaid = paid
            }
        }

        do {
            try modelContext.save()
        } catch {
            withAnimation(smoothAnimation) {
                client.packagePaid = previousPaid
                client.packagePaidAt = previousPaidAt
                for booking in bookings {
                    booking.isPaid = previousBookingStatus[booking.id] ?? booking.isPaid
                }
            }
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ client: Client) {
        withAnimation(smoothAnimation) {
            modelContext.delete(client)
        }
        do {
            try modelContext.save()
        } catch {
            withAnimation(smoothAnimation) {
                modelContext.insert(client)
            }
            errorMessage = error.localizedDescription
        }
    }
}
