import SwiftUI

struct SiteEditorView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let site: Site?

    @State private var name: String = ""
    @State private var provider: CDNProvider = .cloudflare
    @State private var zoneId: String = ""
    @State private var hostingUsername: String = ""
    @State private var domain: String = ""
    @State private var validationMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(site == nil ? "Ajouter un site" : "Modifier le site")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CFDesignTokens.textPrimary)

            CFCard {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fournisseur")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(CFDesignTokens.textSecondary)
                        Picker("Fournisseur", selection: $provider) {
                            ForEach(CDNProvider.allCases) { item in
                                Text(item.displayName).tag(item)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .disabled(site != nil)
                    }

                    CFTextFieldLabel(label: "Nom", text: $name)

                    if provider == .cloudflare {
                        CFTextFieldLabel(label: "Zone ID", text: $zoneId)
                    } else {
                        CFTextFieldLabel(label: "Utilisateur hébergement", text: $hostingUsername)
                        Text("Visible dans hPanel (ex. u123456789). Requis pour vider le cache.")
                            .font(.caption2)
                            .foregroundStyle(CFDesignTokens.textTertiary)
                    }

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
        .frame(width: 460)
        .cfWindowBackground()
        .cfConfigureWindow()
        .preferredColorScheme(.dark)
        .onAppear {
            name = site?.name ?? ""
            provider = site?.provider ?? .cloudflare
            zoneId = site?.zoneId ?? ""
            hostingUsername = site?.hostingUsername ?? ""
            domain = site?.domain ?? ""
        }
    }

    private func saveSite() {
        do {
            let trimmedName = try SiteValidator.validateSiteName(name)
            let trimmedDomain = try SiteValidator.validateDomain(domain)

            let newSite: Site
            switch provider {
            case .cloudflare:
                let trimmedZoneId = try SiteValidator.validateZoneId(zoneId)
                newSite = Site(
                    id: site?.id ?? UUID(),
                    name: trimmedName,
                    zoneId: trimmedZoneId,
                    domain: trimmedDomain,
                    sortOrder: site?.sortOrder ?? 0,
                    provider: .cloudflare,
                    hostingUsername: nil
                )
            case .hostinger:
                let trimmedUsername = try SiteValidator.validateHostingUsername(hostingUsername)
                newSite = Site(
                    id: site?.id ?? UUID(),
                    name: trimmedName,
                    zoneId: "",
                    domain: trimmedDomain,
                    sortOrder: site?.sortOrder ?? 0,
                    provider: .hostinger,
                    hostingUsername: trimmedUsername
                )
            }

            if site != nil {
                viewModel.updateSite(newSite)
            } else {
                viewModel.addSite(newSite)
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
