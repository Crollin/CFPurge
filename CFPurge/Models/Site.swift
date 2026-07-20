import Foundation

struct Site: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var zoneId: String
    var domain: String

    init(id: UUID = UUID(), name: String, zoneId: String, domain: String) {
        self.id = id
        self.name = name
        self.zoneId = zoneId
        self.domain = domain
    }
}
