import Foundation
import SwiftUI

@MainActor
final class DNSViewModel: ObservableObject {
    @Published var records: [DNSRecord] = []
    @Published var status: DNSStatus = .idle
    @Published var searchText = ""
    @Published var typeFilter: String = "Tous"
    @Published var showingEditor = false
    @Published var currentPage = 1
    @Published var hasMorePages = false

    private var activeSite: Site?

    var filteredRecords: [DNSRecord] {
        records.filter { record in
            let matchesSearch: Bool
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let query = searchText.lowercased()
                matchesSearch = record.name.lowercased().contains(query)
                    || record.content.lowercased().contains(query)
                    || record.type.lowercased().contains(query)
            }

            let matchesType = typeFilter == "Tous" || record.type == typeFilter
            return matchesSearch && matchesType
        }
    }

    var availableTypeFilters: [String] {
        ["Tous"] + DNSRecordType.allCases.map(\.rawValue)
    }

    func loadRecords(for site: Site, reset: Bool = true) async {
        guard let token = KeychainService.loadToken() else {
            status = .error(CFPurgeError.missingToken.localizedDescription)
            return
        }

        activeSite = site

        if reset {
            currentPage = 1
            records = []
            hasMorePages = false
        }

        status = .loading

        do {
            let result = try await CloudflareService.listDNSRecords(
                zoneId: site.zoneId,
                token: token,
                page: currentPage
            )

            if reset {
                records = result.records
            } else {
                records.append(contentsOf: result.records)
            }

            hasMorePages = result.hasMore
            status = .idle
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    func loadMore(for site: Site) async {
        guard hasMorePages, !status.isLoading else { return }
        currentPage += 1
        await loadRecords(for: site, reset: false)
    }

    func createRecord(
        for site: Site,
        type: String,
        name: String,
        content: String,
        ttl: Int,
        proxied: Bool
    ) async -> Bool {
        guard let token = KeychainService.loadToken() else {
            status = .error(CFPurgeError.missingToken.localizedDescription)
            return false
        }

        do {
            let request = try DNSRecordValidator.validateWithOptions(
                type: type,
                name: name,
                content: content,
                domain: site.domain,
                ttl: ttl,
                proxied: proxied
            )

            status = .loading
            let created = try await CloudflareService.createDNSRecord(
                zoneId: site.zoneId,
                token: token,
                record: request
            )

            withAnimation(.easeInOut(duration: 0.25)) {
                records.insert(created, at: 0)
            }

            status = .success("Enregistrement \(created.type) créé pour \(created.name).")
            return true
        } catch {
            status = .error(error.localizedDescription)
            return false
        }
    }

    func refresh(for site: Site) async {
        await loadRecords(for: site, reset: true)
    }
}
