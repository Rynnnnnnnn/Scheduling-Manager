import SwiftUI

struct BookingRow: View {
    let booking: Booking
    let isPackagePaid: Bool
    let onEdit: () -> Void
    let isSessionOver: Bool = false

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
                        .foregroundStyle(isSessionOver ? Color.red : Color.secondary)
                    if isSessionOver {
                        Text("Session over")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    }
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

            Label(
                isPackagePaid ? "Package paid" : "Unpaid",
                systemImage: isPackagePaid ? "checkmark.circle.fill" : "circle"
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(isPackagePaid ? .green : .orange)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                (isPackagePaid ? Color.green : Color.orange).opacity(0.12),
                in: Capsule()
            )
            .accessibilityLabel(isPackagePaid ? "Package paid" : "Unpaid")
        }
        .padding(.vertical, 5)
        .overlay(alignment: .leading) {
            if isSessionOver {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red)
                    .frame(width: 3)
                    .padding(.vertical, 8)
            }
        }
    }
}
