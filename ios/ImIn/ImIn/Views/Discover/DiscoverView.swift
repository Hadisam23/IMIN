import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var userManager: UserManager
    private let api = APIService.shared

    @State private var games: [Game] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var selectedCity = "All Cities"
    @State private var selectedSport = "All Sports"

    private let defaultCities = ["London", "Madrid", "New York", "Paris", "Berlin", "Barcelona", "Amsterdam", "Dubai"]
    private let sports = ["All Sports", "Football", "Padel", "Tennis", "Basketball"]

    private var cities: [String] {
        var list = ["All Cities"]
        // Add user's location as first option if available
        if let userLocation = userManager.currentUser?.location, !userLocation.isEmpty {
            list.append(userLocation)
        }
        // Add other cities, excluding user's location to avoid duplicates
        for city in defaultCities {
            if city != userManager.currentUser?.location {
                list.append(city)
            }
        }
        return list
    }

    private var filteredGames: [Game] {
        games.filter { game in
            let sportMatch = selectedSport == "All Sports" || game.sport == selectedSport
            let cityMatch = selectedCity == "All Cities" || game.location.localizedCaseInsensitiveContains(selectedCity)
            return sportMatch && cityMatch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                VStack(spacing: 12) {
                    // Cities filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(cities, id: \.self) { city in
                                FilterPill(
                                    title: city,
                                    isSelected: selectedCity == city,
                                    action: { selectedCity = city }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Sports filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sports, id: \.self) { sport in
                                FilterPill(
                                    title: sport,
                                    isSelected: selectedSport == sport,
                                    action: { selectedSport = sport }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))

                // Games list
                if isLoading && games.isEmpty {
                    loadingView
                } else if filteredGames.isEmpty {
                    emptyStateView
                } else {
                    gamesList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Discover")
            .refreshable {
                await loadGames()
            }
            .task {
                await loadGames()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Finding games...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.accentBlue.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundColor(.accentBlue)
            }

            VStack(spacing: 8) {
                Text("No Games Found")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Try adjusting your filters\nor check back later")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Games List

    private var gamesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredGames) { game in
                    NavigationLink(destination: GameDashboardView(gameId: game.id)) {
                        DiscoverGameCard(game: game)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private func loadGames() async {
        isLoading = true
        defer { isLoading = false }

        do {
            games = try await api.fetchGames()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentBlue : Color(.secondarySystemBackground))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Discover Game Card

struct DiscoverGameCard: View {
    let game: Game
    @Environment(\.colorScheme) private var colorScheme

    private var sportIcon: String {
        switch game.sport.lowercased() {
        case "football", "soccer": return "figure.soccer"
        case "basketball": return "figure.basketball"
        case "tennis": return "figure.tennis"
        case "volleyball": return "volleyball.fill"
        case "padel": return "figure.racquetball"
        default: return "sportscourt.fill"
        }
    }

    private var gameDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: game.time) { return date }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: game.time) { return date }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return df.date(from: game.time)
    }

    private var formattedDate: String {
        guard let date = gameDate else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private var formattedTime: String {
        guard let date = gameDate else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentBlue.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: sportIcon)
                        .font(.system(size: 18))
                        .foregroundColor(.accentBlue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.sport)
                        .font(.headline)

                    Text(game.location.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }

                Spacer()
            }

            // Date / Time / Level row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DATE")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("TIME")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedTime)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("LEVEL")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(game.level)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Player avatars and spots
            HStack {
                // Avatar stack
                HStack(spacing: -8) {
                    ForEach(0..<min(game.currentPlayers, 4), id: \.self) { index in
                        Circle()
                            .fill(Color.accentBlue.opacity(0.2))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.accentBlue)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                    }

                    if game.currentPlayers > 4 {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("+\(game.currentPlayers - 4)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                    }
                }

                Spacer()

                // Spots remaining
                if game.isFull {
                    Text("FULL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.warningOrange)
                } else {
                    HStack(spacing: 4) {
                        Text("\(game.spotsRemaining) Spots Available")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.successGreen)

                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.successGreen)
                    }
                }
            }
        }
        .padding(16)
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

#Preview {
    DiscoverView()
        .environmentObject(UserManager.shared)
}
