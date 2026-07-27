import SwiftUI

enum CFButtonStyle {
    case primary
    case secondary
    case destructive
}

struct CFButton: View {
    let title: String
    var icon: String?
    var style: CFButtonStyle = .primary
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                }
                Text(title)
                    .font(.body.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: CFDesignTokens.radiusButton, style: .continuous))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: CFDesignTokens.radiusButton, style: .continuous)
                        .strokeBorder(CFDesignTokens.border, lineWidth: 1)
                }
            }
        }
        .buttonStyle(CFPressableButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return CFDesignTokens.accent
        case .secondary:
            return CFDesignTokens.surfaceElevated
        case .destructive:
            return CFDesignTokens.destructive
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return CFDesignTokens.textPrimary
        }
    }
}

struct CFIconButton: View {
    let icon: String
    var tint: Color = CFDesignTokens.textSecondary
    var size: CGFloat = 28
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(CFDesignTokens.surfaceElevated, in: Circle())
        }
        .buttonStyle(CFPressableButtonStyle())
    }
}
