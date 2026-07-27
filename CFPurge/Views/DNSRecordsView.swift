import SwiftUI

struct DNSRecordsView: View {
    let site: Site

    @EnvironmentObject private var dnsViewModel: DNSViewModel
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(CFDesignTokens.border)
            filters
            Divider().overlay(CFDesignTokens.border)
            recordList
            footer
        }
        .cfWindowBackground()
        .cfConfigureWindow()
        .preferredColorScheme(.dark)
        .frame(minWidth: 640, minHeight: 480)
        .onAppear {
            Task { await dnsViewModel.loadRecords(for: site) }
        }
        .onChange(of: site.id) { _, _ in
            Task { await dnsViewModel.loadRecords(for: site) }
        }
        .sheet(isPresented: $dnsViewModel.showingEditor, onDismiss: {
            dnsViewModel.editingRecord = nil
        }) {
            DNSRecordEditorView(site: site, existingRecord: dnsViewModel.editingRecord)
                .environmentObject(dnsViewModel)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            CFIconBadge(icon: "network", color: CFDesignTokens.accent, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("DNS — \(site.name)")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CFDesignTokens.textPrimary)
                Text(site.domain)
                    .font(.caption)
                    .foregroundStyle(CFDesignTokens.textSecondary)
            }

            Spacer()

            CFButton(title: "Actualiser", icon: "arrow.clockwise", style: .secondary) {
                Task { await dnsViewModel.refresh(for: site) }
            }
            .disabled(dnsViewModel.status.isLoading)

            CFButton(title: "Ajouter", icon: "plus", style: .primary) {
                dnsViewModel.beginAddRecord()
            }
        }
        .padding(16)
        .background(CFDesignTokens.sidebar)
    }

    private var filters: some View {
        HStack(spacing: 12) {
            CFTextField(placeholder: "Rechercher…", text: $dnsViewModel.searchText)

            Picker("Type", selection: $dnsViewModel.typeFilter) {
                ForEach(dnsViewModel.availableTypeFilters, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var recordList: some View {
        if dnsViewModel.status.isLoading && dnsViewModel.records.isEmpty {
            Spacer()
            ProgressView("Chargement des enregistrements…")
                .foregroundStyle(CFDesignTokens.textSecondary)
                .frame(maxWidth: .infinity)
            Spacer()
        } else if let message = dnsViewModel.status.message,
                  case .error = dnsViewModel.status,
                  dnsViewModel.records.isEmpty {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundStyle(CFDesignTokens.accentOrange)
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(CFDesignTokens.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            Spacer()
        } else if dnsViewModel.filteredRecords.isEmpty {
            Spacer()
            Text(dnsViewModel.records.isEmpty ? "Aucun enregistrement DNS." : "Aucun résultat pour ce filtre.")
                .foregroundStyle(CFDesignTokens.textSecondary)
                .frame(maxWidth: .infinity)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(dnsViewModel.filteredRecords) { record in
                        DNSRecordCard(
                            record: record,
                            canEdit: appViewModel.dnsAllowModifyExisting,
                            onEdit: { dnsViewModel.beginEditRecord(record) }
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(16)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            if dnsViewModel.hasMorePages {
                CFButton(title: "Charger plus", style: .secondary) {
                    Task { await dnsViewModel.loadMore(for: site) }
                }
                .disabled(dnsViewModel.status.isLoading)
            }

            if dnsViewModel.status.isLoading && !dnsViewModel.records.isEmpty {
                ProgressView()
                    .controlSize(.small)
            }

            if let message = dnsViewModel.status.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(footerColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
    }

    private var footerColor: Color {
        if case .success = dnsViewModel.status {
            return CFDesignTokens.success
        }
        if case .error = dnsViewModel.status {
            return CFDesignTokens.destructive
        }
        return CFDesignTokens.textSecondary
    }
}

// MARK: - DNS Record Card

private struct DNSRecordCard: View {
    let record: DNSRecord
    let canEdit: Bool
    let onEdit: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            DNSRecordTypeBadge(type: record.type)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(CFDesignTokens.textPrimary)
                    .lineLimit(1)
                Text(record.content)
                    .font(.caption)
                    .foregroundStyle(CFDesignTokens.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: record.proxied == true ? "cloud.fill" : "cloud")
                        .foregroundStyle(record.proxied == true ? CFDesignTokens.accentOrange : CFDesignTokens.textTertiary)
                    Text(record.proxied == true ? "Proxied" : "DNS only")
                        .font(.caption2)
                        .foregroundStyle(CFDesignTokens.textSecondary)
                }

                Text(ttlLabel)
                    .font(.caption2)
                    .foregroundStyle(CFDesignTokens.textTertiary)
            }

            if canEdit {
                CFIconButton(icon: "pencil", tint: CFDesignTokens.textSecondary, action: onEdit)
            }
        }
        .padding(14)
        .cfHoverable(isHovered: isHovered)
        .overlay {
            RoundedRectangle(cornerRadius: CFDesignTokens.radiusCard, style: .continuous)
                .strokeBorder(CFDesignTokens.border, lineWidth: 1)
        }
        .onHover { isHovered = $0 }
    }

    private var ttlLabel: String {
        record.ttl == 1 ? "TTL auto" : "TTL \(record.ttl)s"
    }
}

struct DNSRecordTypeBadge: View {
    let type: String

    var body: some View {
        Text(type)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .frame(width: 64)
    }

    private var badgeColor: Color {
        switch type.uppercased() {
        case "A":
            return Color(red: 0.85, green: 0.45, blue: 0.15)
        case "AAAA":
            return Color(red: 0.75, green: 0.35, blue: 0.20)
        case "CNAME":
            return Color(red: 0.20, green: 0.45, blue: 0.85)
        case "MX":
            return Color(red: 0.55, green: 0.30, blue: 0.75)
        case "TXT":
            return Color(red: 0.45, green: 0.48, blue: 0.52)
        default:
            return .gray
        }
    }
}

#Preview {
    DNSRecordsView(site: Site(name: "Demo", zoneId: "zone", domain: "example.com"))
        .environmentObject(DNSViewModel())
        .environmentObject(AppViewModel())
}
