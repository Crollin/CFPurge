import AppKit
import SwiftUI

enum CFWindowAppearance {
    @MainActor
    static func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(CFDesignTokens.background)
        window.isMovableByWindowBackground = true
    }
}

struct CFWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                CFWindowAppearance.configure(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            CFWindowAppearance.configure(nsView.window)
        }
    }
}

extension View {
    func cfConfigureWindow() -> some View {
        background(CFWindowConfigurator().frame(width: 0, height: 0))
    }
}
