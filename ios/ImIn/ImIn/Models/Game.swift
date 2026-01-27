import Foundation

struct Game: Codable, Identifiable {
    let id: String
    let sport: String
    let time: String
    let location: String
    let level: String
    let maxPlayers: Int
    var status: GameStatus
    var joinUrl: String?
    var players: [Player]?
    var playerCount: Int?
    var isPublic: Bool?
    var isCreator: Bool?

    var currentPlayers: Int {
        playerCount ?? players?.count ?? 0
    }

    var spotsRemaining: Int {
        maxPlayers - currentPlayers
    }

    var isFull: Bool {
        currentPlayers >= maxPlayers
    }

    var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Try multiple formats
        var date: Date?
        date = formatter.date(from: time)

        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: time)
        }

        if date == nil {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            date = df.date(from: time)
        }

        guard let parsedDate = date else { return time }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        return displayFormatter.string(from: parsedDate)
    }
}

enum GameStatus: String, Codable {
    case open
    case full
    case locked
    case cancelled

    var displayText: String {
        switch self {
        case .open: return "Open"
        case .full: return "Full"
        case .locked: return "Locked"
        case .cancelled: return "Cancelled"
        }
    }

    var color: String {
        switch self {
        case .open: return "green"
        case .full: return "red"
        case .locked: return "orange"
        case .cancelled: return "gray"
        }
    }
}

struct CreateGameRequest: Codable {
    let sport: String
    let time: String
    let location: String
    let level: String
    let maxPlayers: Int
    let isPublic: Bool
    let creatorPhone: String?
}

struct UpdateGameRequest: Codable {
    let status: String
}
