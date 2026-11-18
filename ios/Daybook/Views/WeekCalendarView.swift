import Combine
import SwiftData
import SwiftUI

struct WeekCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Booking.startDate, order: .forward) private var bookings: [Booking]
    @Query private var clients: [Client]

    @State private var weekOffset = 0
    @State private var isShowingForm = false
    @State private var selectedBooking: Booking?
    @State private var bookingToDelete: Booking?
    @State private var errorMessage: String?
    @State private var currentTime = Date()

    private var smoothAnimation: Animation? {
        reduceMotion ? nil : .snappy(duration: 0.24)
    }

    private var weekStart: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) ?? today
        return calendar.date(byAdding: .day, value: weekOffset * 7, to: monday) ?? monday
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private var weekRange: String {
        let lastDay = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(weekStart.formatted(.dateTime.month(.abbreviated).day())) – \(lastDay.formatted(.dateTime.month(.abbreviated).day().year()))"
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(weekDays, id: \.self) { day in
                    let dayBookings = bookings.filter {
                        Calendar.current.isDate($0.startDate, inSameDayAs: day)
                    }

                    Section {
                        if dayBookings.isEmpty {
                            Text("No bookings")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        } else {
                            ForEach(dayBookings) { booking in
                                BookingRow(
                                    booking: booking,
                                    isPackagePaid: PackagePayment.isPaid(for: booking, clients: clients),
                                    onEdit: {
                                        selectedBooking = booking
                                        isShowingForm = true
                                    },
                                    isSessionOver: booking.startDate.addingTimeInterval(60 * 60) <= currentTime
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
                        HStack {
                            Text(day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                .font(.subheadline.weight(.semibold))
                                .textCase(nil)
                            if Calendar.current.isDateInToday(day) {
                                Spacer()
                                Text("Today")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.green)
                                    .textCase(nil)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .animation(smoothAnimation, value: weekOffset)
            .onAppear { currentTime = Date() }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { currentTime = $0 }
            .navigationTitle("Week")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Button {
                            moveWeek(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .accessibilityLabel("Previous week")

                        Text(weekRange)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Button {
                            moveWeek(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .accessibilityLabel("Next week")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if weekOffset != 0 {
                        Button("Today") { moveWeek(to: 0) }
                    }
                }
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

    private func moveWeek(by offset: Int) {
        moveWeek(to: weekOffset + offset)
    }

    private func moveWeek(to offset: Int) {
        withAnimation(smoothAnimation) {
            weekOffset = offset
        }
    }
}
