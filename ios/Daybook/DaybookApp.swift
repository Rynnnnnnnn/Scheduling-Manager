import SwiftData
import SwiftUI

@main
struct DaybookApp: App {
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
            }
        }
        .modelContainer(for: [Booking.self, Client.self, ServicePackage.self])
    }
}
