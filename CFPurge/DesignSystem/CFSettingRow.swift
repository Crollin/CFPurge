import SwiftUI

struct CFSettingRow<Control: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(CFDesignTokens.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CFDesignTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            control()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct CFSettingRowDivider: View {
    var body: some View {
        Divider()
            .overlay(CFDesignTokens.border)
            .padding(.leading, 16)
    }
}
