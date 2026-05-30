import SwiftUI
import AppKit

struct DropdownView: View {
    let hiddenItems: [MenuBarItem]
    let alwaysHiddenItems: [MenuBarItem]
    let onItemTap: (MenuBarItem) -> Void
    let onItemMove: (MenuBarItem, Bool) -> Void
    let onClose: () -> Void
    @ObservedObject var settingsManager: SettingsManager

    @State private var draggingItem: MenuBarItem?

    private var showAlwaysHiddenSection: Bool {
        settingsManager.enableAlwaysHidden && !alwaysHiddenItems.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !hiddenItems.isEmpty {
                sectionView(items: hiddenItems, isAlwaysHidden: false)
            }

            if showAlwaysHiddenSection {
                Divider().padding(.vertical, 4)
                sectionView(items: alwaysHiddenItems, isAlwaysHidden: true)
            }

            if hiddenItems.isEmpty && alwaysHiddenItems.isEmpty {
                Text("No hidden items")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.separator, lineWidth: 0.5))
    }

    @ViewBuilder
    private func sectionView(items: [MenuBarItem], isAlwaysHidden: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(items, id: \.info) { item in
                itemRow(item, isAlwaysHidden: isAlwaysHidden)
            }
        }
        .onDrop(of: [.text], delegate: ItemDropDelegate(
            isAlwaysHiddenTarget: isAlwaysHidden,
            draggingItem: $draggingItem,
            onMove: onItemMove
        ))
    }

    @ViewBuilder
    private func itemRow(_ item: MenuBarItem, isAlwaysHidden: Bool) -> some View {
        Button {
            onItemTap(item)
        } label: {
            HStack(spacing: 8) {
                if settingsManager.displayMode != .textOnly {
                    itemIcon(item)
                }
                if settingsManager.displayMode != .iconOnly {
                    Text(item.displayName)
                        .font(.system(size: 13))
                        .lineLimit(1)
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .hoverEffect()
        .onDrag {
            draggingItem = item
            return NSItemProvider(object: item.info.description as NSString)
        }
    }

    @ViewBuilder
    private func itemIcon(_ item: MenuBarItem) -> some View {
        if let app = item.owningApplication,
           let icon = app.icon {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 16, height: 16)
        } else {
            Image(systemName: "app.fill")
                .frame(width: 16, height: 16)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Hover effect

extension View {
    func hoverEffect() -> some View {
        self.modifier(HoverEffectModifier())
    }
}

struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color.primary.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
            .onHover { isHovered = $0 }
    }
}

// MARK: - Drop delegate

struct ItemDropDelegate: DropDelegate {
    let isAlwaysHiddenTarget: Bool
    @Binding var draggingItem: MenuBarItem?
    let onMove: (MenuBarItem, Bool) -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard let item = draggingItem else { return false }
        onMove(item, isAlwaysHiddenTarget)
        draggingItem = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
