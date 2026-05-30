import Combine
import Foundation

enum DisplayMode: String, CaseIterable {
    case iconOnly = "Icon Only"
    case textOnly = "Text Only"
    case both = "Icon and Text"
}

@MainActor
final class SettingsManager: ObservableObject {
    @Published var displayMode: DisplayMode {
        didSet { UserDefaults.standard.set(displayMode.rawValue, forKey: "displayMode") }
    }
    @Published var enableAlwaysHidden: Bool {
        didSet { UserDefaults.standard.set(enableAlwaysHidden, forKey: "enableAlwaysHidden") }
    }

    init() {
        let savedMode = UserDefaults.standard.string(forKey: "displayMode")
        self.displayMode = DisplayMode(rawValue: savedMode ?? "") ?? .both
        self.enableAlwaysHidden = UserDefaults.standard.object(forKey: "enableAlwaysHidden") as? Bool ?? true
    }
}
