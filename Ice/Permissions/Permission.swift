import Combine
import Cocoa

@discardableResult
func checkIsProcessTrusted(prompt: Bool = false) -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
}

@MainActor
class Permission: ObservableObject, Identifiable {
    @Published private(set) var hasPermission = false
    let title: String
    let isRequired: Bool
    private let settingsURL: URL?
    private let check: () -> Bool
    private let request: () -> Void
    private var timerCancellable: AnyCancellable?

    init(title: String, isRequired: Bool, settingsURL: URL?, check: @escaping () -> Bool, request: @escaping () -> Void) {
        self.title = title
        self.isRequired = isRequired
        self.settingsURL = settingsURL
        self.check = check
        self.request = request
        self.hasPermission = check()
        startTimer()
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.hasPermission = self.check()
            }
    }

    func performRequest() {
        request()
        if let settingsURL {
            NSWorkspace.shared.open(settingsURL)
        }
    }

    func waitForPermission() async {
        guard !hasPermission else { return }
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = $hasPermission.sink { hasPermission in
                if hasPermission {
                    cancellable?.cancel()
                    continuation.resume()
                }
            }
        }
    }
}

final class AccessibilityPermission: Permission {
    init() {
        super.init(
            title: "Accessibility",
            isRequired: true,
            settingsURL: nil,
            check: { checkIsProcessTrusted() },
            request: { checkIsProcessTrusted(prompt: true) }
        )
    }
}
