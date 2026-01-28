import Foundation

struct Player: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let phone: String?
    let timestamp: String?
    var skillLevel: Int?

    var initials: String {
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }
        return String(initials).uppercased()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }
}

struct JoinRequest: Codable {
    let name: String
    let phone: String?
}

struct JoinResponse: Codable {
    let success: Bool
    let message: String
    let game: Game?
}
