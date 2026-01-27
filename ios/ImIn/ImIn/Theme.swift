import SwiftUI
import UIKit

// MARK: - App Theme
struct AppTheme {
    // Primary accent color - professional blue
    static let accent = Color.accentBlue

    // Semantic colors
    static let success = Color.successGreen
    static let warning = Color.warningOrange
    static let error = Color.errorRed
}

// MARK: - Color Extension for Asset Colors with Fallbacks
extension Color {
    static let accentBlue = Color(light: Color(hex: "4B6BFB"), dark: Color(hex: "6B8AFF"))
    static let successGreen = Color(light: Color(hex: "22C55E"), dark: Color(hex: "4ADE80"))
    static let warningOrange = Color(light: Color(hex: "F59E0B"), dark: Color(hex: "FBBF24"))
    static let errorRed = Color(light: Color(hex: "EF4444"), dark: Color(hex: "F87171"))

    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.06),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

struct FieldLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func fieldLabel() -> some View {
        modifier(FieldLabelStyle())
    }
}

// MARK: - Sport Icons
enum SportIcon: String, CaseIterable {
    case football = "Football"
    case padel = "Padel"
    case tennis = "Tennis"
    case basketball = "Basketball"
    case volleyball = "Volleyball"
    case other = "Other"

    var systemImage: String {
        switch self {
        case .football: return "figure.soccer"
        case .padel: return "figure.racquetball"
        case .tennis: return "figure.tennis"
        case .basketball: return "figure.basketball"
        case .volleyball: return "volleyball.fill"
        case .other: return "sportscourt.fill"
        }
    }

    var emoji: String {
        switch self {
        case .football: return "⚽️"
        case .padel: return "🎾"
        case .tennis: return "🎾"
        case .basketball: return "🏀"
        case .volleyball: return "🏐"
        case .other: return "🏆"
        }
    }
}
