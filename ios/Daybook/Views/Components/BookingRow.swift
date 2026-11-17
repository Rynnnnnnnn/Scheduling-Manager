import SwiftUI

struct BookingRow: View {
    let booking: Booking
    let onEdit: () -> Void
    let onTogglePayment: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(booking.clientName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(booking.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(booking.startDate.formatted(date: .omitted, time: .shortened)) – \(booking.startDate.addingTimeInterval(60 * 60).formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let packageName = booking.packageName, !packageName.isEmpty {
                        Text("Package: \(packageName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if !booking.notes.isEmpty {
                        Text(booking.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens booking details for editing")

            Button(action: onTogglePayment) {
                Label(
                    booking.isPaid ? "Paid" : "Unpaid",
                    systemImage: booking.isPaid ? "checkmark.circle.fill" : "circle"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(booking.isPaid ? .green : .orange)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(
                    (booking.isPaid ? Color.green : Color.orange).opacity(0.12),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(booking.isPaid ? "Mark unpaid" : "Mark paid")
        }
        .padding(.vertical, 5)
    }
}
