import SwiftUI

struct HomeView: View {
    private let api = APIService.shared
    @State private var games: [Game] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateGame = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                Group {
                    if isLoading && games.isEmpty {
                        loadingView
                    } else if games.isEmpty {
                        emptyStateView
                    } else {
                        gameListView
                    }
                }
            }
            .navigationTitle("My Games")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateGame = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentBlue)
                    }
                }
            }
            .sheet(isPresented: $showCreateGame) {
                CreateGameView(onGameCreated: { game in
                    games.insert(game, at: 0)
                })
            }
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

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading games...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.accentBlue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.accentBlue)
            }

            VStack(spacing: 8) {
                Text("No Games Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create your first game and\nshare the link with players")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showCreateGame = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Game")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.accentBlue)
                .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .padding(40)
    }

    private var gameListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(games) { game in
                    NavigationLink(destination: GameDashboardView(gameId: game.id)) {
                        GameCardView(game: game)
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
            // Header
            HStack(alignment: .center) {
                // Sport icon
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

            // Location
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.accentBlue)
                Text(game.location)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)

            // Progress
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

// Keep StatusBadge for backward compatibility
struct StatusBadge: View {
    let status: GameStatus

    var body: some View {
        StatusPill(status: status)
    }
}

#Preview {
    HomeView()
}
