import SwiftUI

struct DNSRecordEditorView: View {
    let site: Site
    let existingRecord: DNSRecord?

    @EnvironmentObject private var dnsViewModel: DNSViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var recordType = DNSRecordType.a.rawValue
    @State private var name = "@"
    @State private var content = ""
    @State private var ttl = 1
    @State private var proxied = false
    @State private var validationMessage: String?
    @State private var isSaving = false

    private let cloudflareTTLOptions: [(label: String, value: Int)] = [
        ("Auto", 1),
        ("5 min", 300),
        ("1 h", 3600),
        ("1 jour", 86400)
    ]

    private let hostingerTTLOptions: [(label: String, value: Int)] = [
        ("5 min", 300),
        ("1 h", 3600),
        ("4 h", 14400),
        ("1 jour", 86400)
    ]

    private var ttlOptions: [(label: String, value: Int)] {
        site.provider == .hostinger ? hostingerTTLOptions : cloudflareTTLOptions
    }

    private var isEditing: Bool {
        existingRecord != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(isEditing ? "Modifier l'enregistrement DNS" : "Nouvel enregistrement DNS")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CFDesignTokens.textPrimary)

            CFCard {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Type")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(CFDesignTokens.textSecondary)
                        Picker("Type", selection: $recordType) {
                            ForEach(DNSRecordType.allCases) { type in
                                Text(type.rawValue).tag(type.rawValue)
                            }
                        }
                        .labelsHidden()
                        .disabled(isEditing)
                    }

                    CFTextFieldLabel(label: "Nom (@, www, sous-domaine)", text: $name)
                    CFTextFieldLabel(label: contentPlaceholder, text: $content)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("TTL")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(CFDesignTokens.textSecondary)
                        Picker("TTL", selection: $ttl) {
                            ForEach(ttlOptions, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                        .labelsHidden()
                    }

                    if selectedType.isProxiable && site.provider.supportsProxiedDNS {
                        CFSettingRow(
                            title: "Proxied (nuage orange)",
                            subtitle: "Active le proxy Cloudflare pour cet enregistrement."
                        ) {
                            CFToggle(isOn: $proxied)
                        }
                    }

                    Text("Nom complet : \(DNSRecordValidator.fullRecordName(name, domain: site.domain))")
                        .font(.caption)
                        .foregroundStyle(CFDesignTokens.textSecondary)
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
                CFButton(title: isEditing ? "Enregistrer" : "Créer", style: .primary) {
                    Task { await saveRecord() }
                }
                .disabled(isSaving)
            }
        }
        .padding(24)
        .frame(width: 480)
        .cfWindowBackground()
        .cfConfigureWindow()
        .preferredColorScheme(.dark)
        .onAppear {
            if site.provider == .hostinger {
                ttl = 14400
            }
            prefillIfEditing()
        }
    }

    private var selectedType: DNSRecordType {
        DNSRecordType(rawValue: recordType) ?? .a
    }

    private var contentPlaceholder: String {
        switch selectedType {
        case .a:
            return "Adresse IPv4 (ex. 192.0.2.1)"
        case .aaaa:
            return "Adresse IPv6"
        case .cname:
            return "Cible (ex. target.example.com)"
        case .mx:
            return "Serveur mail (ex. mail.example.com)"
        case .txt:
            return "Valeur TXT"
        }
    }

    private func prefillIfEditing() {
        guard let record = existingRecord else { return }

        recordType = record.type.uppercased()
        name = relativeName(for: record.name)
        content = record.content
        ttl = closestTTLOption(for: record.ttl)
        proxied = record.proxied ?? false
    }

    private func relativeName(for fullName: String) -> String {
        let domain = site.domain
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let lower = fullName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if lower == domain {
            return "@"
        }

        let suffix = ".\(domain)"
        if lower.hasSuffix(suffix) {
            return String(lower.dropLast(suffix.count))
        }

        return fullName
    }

    private func closestTTLOption(for value: Int) -> Int {
        if ttlOptions.contains(where: { $0.value == value }) {
            return value
        }
        return site.provider == .hostinger ? 14400 : 1
    }

    private func saveRecord() async {
        validationMessage = nil
        isSaving = true
        defer { isSaving = false }

        let success: Bool
        if let existingRecord {
            success = await dnsViewModel.updateRecord(
                for: site,
                recordId: existingRecord.id,
                type: recordType,
                name: name,
                content: content,
                ttl: ttl,
                proxied: proxied
            )
        } else {
            success = await dnsViewModel.createRecord(
                for: site,
                type: recordType,
                name: name,
                content: content,
                ttl: ttl,
                proxied: proxied
            )
        }

        if success {
            dismiss()
        } else if case .error(let message) = dnsViewModel.status {
            validationMessage = message
        }
    }
}

#Preview("Création") {
    DNSRecordEditorView(site: Site(name: "Demo", zoneId: "zone", domain: "example.com"), existingRecord: nil)
        .environmentObject(DNSViewModel())
}

#Preview("Modification") {
    DNSRecordEditorView(
        site: Site(name: "Demo", zoneId: "zone", domain: "example.com"),
        existingRecord: DNSRecord(
            id: "rec1",
            type: "A",
            name: "www.example.com",
            content: "192.0.2.1",
            ttl: 1,
            proxied: true,
            proxiable: true
        )
    )
    .environmentObject(DNSViewModel())
}
