import SwiftUI

struct CFIconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}
