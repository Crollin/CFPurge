import SwiftUI

struct CFTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .textFieldStyle(.plain)
        .font(.body)
        .foregroundStyle(CFDesignTokens.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(CFDesignTokens.surfaceElevated, in: RoundedRectangle(cornerRadius: CFDesignTokens.radiusButton, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CFDesignTokens.radiusButton, style: .continuous)
                .strokeBorder(CFDesignTokens.border, lineWidth: 1)
        }
    }
}

struct CFTextFieldLabel: View {
    let label: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(CFDesignTokens.textSecondary)
            CFTextField(placeholder: label, text: $text, isSecure: isSecure)
        }
    }
}
