import SwiftUI

struct SettingsView: View {
    private struct FontOption: Identifiable {
        let scale: Double
        let label: String
        var id: Double { scale }
    }

    @AppStorage("daybook.fontScale") private var fontScale: Double = 1.15

    private let fontOptions: [FontOption] = [
        FontOption(scale: 1.00, label: "Normal (100%)"),
        FontOption(scale: 1.15, label: "A little bigger (115%)"),
        FontOption(scale: 1.30, label: "Bigger (130%)"),
        FontOption(scale: 1.50, label: "Extra large (150%)")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Text size", selection: $fontScale) {
                        ForEach(fontOptions) { option in
                            Text(option.label).tag(option.scale)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Font size")
                } footer: {
                    Text("Make text easier to read. This applies throughout the whole app.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your schedule")
                            .font(.headline)
                        Text("Keep track of your clients and bookings.")
                            .font(.body)
                        Text("Client name · 10 sessions left")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
