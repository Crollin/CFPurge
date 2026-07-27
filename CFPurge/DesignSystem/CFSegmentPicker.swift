import SwiftUI

struct CFSegmentPicker<T: Hashable & CaseIterable & RawRepresentable>: View where T.RawValue == String, T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    let visibleCases: [T]

    init(selection: Binding<T>, visibleCases: [T]? = nil) {
        _selection = selection
        self.visibleCases = visibleCases ?? Array(T.allCases)
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(visibleCases, id: \.self) { item in
                Button {
                    withAnimation(.easeInOut(duration: CFDesignTokens.animationNormal)) {
                        selection = item
                    }
                } label: {
                    Text(item.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selection == item ? CFDesignTokens.textPrimary : CFDesignTokens.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .frame(minWidth: 72)
                        .background {
                            if selection == item {
                                RoundedRectangle(cornerRadius: CFDesignTokens.radiusButton, style: .continuous)
                                    .fill(CFDesignTokens.surfaceElevated)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(CFDesignTokens.surface, in: RoundedRectangle(cornerRadius: CFDesignTokens.radiusButton + 2, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CFDesignTokens.radiusButton + 2, style: .continuous)
                .strokeBorder(CFDesignTokens.border, lineWidth: 1)
        }
    }
}
