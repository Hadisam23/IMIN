import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    var name: String
    var location: String
    var sports: [UserSport]
    var freeTimeSlots: [FreeTimeSlot]

    init(id: String = UUID().uuidString, name: String, location: String = "", sports: [UserSport] = [], freeTimeSlots: [FreeTimeSlot] = []) {
        self.id = id
        self.name = name
        self.location = location
        self.sports = sports
        self.freeTimeSlots = freeTimeSlots
    }

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - User Sport
struct UserSport: Codable, Identifiable, Hashable {
    let id: String
    let sport: String
    var level: SkillLevel

    init(id: String = UUID().uuidString, sport: String, level: SkillLevel = .intermediate) {
        self.id = id
        self.sport = sport
        self.level = level
    }

    var iconName: String {
        switch sport.lowercased() {
        case "football": return "figure.soccer"
        case "padel": return "figure.racquetball"
        case "tennis": return "figure.tennis"
        case "basketball": return "figure.basketball"
        case "volleyball": return "volleyball.fill"
        default: return "sportscourt.fill"
        }
    }
}

// MARK: - Skill Level
enum SkillLevel: String, Codable, CaseIterable {
    case none = "None"
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case pro = "Pro"

    var shortName: String {
        switch self {
        case .none: return "—"
        case .beginner: return "BEG"
        case .intermediate: return "INT"
        case .advanced: return "ADV"
        case .pro: return "PRO"
        }
    }

    var color: String {
        switch self {
        case .none: return "gray"
        case .beginner: return "green"
        case .intermediate: return "blue"
        case .advanced: return "orange"
        case .pro: return "purple"
        }
    }
}

// MARK: - Free Time Slot
struct FreeTimeSlot: Codable, Identifiable, Hashable {
    let id: String
    let day: Weekday
    let timeOfDay: TimeOfDay
    var isActive: Bool

    init(id: String = UUID().uuidString, day: Weekday, timeOfDay: TimeOfDay, isActive: Bool = true) {
        self.id = id
        self.day = day
        self.timeOfDay = timeOfDay
        self.isActive = isActive
    }

    var displayText: String {
        "\(day.rawValue) \(timeOfDay.rawValue)"
    }
}

// MARK: - Weekday
enum Weekday: String, Codable, CaseIterable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"

    var shortName: String {
        String(rawValue.prefix(3))
    }
}

// MARK: - Time of Day
enum TimeOfDay: String, Codable, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        }
    }
}

// MARK: - Available Sports
enum AvailableSport: String, CaseIterable {
    case football = "Football"
    case padel = "Padel"
    case tennis = "Tennis"
    case basketball = "Basketball"

    var iconName: String {
        switch self {
        case .football: return "figure.soccer"
        case .padel: return "figure.racquetball"
        case .tennis: return "figure.tennis"
        case .basketball: return "figure.basketball"
        }
    }
}
