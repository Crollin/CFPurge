import AppKit
import SwiftUI

/// The CFPurge mark: two channels narrowing into a clean, empty center.
struct CFPurgeMark: View {
    var size: CGFloat = 28
    var showsBackground = true

    var body: some View {
        ZStack {
            if showsBackground {
                RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                    .fill(CFPurgeBrand.graphite)
            }

            Canvas { context, canvasSize in
                let inset = size * 0.22
                let left = Path { path in
                    path.move(to: CGPoint(x: inset, y: canvasSize.height * 0.30))
                    path.addLine(to: CGPoint(x: canvasSize.width * 0.45, y: canvasSize.height * 0.50))
                    path.addLine(to: CGPoint(x: inset, y: canvasSize.height * 0.70))
                }
                let right = Path { path in
                    path.move(to: CGPoint(x: canvasSize.width - inset, y: canvasSize.height * 0.30))
                    path.addLine(to: CGPoint(x: canvasSize.width * 0.55, y: canvasSize.height * 0.50))
                    path.addLine(to: CGPoint(x: canvasSize.width - inset, y: canvasSize.height * 0.70))
                }

                context.stroke(left, with: .color(CFPurgeBrand.cyan), style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round, lineJoin: .round))
                context.stroke(right, with: .color(CFPurgeBrand.blue), style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round, lineJoin: .round))
            }
            .padding(size * 0.13)

            Circle()
                .fill(CFPurgeBrand.orange)
                .frame(width: size * 0.14, height: size * 0.14)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("CFPurge")
    }
}

enum CFPurgeBrand {
    static let graphite = Color(red: 21 / 255, green: 25 / 255, blue: 34 / 255)
    static let surface = Color(red: 32 / 255, green: 38 / 255, blue: 51 / 255)
    static let cyan = Color(red: 102 / 255, green: 227 / 255, blue: 208 / 255)
    static let blue = Color(red: 79 / 255, green: 124 / 255, blue: 255 / 255)
    static let orange = Color(red: 255 / 255, green: 157 / 255, blue: 77 / 255)
}

/// `MenuBarExtra` n'affiche que Text / Image / Label — un Canvas custom est ignoré
/// (app « agent » sans Dock = impression que rien ne se lance).
enum CFPurgeMenuBarIcon {
    private static let pointSize: CGFloat = 18

    @MainActor
    static let nsImage: NSImage = {
        let content = CFPurgeMark(size: 16, showsBackground: false)
            .frame(width: pointSize, height: pointSize)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2

        if let rendered = renderer.nsImage {
            rendered.isTemplate = false
            rendered.size = NSSize(width: pointSize, height: pointSize)
            return rendered
        }

        return NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "CFPurge")
            ?? NSImage(size: NSSize(width: pointSize, height: pointSize))
    }()
}

#Preview {
    HStack(spacing: 16) {
        CFPurgeMark(size: 64)
        CFPurgeMark(size: 28)
        CFPurgeMark(size: 18, showsBackground: false)
    }
    .padding(24)
    .background(CFPurgeBrand.surface)
}

#Preview {
    HStack(spacing: 16) {
        CFPurgeMark(size: 64)
        CFPurgeMark(size: 28)
        CFPurgeMark(size: 18, showsBackground: false)
    }
    .padding(24)
    .background(CFPurgeBrand.surface)
}
