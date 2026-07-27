import SwiftUI

struct PurgeStatusBanner: View {
    let status: PurgeStatus

    var body: some View {
        if let message = status.message {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(titleColor)

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(CFDesignTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: CFDesignTokens.radiusCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFDesignTokens.radiusCard, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var title: String {
        switch status {
        case .idle:
            return ""
        case .loading:
            return "Vidage en cours"
        case .success:
            return "Succès"
        case .error:
            return "Erreur"
        }
    }

    private var iconName: String {
        switch status {
        case .idle:
            return "circle"
        case .loading:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch status {
        case .idle:
            return CFDesignTokens.textSecondary
        case .loading:
            return CFDesignTokens.accentOrange
        case .success:
            return CFDesignTokens.success
        case .error:
            return CFDesignTokens.destructive
        }
    }

    private var titleColor: Color {
        switch status {
        case .success:
            return CFDesignTokens.success
        case .error:
            return CFDesignTokens.destructive
        default:
            return CFDesignTokens.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .loading:
            return CFDesignTokens.accentOrange.opacity(0.08)
        case .success:
            return CFDesignTokens.success.opacity(0.08)
        case .error:
            return CFDesignTokens.destructive.opacity(0.08)
        case .idle:
            return .clear
        }
    }

    private var borderColor: Color {
        switch status {
        case .loading:
            return CFDesignTokens.accentOrange.opacity(0.25)
        case .success:
            return CFDesignTokens.success.opacity(0.25)
        case .error:
            return CFDesignTokens.destructive.opacity(0.25)
        case .idle:
            return .clear
        }
    }
}
