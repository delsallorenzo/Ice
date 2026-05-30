import Cocoa
import Combine

@MainActor
final class AppState: ObservableObject {
    let menuBarManager: MenuBarManager
    let permissionsManager: PermissionsManager
    let settingsManager: SettingsManager

    weak var appDelegate: AppDelegate?
    weak var permissionsWindow: NSWindow?

    init() {
        self.settingsManager = SettingsManager()
        let mbm = MenuBarManager()
        let pm = PermissionsManager()
        self.menuBarManager = mbm
        self.permissionsManager = pm
        mbm.appState = self
        pm.appState = self
    }

    func performSetup() {
        menuBarManager.performSetup()
    }

    func assignPermissionsWindow(_ window: NSWindow) {
        permissionsWindow = window
    }

    func openPreferences() {
        PreferencesWindowController.open(appState: self)
    }
}
