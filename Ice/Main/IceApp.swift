import SwiftUI

@main
struct IceApp: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate

    var body: some Scene {
        // All UI is managed programmatically by AppDelegate.
        // This empty Settings scene is required for @main.
        Settings { EmptyView() }
    }
}
