import Foundation

struct Player: Codable, Identifiable {
    let id: String
    let name: String
    let phone: String?
    let timestamp: String?

    var initials: String {
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }
        return String(initials).uppercased()
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
