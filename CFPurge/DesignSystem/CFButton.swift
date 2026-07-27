import SwiftUI

enum CFButtonStyle {
    case primary
    case secondary
    case destructive
}

enum CFButtonSize {
    case regular
    case compact

    var horizontalPadding: CGFloat {
        switch self {
        case .regular: return 14
        case .compact: return 10
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .regular: return 8
        case .compact: return 6
        }
    }
}

struct CFButton: View {
    let title: String
    var icon: String?
    var style: CFButtonStyle = .primary
    var size: CFButtonSize = .regular
    var expands: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(size == .compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                }
                Text(title)
                    .font(size == .compact ? .caption.weight(.medium) : .body.weight(.medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: expands ? .infinity : nil)
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
