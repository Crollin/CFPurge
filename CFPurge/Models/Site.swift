import Foundation

struct Site: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var zoneId: String
    var domain: String
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, zoneId: String, domain: String, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.zoneId = zoneId
        self.domain = domain
        self.sortOrder = sortOrder
    }

    enum CodingKeys: String, CodingKey {
        case id, name, zoneId, domain, sortOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        zoneId = try container.decode(String.self, forKey: .zoneId)
        domain = try container.decode(String.self, forKey: .domain)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
    }
}
