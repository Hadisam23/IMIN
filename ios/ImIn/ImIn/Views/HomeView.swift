import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userManager: UserManager
    private let api = APIService.shared

    @State private var myGames: [Game] = []
    @State private var isLoading = false
    @State private var showCreateGame = false
    @State private var selectedGame: Game?

    private var upcomingGames: [Game] {
        myGames.filter { $0.status == .open || $0.status == .full }
    }

    private var heroGame: Game? {
        upcomingGames.first
    }

    private var otherGames: [Game] {
        Array(upcomingGames.dropFirst())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    heroSection
                    quickActionsSection
                    if !otherGames.isEmpty {
                        upcomingSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                await loadGames()
            }
            .task {
                await loadGames()
            }
            .sheet(isPresented: $showCreateGame) {
                CreateGameView(onGameCreated: { game in
                    myGames.insert(game, at: 0)
                })
            }
            .navigationDestination(item: $selectedGame) { game in
                GameDashboardView(gameId: game.id)
            }
        }
    }

    // MARK: - Header (compact identity)

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Small avatar
            ZStack {
                Circle()
                    .fill(Color.accentBlue)
                    .frame(width: 44, height: 44)

                Text(userManager.currentUser?.initials ?? "?")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Hey, \(userManager.currentUser?.name.components(separatedBy: " ").first ?? "Player")")
                    .font(.title3)
                    .fontWeight(.bold)

                // Inline sport icons
                if let sports = userManager.currentUser?.sports, !sports.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(sports) { sport in
                            Image(systemName: sport.iconName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Hero Card (most relevant game)

    private var heroSection: some View {
        Group {
            if isLoading && myGames.isEmpty {
                heroLoadingView
            } else if let game = heroGame {
                heroGameCard(game: game)
            } else {
                heroEmptyView
            }
        }
    }

    private var heroLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading your games...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }

    private func heroGameCard(game: Game) -> some View {
        Button {
            selectedGame = game
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Top row: sport + status
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: sportIconName(for: game.sport))
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))

                        Text(game.sport)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    StatusPill(status: game.status)
                }

                // Time + location
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text(game.formattedTime)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(game.location)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
                .foregroundColor(.white.opacity(0.85))

                // Player count bar
                VStack(spacing: 6) {
                    HStack {
                        Text("\(game.currentPlayers) / \(game.maxPlayers) players")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        if game.spotsRemaining > 0 {
                            Text("\(game.spotsRemaining) spots left")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 5)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white)
                                .frame(width: geo.size.width * min(CGFloat(game.currentPlayers) / CGFloat(max(game.maxPlayers, 1)), 1.0), height: 5)
                        }
                    }
                    .frame(height: 5)
                }

                // CTA
                HStack {
                    Spacer()
                    Text(game.spotsRemaining > 0 ? "Invite Players" : "View Game")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentBlue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(20)
                    Spacer()
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.accentBlue, Color.accentBlue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }

    private var heroEmptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 36))
                .foregroundColor(.accentBlue.opacity(0.5))

            VStack(spacing: 4) {
                Text("No upcoming games")
                    .font(.headline)

                Text("Create a game and share the link")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Button {
                showCreateGame = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Game")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentBlue)
                .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "plus.circle.fill",
                label: "Create Game",
                color: .accentBlue
            ) {
                showCreateGame = true
            }

            QuickActionButton(
                icon: "magnifyingglass",
                label: "Find Games",
                color: .successGreen
            ) {
                // Navigate to Discover tab — handled by parent TabView if needed
            }
        }
    }

    // MARK: - Upcoming Games List

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MORE GAMES")
                .fieldLabel()

            ForEach(otherGames) { game in
                Button {
                    selectedGame = game
                } label: {
                    GameCardView(game: game)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func loadGames() async {
        isLoading = true
        defer { isLoading = false }

        guard let phone = userManager.currentUser?.phone else {
            // Fallback to all games if no phone
            do {
                myGames = try await api.fetchGames()
            } catch {
                print("Failed to load games: \(error)")
            }
            return
        }

        do {
            myGames = try await api.fetchMyGames(phone: phone)
        } catch {
            print("Failed to load games: \(error)")
        }
    }

    private func sportIconName(for sport: String) -> String {
        switch sport.lowercased() {
        case "football", "soccer": return "figure.soccer"
        case "basketball": return "figure.basketball"
        case "tennis": return "figure.tennis"
        case "volleyball": return "volleyball.fill"
        case "padel": return "figure.racquetball"
        default: return "sportscourt.fill"
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.04),
                radius: 6,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Existing components kept for reuse

struct GameCardView: View {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(Color.accentBlue.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: sportIcon)
                        .font(.system(size: 20))
                        .foregroundColor(.accentBlue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(game.sport)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(game.formattedTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusPill(status: game.status)
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.accentBlue)
                Text(game.location)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)

            VStack(spacing: 8) {
                HStack {
                    Text("Players")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(game.currentPlayers)/\(game.maxPlayers)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(game.isFull ? .warningOrange : .accentBlue)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(game.isFull ? Color.warningOrange : Color.accentBlue)
                            .frame(width: geo.size.width * CGFloat(game.currentPlayers) / CGFloat(game.maxPlayers), height: 6)
                    }
                }
                .frame(height: 6)
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

struct StatusPill: View {
    let status: GameStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(status.displayText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.12))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .open: return .successGreen
        case .full: return .warningOrange
        case .locked: return .accentBlue
        case .cancelled: return .secondary
        }
    }
}

struct StatusBadge: View {
    let status: GameStatus

    var body: some View {
        StatusPill(status: status)
    }
}

// Make Game conform to Hashable for navigationDestination(item:)
extension Game: Hashable {
    static func == (lhs: Game, rhs: Game) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

#Preview {
    HomeView()
        .environmentObject(UserManager.shared)
}
