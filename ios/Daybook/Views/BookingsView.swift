import SwiftData
import SwiftUI

private enum PaymentFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case unpaid = "Unpaid"
    case paid = "Paid"

    var id: Self { self }
}

struct BookingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Booking.startDate, order: .forward) private var bookings: [Booking]
    @Query private var clients: [Client]

    @State private var searchText = ""
    @State private var paymentFilter = PaymentFilter.all
    @State private var isShowingForm = false
    @State private var selectedBooking: Booking?
    @State private var bookingToDelete: Booking?
    @State private var errorMessage: String?

    private var smoothAnimation: Animation? {
        reduceMotion ? nil : .snappy(duration: 0.24)
    }

    private var visibleBookings: [Booking] {
        bookings.filter { booking in
            let matchesPayment: Bool
            switch paymentFilter {
            case .all:
                matchesPayment = true
            case .paid:
                matchesPayment = booking.isPaid
            case .unpaid:
                matchesPayment = !booking.isPaid
            }

            let matchesSearch = searchText.isEmpty
                || booking.clientName.localizedStandardContains(searchText)
                || (booking.packageName?.localizedStandardContains(searchText) ?? false)
                || booking.notes.localizedStandardContains(searchText)

            return matchesPayment && matchesSearch
        }
    }

    private var upcomingCount: Int {
        bookings.filter { $0.startDate >= .now }.count
    }

    private var unpaidCount: Int {
        bookings.filter { !$0.isPaid }.count
    }

    private var paidThisMonthCount: Int {
        bookings.filter {
            $0.isPaid && Calendar.current.isDate($0.startDate, equalTo: .now, toGranularity: .month)
        }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    overview
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }

                Section {
                    Picker("Payment status", selection: $paymentFilter) {
                        ForEach(PaymentFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)

                    if visibleBookings.isEmpty {
                        ContentUnavailableView(
                            bookings.isEmpty ? "Your calendar is clear" : "No bookings found",
                            systemImage: "calendar",
                            description: Text(
                                bookings.isEmpty
                                    ? "Add your first client booking to get started."
                                    : "Try changing your search or payment filter."
                            )
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(visibleBookings) { booking in
                            BookingRow(
                                booking: booking,
                                onEdit: {
                                    selectedBooking = booking
                                    isShowingForm = true
                                },
                                onTogglePayment: {
                                    togglePayment(for: booking)
                                }
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    bookingToDelete = booking
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Bookings")
                }
            }
            .listStyle(.insetGrouped)
            .animation(smoothAnimation, value: visibleBookings.map(\.id))
            .navigationTitle("Daybook")
            .searchable(text: $searchText, prompt: "Clients, packages, or notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedBooking = nil
                        isShowingForm = true
                    } label: {
                        Label("Add booking", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingForm, onDismiss: { selectedBooking = nil }) {
                BookingFormView(booking: selectedBooking)
            }
            .confirmationDialog(
                "Delete booking?",
                isPresented: Binding(
                    get: { bookingToDelete != nil },
                    set: { if !$0 { bookingToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let target = bookingToDelete {
                        delete(target)
                    }
                    bookingToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    bookingToDelete = nil
                }
            } message: {
                Text("This will permanently delete \(bookingToDelete?.clientName ?? "this booking").")
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

    private var overview: some View {
        HStack(spacing: 10) {
            StatCard(title: "Upcoming", value: upcomingCount, symbol: "calendar")
            StatCard(title: "Unpaid", value: unpaidCount, symbol: "creditcard")
            StatCard(title: "Paid this month", value: paidThisMonthCount, symbol: "checkmark.circle")
        }
    }

    private func togglePayment(for booking: Booking) {
        let previousValue = booking.isPaid
        withAnimation(smoothAnimation) {
            booking.isPaid.toggle()
        }
        do {
            try modelContext.save()
        } catch {
            booking.isPaid = previousValue
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ booking: Booking) {
        let linkedClient = booking.clientID.flatMap { id in clients.first { $0.id == id } }
        let previousRemaining = linkedClient?.sessionsRemaining
        withAnimation(smoothAnimation) {
            if let linkedClient,
               let cycleID = booking.packageCycleID,
               linkedClient.packageCycleID == cycleID,
               let remaining = linkedClient.sessionsRemaining,
               let total = linkedClient.totalSessions {
                linkedClient.sessionsRemaining = min(total, remaining + 1)
            }
            modelContext.delete(booking)
        }
        do {
            try modelContext.save()
        } catch {
            withAnimation(smoothAnimation) {
                modelContext.insert(booking)
                if let linkedClient {
                    linkedClient.sessionsRemaining = previousRemaining
                }
            }
            errorMessage = error.localizedDescription
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: Int
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.subheadline)
                .foregroundStyle(.green)
            Text(value, format: .number)
                .font(.title2.weight(.semibold))
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
    }
}
