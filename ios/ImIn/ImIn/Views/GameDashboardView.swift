import SwiftUI
import Combine

struct GameDashboardView: View {
    let gameId: String

    private let api = APIService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var game: Game?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showShareSheet = false
    @State private var showLockConfirm = false
    @State private var showCancelConfirm = false

    private let refreshTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private var sportIcon: String {
        guard let sport = game?.sport.lowercased() else { return "sportscourt.fill" }
        switch sport {
        case "football", "soccer": return "figure.soccer"
        case "basketball": return "figure.basketball"
        case "tennis": return "figure.tennis"
        case "volleyball": return "volleyball.fill"
        case "padel": return "figure.racquetball"
        default: return "sportscourt.fill"
        }
    }

    var body: some View {
        Group {
            if isLoading && game == nil {
                loadingView
            } else if let game = game {
                gameContent(game)
            } else {
                errorView
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadGame()
        }
        .onReceive(refreshTimer) { _ in
            Task { await loadGame() }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog("Lock Game?", isPresented: $showLockConfirm) {
            Button("Lock Game", role: .destructive) {
                updateStatus(.locked)
            }
        } message: {
            Text("Players won't be able to join after locking.")
        }
        .confirmationDialog("Cancel Game?", isPresented: $showCancelConfirm) {
            Button("Cancel Game", role: .destructive) {
                updateStatus(.cancelled)
            }
        } message: {
            Text("This will mark the game as cancelled.")
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = game?.joinUrl {
                ShareSheet(items: [URL(string: url)!])
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading game...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.warningOrange)
            Text("Game not found")
                .font(.headline)
        }
    }

    private func gameContent(_ game: Game) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Header
                heroHeader(game)

                // Progress Card
                progressCard(game)

                // Players List
                playersCard(game)

                // Actions
                actionsCard(game)

                // Auto-refresh indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.successGreen)
                        .frame(width: 6, height: 6)
                    Text("Live updating")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func heroHeader(_ game: Game) -> some View {
        VStack(spacing: 16) {
            // Sport icon and status
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.accentBlue.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: sportIcon)
                        .font(.system(size: 26))
                        .foregroundColor(.accentBlue)
                }

                Spacer()

                StatusPill(status: game.status)
            }

            // Game info
            VStack(alignment: .leading, spacing: 12) {
                Text(game.sport)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 16) {
                    Label(game.formattedTime, systemImage: "calendar")
                    Spacer()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    Label(game.location, systemImage: "mappin.circle.fill")
                        .foregroundColor(.secondary)
                    Spacer()
                    Label(game.level, systemImage: "chart.bar.fill")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(
            color: colorScheme == .dark ? .clear : .black.opacity(0.05),
            radius: 10,
            x: 0,
            y: 2
        )
    }

    private func progressCard(_ game: Game) -> some View {
        VStack(spacing: 16) {
            // Big numbers
            HStack(alignment: .firstTextBaseline) {
                Text("\(game.currentPlayers)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(game.isFull ? .warningOrange : .accentBlue)

                Text("/ \(game.maxPlayers)")
                    .font(.title)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(game.isFull ? "FULL" : "\(game.spotsRemaining) spots")
                        .font(.headline)
                        .foregroundColor(game.isFull ? .warningOrange : .accentBlue)
                    Text("remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(game.isFull ? 0 : 1)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: game.isFull ? [.warningOrange, .errorRed] : [.accentBlue, .accentBlue.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(game.currentPlayers) / CGFloat(game.maxPlayers)), height: 10)
                }
            }
            .frame(height: 10)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(
            color: colorScheme == .dark ? .clear : .black.opacity(0.05),
            radius: 10,
            x: 0,
            y: 2
        )
    }

    private func playersCard(_ game: Game) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Players")
                    .font(.headline)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if let players = game.players, !players.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        PlayerRow(player: player, index: index + 1)

                        if index < players.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.3")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No players yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Share the link to get players!")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(
            color: colorScheme == .dark ? .clear : .black.opacity(0.05),
            radius: 10,
            x: 0,
            y: 2
        )
    }

    private func actionsCard(_ game: Game) -> some View {
        VStack(spacing: 12) {
            // Share button
            Button {
                showShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Link")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentBlue)
                .cornerRadius(14)
            }

            // Lock & Cancel buttons
            HStack(spacing: 12) {
                Button {
                    showLockConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("Lock")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentBlue.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(game.status == .locked || game.status == .cancelled)
                .opacity(game.status == .locked || game.status == .cancelled ? 0.5 : 1)

                Button {
                    showCancelConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.errorRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.errorRed.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(game.status == .cancelled)
                .opacity(game.status == .cancelled ? 0.5 : 1)
            }
        }
    }

    private func loadGame() async {
        do {
            let fetchedGame = try await api.fetchGame(id: gameId)
            self.game = fetchedGame
            self.isLoading = false
        } catch {
            if game == nil {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func updateStatus(_ status: GameStatus) {
        Task {
            do {
                let updatedGame = try await api.updateGame(id: gameId, status: status)
                self.game = updatedGame
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct PlayerRow: View {
    let player: Player
    let index: Int

    private let colors: [Color] = [.accentBlue, .successGreen, .warningOrange, .purple, .pink, .teal]

    private var avatarColor: Color {
        colors[(index - 1) % colors.count]
    }

    var body: some View {
        HStack(spacing: 12) {
            // Index
            Text("\(index)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)

            // Avatar
            Circle()
                .fill(avatarColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(player.initials)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(avatarColor)
                )

            // Name & phone
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let phone = player.phone, !phone.isEmpty {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    NavigationStack {
        GameDashboardView(gameId: "test-123")
    }
}
