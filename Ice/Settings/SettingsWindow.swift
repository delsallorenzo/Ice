import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        Form {
            Section {
                Picker("Display mode", selection: $settingsManager.displayMode) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section {
                Toggle("Enable Always-Hidden section", isOn: $settingsManager.enableAlwaysHidden)
            } footer: {
                Text("When enabled, Cmd+Click on the dot shows a second section for items you want permanently hidden — even from the panel. Useful for reorganizing them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 380)
    }
}
