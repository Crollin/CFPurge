import SwiftUI

struct CFSidebarItem: View {
    let title: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                CFIconBadge(icon: icon, color: iconColor, size: 24)

                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isSelected ? .white : CFDesignTokens.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(RoundedRectangle(cornerRadius: CFDesignTokens.radiusSidebarItem, style: .continuous))
            .cfSidebarSelection(isSelected)
            .background {
                if !isSelected && isHovered {
                    RoundedRectangle(cornerRadius: CFDesignTokens.radiusSidebarItem, style: .continuous)
                        .fill(CFDesignTokens.surfaceElevated.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: CFDesignTokens.animationFast), value: isSelected)
    }
}
