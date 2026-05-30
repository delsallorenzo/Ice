import Cocoa

@MainActor
final class MenuBarSection {
    enum Name: CaseIterable {
        case visible, hidden, alwaysHidden
    }

    let name: Name
    let controlItem: ControlItem

    var isHidden: Bool { controlItem.state == .hideItems }

    init(name: Name) {
        self.name = name
        switch name {
        case .visible:    self.controlItem = ControlItem(identifier: .iceIcon)
        case .hidden:     self.controlItem = ControlItem(identifier: .hidden)
        case .alwaysHidden: self.controlItem = ControlItem(identifier: .alwaysHidden)
        }
    }

    func show() { controlItem.state = .showItems }
    func hide() { controlItem.state = .hideItems }
    func toggle() {
        if isHidden { show() } else { hide() }
    }
}
