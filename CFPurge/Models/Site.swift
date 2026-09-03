import Foundation

struct Site: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var zoneId: String
    var domain: String
    var sortOrder: Int
    var provider: CDNProvider
    /// Nom d'utilisateur hébergement Hostinger (requis pour la purge cache).
    var hostingUsername: String?

    init(
        id: UUID = UUID(),
        name: String,
        zoneId: String,
        domain: String,
        sortOrder: Int = 0,
        provider: CDNProvider = .cloudflare,
        hostingUsername: String? = nil
    ) {
        self.id = id
        self.name = name
        self.zoneId = zoneId
        self.domain = domain
        self.sortOrder = sortOrder
        self.provider = provider
        self.hostingUsername = hostingUsername
    }

    enum CodingKeys: String, CodingKey {
        case id, name, zoneId, domain, sortOrder, provider, hostingUsername
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        zoneId = try container.decodeIfPresent(String.self, forKey: .zoneId) ?? ""
        domain = try container.decode(String.self, forKey: .domain)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        provider = try container.decodeIfPresent(CDNProvider.self, forKey: .provider) ?? .cloudflare
        hostingUsername = try container.decodeIfPresent(String.self, forKey: .hostingUsername)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(zoneId, forKey: .zoneId)
        try container.encode(domain, forKey: .domain)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(provider, forKey: .provider)
        try container.encodeIfPresent(hostingUsername, forKey: .hostingUsername)
    }
}
