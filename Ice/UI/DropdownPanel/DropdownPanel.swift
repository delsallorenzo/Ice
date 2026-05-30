import AppKit
import SwiftUI

final class DropdownPanel: NSPanel {
    private let hiddenItems: [MenuBarItem]
    private let alwaysHiddenItems: [MenuBarItem]
    private let iceIconFrame: CGRect
    private let screen: NSScreen
    private weak var manager: MenuBarManager?
    private weak var appState: AppState?

    init(
        hiddenItems: [MenuBarItem],
        alwaysHiddenItems: [MenuBarItem],
        iceIconFrame: CGRect,
        screen: NSScreen,
        manager: MenuBarManager,
        appState: AppState
    ) {
        self.hiddenItems = hiddenItems
        self.alwaysHiddenItems = alwaysHiddenItems
        self.iceIconFrame = iceIconFrame
        self.screen = screen
        self.manager = manager
        self.appState = appState

        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .mainMenu + 1
        self.backgroundColor = .clear
        self.hasShadow = true
        self.animationBehavior = .utilityWindow
        self.collectionBehavior = [.fullScreenAuxiliary, .ignoresCycle, .moveToActiveSpace]
        self.isReleasedWhenClosed = false
    }

    func showPanel() {
        guard let manager, let appState else { return }

        let view = DropdownView(
            hiddenItems: hiddenItems,
            alwaysHiddenItems: alwaysHiddenItems,
            onItemTap: { [weak manager] item in manager?.activateItem(item) },
            onItemMove: { [weak manager] item, toAlwaysHidden in manager?.moveItem(item, toAlwaysHidden: toAlwaysHidden) },
            onClose: { [weak manager] in manager?.closePanel() },
            settingsManager: appState.settingsManager
        )

        let hosting = NSHostingView(rootView: view)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        contentView = hosting

        // Size the panel to fit content
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize
        let panelWidth = max(220, min(size.width + 20, 400))
        let panelHeight = max(40, size.height + 16)

        // Position below the ice icon (convert from AppKit coordinates)
        let screenHeight = screen.frame.height
        let menuBarBottom = screenHeight - iceIconFrame.maxY
        let panelX = iceIconFrame.midX - panelWidth / 2
        let panelY = menuBarBottom - panelHeight - 4

        setFrame(CGRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight), display: false)
        orderFrontRegardless()

        // Close when clicking outside
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if !self.frame.contains(NSEvent.mouseLocation) {
                    self.manager?.closePanel()
                }
            }
        }
    }
}
