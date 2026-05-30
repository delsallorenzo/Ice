import Cocoa

@MainActor
final class ControlItem {
    enum Identifier: String, CaseIterable {
        case iceIcon = "SItem"
        case hidden = "HItem"
        case alwaysHidden = "AHItem"
    }

    enum HidingState {
        case hideItems, showItems
    }

    private enum Lengths {
        static let standard: CGFloat = NSStatusItem.variableLength
        static let expanded: CGFloat = 10_000
    }

    var state: HidingState = .hideItems {
        didSet { updateLength() }
    }

    let statusItem: NSStatusItem
    let identifier: Identifier

    var window: NSWindow? { statusItem.button?.window }

    var windowFrame: CGRect? { window?.frame }

    var isVisible: Bool {
        get { statusItem.isVisible }
        set {
            let name = statusItem.autosaveName as String
            let cached = StatusItemDefaults[.preferredPosition, name]
            statusItem.isVisible = newValue
            if !newValue { StatusItemDefaults[.preferredPosition, name] = cached }
        }
    }

    init(identifier: Identifier) {
        let name = identifier.rawValue
        if StatusItemDefaults[.preferredPosition, name] == nil {
            switch identifier {
            case .iceIcon: StatusItemDefaults[.preferredPosition, name] = 0
            case .hidden:  StatusItemDefaults[.preferredPosition, name] = 1
            case .alwaysHidden: break
            }
        }
        self.statusItem = NSStatusBar.system.statusItem(withLength: 0)
        self.statusItem.autosaveName = name
        self.identifier = identifier
        updateLength()
    }

    deinit {
        let name = statusItem.autosaveName as String
        let cached = StatusItemDefaults[.preferredPosition, name]
        NSStatusBar.system.removeStatusItem(statusItem)
        StatusItemDefaults[.preferredPosition, name] = cached
    }

    private func updateLength() {
        switch identifier {
        case .iceIcon:
            statusItem.length = Lengths.standard
        case .hidden, .alwaysHidden:
            statusItem.length = state == .hideItems ? Lengths.expanded : Lengths.standard
        }
    }

    func configureButton(target: AnyObject, action: Selector) {
        guard let button = statusItem.button else { return }
        button.target = target
        button.action = action
        button.sendAction(on: [.leftMouseDown, .rightMouseUp])
        updateIcon(isOpen: false)
    }

    func updateIcon(isOpen: Bool) {
        guard identifier == .iceIcon, let button = statusItem.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let name = isOpen ? "circle" : "circle.fill"
        button.image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
    }
}

extension ControlItem {
    func showMenu(_ menu: NSMenu) {
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
}
