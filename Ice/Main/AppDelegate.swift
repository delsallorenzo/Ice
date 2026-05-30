import Cocoa
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState?
    private var permissionsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let state = AppState()
        self.appState = state

        if state.permissionsManager.hasPermissions {
            state.performSetup()
        } else {
            showPermissionsWindow(for: state)
            // Watch for when permission is granted
            state.permissionsManager.$hasPermissions
                .receive(on: DispatchQueue.main)
                .sink { [weak self, weak state] hasPerms in
                    guard let state, hasPerms else { return }
                    state.performSetup()
                    self?.permissionsWindow?.close()
                    self?.permissionsWindow = nil
                }
                .store(in: &cancellables)
        }
    }

    private func showPermissionsWindow(for state: AppState) {
        let view = PermissionsView()
            .environmentObject(state.permissionsManager)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Hide Menu Bar Apps — Permissions"
        window.styleMask = [.titled, .closable]
        window.setContentSize(hosting.view.fittingSize)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        state.permissionsWindow = window
        self.permissionsWindow = window
    }

    func openSettingsWindow() {
        appState?.openPreferences()
    }
}
