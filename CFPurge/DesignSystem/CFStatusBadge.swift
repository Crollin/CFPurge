import SwiftUI

enum CFStatusBadgeStyle {
    case active
    case configured
    case warning

    var label: String {
        switch self {
        case .active: return "ACTIF"
        case .configured: return "CONFIGURÉ"
        case .warning: return "CONFIG REQUISE"
        }
    }

    var color: Color {
        switch self {
        case .active, .configured: return CFDesignTokens.success
        case .warning: return CFDesignTokens.accentOrange
        }
    }
}

struct CFStatusBadge: View {
    let style: CFStatusBadgeStyle

    var body: some View {
        Text(style.label)
            .font(.caption2.weight(.bold))
            .foregroundStyle(style.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(style.color.opacity(0.15), in: Capsule())
    }
}
