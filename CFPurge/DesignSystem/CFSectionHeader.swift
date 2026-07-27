import SwiftUI

struct CFSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(CFDesignTokens.textTertiary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}
