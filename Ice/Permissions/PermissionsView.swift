import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject var permissionsManager: PermissionsManager

    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSImage(named: NSImage.applicationIconName) ?? NSImage())
                .resizable()
                .frame(width: 64, height: 64)
            Text("Ice needs Accessibility permission to manage the menu bar.")
                .multilineTextAlignment(.center)
            HStack {
                Button("Quit") { NSApp.terminate(nil) }
                Button(permissionsManager.accessibilityPermission.hasPermission ? "Permission Granted ✓" : "Grant Permission") {
                    permissionsManager.accessibilityPermission.performRequest()
                    Task {
                        await permissionsManager.accessibilityPermission.waitForPermission()
                        permissionsManager.appState?.permissionsWindow?.close()
                        permissionsManager.appState?.performSetup()
                    }
                }
                .disabled(permissionsManager.accessibilityPermission.hasPermission)
            }
        }
        .padding(30)
        .frame(width: 340)
    }
}
