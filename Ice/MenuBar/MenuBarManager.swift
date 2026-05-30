import Cocoa
import Combine

@MainActor
final class MenuBarManager: NSObject, ObservableObject {
    let visibleSection: MenuBarSection
    let hiddenSection: MenuBarSection
    let alwaysHiddenSection: MenuBarSection

    @Published private(set) var isPanelOpen = false

    weak var appState: AppState?
    private var dropdownPanel: DropdownPanel?
    private var cancellables = Set<AnyCancellable>()

    var sections: [MenuBarSection] { [visibleSection, hiddenSection, alwaysHiddenSection] }

    override init() {
        self.visibleSection = MenuBarSection(name: .visible)
        self.hiddenSection = MenuBarSection(name: .hidden)
        self.alwaysHiddenSection = MenuBarSection(name: .alwaysHidden)
        super.init()
    }

    func performSetup() {
        visibleSection.controlItem.configureButton(target: self, action: #selector(handleClick))

        guard let appState else { return }
        appState.settingsManager.$enableAlwaysHidden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.alwaysHiddenSection.controlItem.isVisible = enabled
            }
            .store(in: &cancellables)
    }

    func section(withName name: MenuBarSection.Name) -> MenuBarSection? {
        sections.first { $0.name == name }
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else { return }
        switch event.type {
        case .rightMouseUp:
            showContextMenu()
        case .leftMouseDown:
            let isCmdPressed = NSEvent.modifierFlags.contains(.command)
            if isPanelOpen {
                closePanel()
            } else {
                openPanel(includeAlwaysHidden: isCmdPressed)
            }
        default:
            break
        }
    }

    // MARK: - Panel open/close

    func openPanel(includeAlwaysHidden: Bool) {
        guard let appState, let screen = NSScreen.main,
              let iceIconFrame = visibleSection.controlItem.windowFrame else { return }

        hiddenSection.show()
        if includeAlwaysHidden { alwaysHiddenSection.show() }

        Task {
            try? await Task.sleep(for: .milliseconds(200))

            let all = MenuBarItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true)

            guard let hiddenCI = all.first(where: { $0.info == .hiddenControlItem }) else {
                self.hiddenSection.hide()
                if includeAlwaysHidden { self.alwaysHiddenSection.hide() }
                return
            }

            let alwaysHiddenCI = includeAlwaysHidden
                ? all.first(where: { $0.info == .alwaysHiddenControlItem })
                : nil

            let predicates = Predicates.sectionPredicates(
                hiddenControlItem: hiddenCI,
                alwaysHiddenControlItem: alwaysHiddenCI
            )

            let skip: Set<MenuBarItemInfo> = [.hiddenControlItem, .alwaysHiddenControlItem, .iceIcon]

            let hiddenItems = all.filter { item in
                item.canBeHidden && !skip.contains(item.info) && predicates.isInHiddenSection(item)
            }
            let alwaysHiddenItems = includeAlwaysHidden
                ? all.filter { item in item.canBeHidden && !skip.contains(item.info) && predicates.isInAlwaysHiddenSection(item) }
                : []

            self.hiddenSection.hide()
            if includeAlwaysHidden { self.alwaysHiddenSection.hide() }

            let panel = DropdownPanel(
                hiddenItems: hiddenItems,
                alwaysHiddenItems: alwaysHiddenItems,
                iceIconFrame: iceIconFrame,
                screen: screen,
                manager: self,
                appState: appState
            )
            panel.delegate = self
            self.dropdownPanel = panel
            self.isPanelOpen = true
            self.visibleSection.controlItem.updateIcon(isOpen: true)
            panel.showPanel()
        }
    }

    func closePanel() {
        dropdownPanel?.close()
        dropdownPanel = nil
        isPanelOpen = false
        visibleSection.controlItem.updateIcon(isOpen: false)
    }

    // MARK: - Item activation

    func activateItem(_ item: MenuBarItem) {
        closePanel()

        let isAlwaysHidden = alwaysHiddenSection.controlItem.windowFrame
            .map { item.frame.maxX <= $0.minX } ?? false

        if isAlwaysHidden { alwaysHiddenSection.show() }
        hiddenSection.show()

        Task {
            try? await Task.sleep(for: .milliseconds(200))
            let liveFrame = MenuBarItem.getMenuBarItems(onScreenOnly: true, activeSpaceOnly: true)
                .first(where: { $0.info == item.info })?.frame
            if let frame = liveFrame {
                self.simulateClick(at: CGPoint(x: frame.midX, y: frame.midY), pid: item.ownerPID)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.hiddenSection.hide()
                self?.alwaysHiddenSection.hide()
            }
        }
    }

    private func simulateClick(at point: CGPoint, pid: pid_t) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)?.postToPid(pid)
        CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)?.postToPid(pid)
    }

    // MARK: - Move item between sections

    func moveItem(_ item: MenuBarItem, toAlwaysHidden: Bool) {
        hiddenSection.show()
        alwaysHiddenSection.show()

        Task {
            try? await Task.sleep(for: .milliseconds(200))
            let all = MenuBarItem.getMenuBarItems(onScreenOnly: true, activeSpaceOnly: true)
            guard let liveItem = all.first(where: { $0.info == item.info }) else {
                self.hiddenSection.hide(); self.alwaysHiddenSection.hide(); return
            }
            let targetCI = toAlwaysHidden ? self.alwaysHiddenSection.controlItem : self.hiddenSection.controlItem
            guard let targetFrame = targetCI.windowFrame else {
                self.hiddenSection.hide(); self.alwaysHiddenSection.hide(); return
            }
            let dest = CGPoint(x: targetFrame.minX - 10, y: liveItem.frame.midY)
            self.simulateDrag(from: CGPoint(x: liveItem.frame.midX, y: liveItem.frame.midY), to: dest, pid: liveItem.ownerPID)
            try? await Task.sleep(for: .milliseconds(500))
            self.hiddenSection.hide()
            self.alwaysHiddenSection.hide()
        }
    }

    private func simulateDrag(from start: CGPoint, to end: CGPoint, pid: pid_t) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        func post(_ type: CGEventType, at pt: CGPoint) {
            let e = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: pt, mouseButton: .left)
            e?.flags = (e?.flags ?? []).union(.maskCommand)
            e?.postToPid(pid)
        }

        post(.leftMouseDown, at: start)
        for i in 1...15 {
            let t = CGFloat(i) / 15
            post(.leftMouseDragged, at: CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t))
            Thread.sleep(forTimeInterval: 0.016)
        }
        post(.leftMouseUp, at: end)
    }

    // MARK: - Context menu

    private func showContextMenu() {
        let menu = NSMenu(title: "Hide Menu Bar Apps")
        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.keyEquivalentModifierMask = .command
        prefsItem.target = self
        menu.addItem(prefsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)

        visibleSection.controlItem.showMenu(menu)
    }

    @objc private func openPreferences() {
        appState?.openPreferences()
    }
}

// MARK: - NSWindowDelegate

extension MenuBarManager: NSWindowDelegate {
    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            if notification.object as? NSPanel === self.dropdownPanel {
                self.isPanelOpen = false
                self.visibleSection.controlItem.updateIcon(isOpen: false)
                self.dropdownPanel = nil
            }
        }
    }
}

// MARK: - Legacy stubs

extension MenuBarManager {
    var iceBarPanel: NSPanel { NSPanel() }
    var isMenuBarHiddenBySystem: Bool { false }
    var isMenuBarHiddenBySystemUserDefaults: Bool { false }
    func getApplicationMenuFrame(for display: CGDirectDisplayID) -> CGRect? { nil }
}
