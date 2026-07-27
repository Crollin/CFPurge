import SwiftUI

enum CFDesignTokens {
    // Surfaces (dark-first)
    static let background = Color(hex: "#0D0D0E")
    static let sidebar = Color(hex: "#121214")
    static let surface = Color(hex: "#1A1A1C")
    static let surfaceElevated = Color(hex: "#252528")
    static let border = Color.white.opacity(0.08)

    // Texte
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.35)

    // Accents (charte CFPurge)
    static let accent = CFPurgeBrand.blue
    static let accentCyan = CFPurgeBrand.cyan
    static let accentOrange = CFPurgeBrand.orange
    static let destructive = Color(hex: "#FF453A")
    static let success = Color(hex: "#22C55E")

    // Sidebar icon backgrounds
    static let iconPurple = Color(hex: "#8B5CF6")
    static let iconOrange = Color(hex: "#F97316")
    static let iconGreen = Color(hex: "#22C55E")
    static let iconBlue = Color(hex: "#3B82F6")

    // Radius
    static let radiusCard: CGFloat = 12
    static let radiusButton: CGFloat = 8
    static let radiusPill: CGFloat = 999
    static let radiusSidebarItem: CGFloat = 8

    // Motion
    static let animationFast: Double = 0.15
    static let animationNormal: Double = 0.2
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
