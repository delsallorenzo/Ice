import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    private static var instance: PreferencesWindowController?

    static func open(appState: AppState) {
        if let existing = instance {
            existing.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let wc = PreferencesWindowController(appState: appState)
        instance = wc
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    init(appState: AppState) {
        let view = PreferencesView().environmentObject(appState.settingsManager)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Ice Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(hosting.view.fittingSize)
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }
}
