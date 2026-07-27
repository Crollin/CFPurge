import SwiftUI

extension View {
    func cfWindowBackground() -> some View {
        background(CFDesignTokens.background)
    }

    func cfCardStyle() -> some View {
        background(CFDesignTokens.surface, in: RoundedRectangle(cornerRadius: CFDesignTokens.radiusCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFDesignTokens.radiusCard, style: .continuous)
                    .strokeBorder(CFDesignTokens.border, lineWidth: 1)
            }
    }

    func cfSidebarSelection(_ isSelected: Bool) -> some View {
        background {
            if isSelected {
                RoundedRectangle(cornerRadius: CFDesignTokens.radiusSidebarItem, style: .continuous)
                    .fill(CFDesignTokens.accent)
            }
        }
    }

    func cfHoverable(isHovered: Bool) -> some View {
        background(
            isHovered ? CFDesignTokens.surfaceElevated : CFDesignTokens.surface,
            in: RoundedRectangle(cornerRadius: CFDesignTokens.radiusCard, style: .continuous)
        )
        .animation(.easeInOut(duration: CFDesignTokens.animationFast), value: isHovered)
    }

    func cfPressable() -> some View {
        buttonStyle(CFPressableButtonStyle())
    }
}

struct CFPressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeInOut(duration: CFDesignTokens.animationFast), value: configuration.isPressed)
    }
}
