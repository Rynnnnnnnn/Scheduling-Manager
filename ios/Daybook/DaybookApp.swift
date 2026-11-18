import SwiftData
import SwiftUI

@main
struct DaybookApp: App {
    @AppStorage("daybook.fontScale") private var fontScale: Double = 1.15

    private var contentSizeCategory: ContentSizeCategory {
        switch fontScale {
        case ..<1.08: return .large
        case ..<1.22: return .xLarge
        case ..<1.40: return .xxLarge
        default: return .xxxLarge
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                BookingsView()
                    .tabItem {
                        Label("Schedule", systemImage: "list.bullet")
                    }

                WeekCalendarView()
                    .tabItem {
                        Label("Week", systemImage: "calendar")
                    }

                ClientsView()
                    .tabItem {
                        Label("Clients", systemImage: "person.2")
                    }

                PackagesView()
                    .tabItem {
                        Label("Packages", systemImage: "shippingbox")
                    }

                LogsView()
                    .tabItem {
                        Label("Logs", systemImage: "clock.arrow.circlepath")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            .environment(\.sizeCategory, contentSizeCategory)
        }
        .modelContainer(for: [Booking.self, Client.self, ServicePackage.self])
    }
}
