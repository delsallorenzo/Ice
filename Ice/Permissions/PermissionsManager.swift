import Combine
import Foundation

@MainActor
final class PermissionsManager: ObservableObject {
    @Published var hasPermissions = false
    let accessibilityPermission: AccessibilityPermission
    weak var appState: AppState?
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.accessibilityPermission = AccessibilityPermission()
        self.hasPermissions = accessibilityPermission.hasPermission
        accessibilityPermission.$hasPermission
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in self?.hasPermissions = value }
            .store(in: &cancellables)
    }

    func setAppState(_ state: AppState) {
        self.appState = state
    }
}
