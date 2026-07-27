import SwiftUI

struct SiteEditorView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let site: Site?

    @State private var name: String = ""
    @State private var zoneId: String = ""
    @State private var domain: String = ""
    @State private var validationMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(site == nil ? "Ajouter un site" : "Modifier le site")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CFDesignTokens.textPrimary)

            CFCard {
                VStack(alignment: .leading, spacing: 14) {
                    CFTextFieldLabel(label: "Nom", text: $name)
                    CFTextFieldLabel(label: "Zone ID", text: $zoneId)
                    CFTextFieldLabel(label: "Domaine", text: $domain)
                }
                .padding(16)
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(CFDesignTokens.destructive)
            }

            HStack {
                Spacer()
                CFButton(title: "Annuler", style: .secondary) {
                    dismiss()
                }
                CFButton(title: site == nil ? "Ajouter" : "Enregistrer", style: .primary) {
                    saveSite()
                }
            }
        }
        .padding(24)
        .frame(width: 440)
        .cfWindowBackground()
        .cfConfigureWindow()
        .preferredColorScheme(.dark)
        .onAppear {
            name = site?.name ?? ""
            zoneId = site?.zoneId ?? ""
            domain = site?.domain ?? ""
        }
    }

    private func saveSite() {
        do {
            let trimmedName = try SiteValidator.validateSiteName(name)
            let trimmedZoneId = try SiteValidator.validateZoneId(zoneId)
            let trimmedDomain = try SiteValidator.validateDomain(domain)

            if let site {
                viewModel.updateSite(Site(
                    id: site.id,
                    name: trimmedName,
                    zoneId: trimmedZoneId,
                    domain: trimmedDomain,
                    sortOrder: site.sortOrder
                ))
            } else {
                viewModel.addSite(Site(name: trimmedName, zoneId: trimmedZoneId, domain: trimmedDomain))
            }

            dismiss()
        } catch {
            validationMessage = error.localizedDescription
        }
    }
}

#Preview {
    SiteEditorView(site: Site(name: "Demo", zoneId: "a1b2c3d4e5f6789012345678abcdef01", domain: "example.com"))
        .environmentObject(AppViewModel())
}
