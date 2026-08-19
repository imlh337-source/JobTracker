import SwiftUI

@main
struct JobTrackerApp: App {
    @StateObject private var store = ApplicationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Application") {
                    NotificationCenter.default.post(name: .newApplicationRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(replacing: .printItem) {
                Button("Print Applications…") {
                    NotificationCenter.default.post(name: .printApplicationsRequested, object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let newApplicationRequested = Notification.Name("newApplicationRequested")
    static let printApplicationsRequested = Notification.Name("printApplicationsRequested")
}
