import SwiftUI

struct CFToggle: View {
    @Binding var isOn: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: CFDesignTokens.animationNormal)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? CFDesignTokens.accent : CFDesignTokens.surfaceElevated)
                    .frame(width: 44, height: 26)

                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "Activé" : "Désactivé")
    }
}
