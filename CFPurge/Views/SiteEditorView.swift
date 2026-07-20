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
        VStack(alignment: .leading, spacing: 16) {
            Text(site == nil ? "Ajouter un site" : "Modifier le site")
                .font(.title2)

            Form {
                TextField("Nom", text: $name)
                TextField("Zone ID", text: $zoneId)
                TextField("Domaine", text: $domain)
            }
            .formStyle(.grouped)

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Annuler") {
                    dismiss()
                }
                Button(site == nil ? "Ajouter" : "Enregistrer") {
                    saveSite()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            name = site?.name ?? ""
            zoneId = site?.zoneId ?? ""
            domain = site?.domain ?? ""
        }
    }

    private func saveSite() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedZoneId = zoneId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDomain = domain
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard !trimmedName.isEmpty, !trimmedZoneId.isEmpty, !trimmedDomain.isEmpty else {
            validationMessage = "Tous les champs sont obligatoires."
            return
        }

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
    }
}

#Preview {
    SiteEditorView(site: Site(name: "Demo", zoneId: "zone123", domain: "example.com"))
        .environmentObject(AppViewModel())
}
