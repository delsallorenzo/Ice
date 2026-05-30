import SwiftUI

extension View {
    func readWindow(_ action: @escaping (NSWindow?) -> Void) -> some View {
        self.background(WindowReader(action: action))
    }
}

private struct WindowReader: NSViewRepresentable {
    let action: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { self.action(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { self.action(nsView.window) }
    }
}
