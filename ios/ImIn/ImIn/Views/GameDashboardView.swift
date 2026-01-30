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
    @State private var showTeamSplit = false
    @State private var editingSkillPlayerId: String?
    @State private var showEditSheet = false

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
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
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
        .sheet(isPresented: $showEditSheet, onDismiss: {
            Task { await loadGame() }
        }) {
            if let game = game {
                EditGameSheet(game: game) { updatedGame in
                    self.game = updatedGame
                }
            }
        }
        .sheet(isPresented: $showTeamSplit) {
            if let game = game, let players = game.players {
                TeamSplitView(
                    gameId: gameId,
                    initialPlayersPerTeam: extractPlayersPerTeam(from: game.sport, maxPlayers: game.maxPlayers),
                    players: Binding(
                        get: { players },
                        set: { _ in }
                    )
                )
            }
        }
    }

    private func extractPlayersPerTeam(from sport: String, maxPlayers: Int) -> Int {
        // Extract number from sport format like "5v5", "11v11", etc.
        let pattern = #"(\d+)v\d+"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: sport, options: [], range: NSRange(sport.startIndex..., in: sport)),
           let range = Range(match.range(at: 1), in: sport),
           let number = Int(sport[range]) {
            return number
        }

        // Try to find a sensible team size based on maxPlayers
        // Common formats: 5v5=10, 6v6=12, 7v7=14, 11v11=22, 3v3=6, 4v4=8
        let commonTeamSizes = [11, 7, 6, 5, 4, 3]
        for size in commonTeamSizes {
            if maxPlayers % size == 0 && maxPlayers / size >= 2 {
                return size
            }
        }

        // Default: assume 2 teams
        return max(2, maxPlayers / 2)
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
                HStack {
                    Text(game.sport)
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    if game.status != .cancelled {
                        Button {
                            showEditSheet = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentBlue)
                        }
                    }
                }

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
                        PlayerRowWithSkill(
                            player: player,
                            index: index + 1,
                            isEditing: editingSkillPlayerId == player.id,
                            onSkillTap: {
                                if editingSkillPlayerId == player.id {
                                    editingSkillPlayerId = nil
                                } else {
                                    editingSkillPlayerId = player.id
                                }
                            },
                            onSkillChange: { newSkill in
                                updatePlayerSkill(playerId: player.id, skill: newSkill)
                                editingSkillPlayerId = nil
                            }
                        )

                        if index < players.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }

                // Split Teams button
                if players.count >= 4 {
                    Button {
                        showTeamSplit = true
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Split Teams")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.successGreen)
                        .cornerRadius(10)
                    }
                    .padding(.top, 8)
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

    private func updatePlayerSkill(playerId: String, skill: Int) {
        Task {
            do {
                let updatedGame = try await api.updatePlayerSkillLevel(gameId: gameId, playerId: playerId, skillLevel: skill)
                self.game = updatedGame
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func actionsCard(_ game: Game) -> some View {
        VStack(spacing: 12) {
            // Visibility toggle
            visibilityToggle(game)

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

    private func visibilityToggle(_ game: Game) -> some View {
        let isPublic = game.isPublic ?? false

        return Button {
            toggleVisibility(!isPublic)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isPublic ? "globe" : "lock.fill")
                    .font(.title3)
                    .foregroundColor(isPublic ? .accentBlue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isPublic ? "Public Game" : "Private Game")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(isPublic ? "Visible in Discover - tap to make private" : "Only via link - tap to make public")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPublic ? Color.accentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggleVisibility(_ isPublic: Bool) {
        Task {
            do {
                let updatedGame = try await api.updateGameVisibility(id: gameId, isPublic: isPublic)
                self.game = updatedGame
            } catch {
                errorMessage = error.localizedDescription
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

struct PlayerRowWithSkill: View {
    let player: Player
    let index: Int
    let isEditing: Bool
    let onSkillTap: () -> Void
    let onSkillChange: (Int) -> Void

    private let colors: [Color] = [.accentBlue, .successGreen, .warningOrange, .purple, .pink, .teal]

    private var avatarColor: Color {
        colors[(index - 1) % colors.count]
    }

    private func skillColor(_ level: Int) -> Color {
        switch level {
        case 1: return .gray
        case 2: return .blue
        case 3: return .green
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 0) {
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

                // Skill level badge (tappable)
                Button(action: onSkillTap) {
                    if let skill = player.skillLevel {
                        Text("\(skill)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(skillColor(skill))
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "star")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)

            // Skill picker (when editing)
            if isEditing {
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            onSkillChange(level)
                        } label: {
                            Text("\(level)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(player.skillLevel == level ? .white : skillColor(level))
                                .frame(width: 40, height: 36)
                                .background(player.skillLevel == level ? skillColor(level) : skillColor(level).opacity(0.15))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
                .padding(.leading, 32)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
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

// MARK: - Edit Game Sheet
struct EditGameSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let api = APIService.shared

    let game: Game
    let onSave: (Game) -> Void

    @State private var location: String
    @State private var gameDate: Date
    @State private var gameTime: Date
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(game: Game, onSave: @escaping (Game) -> Void) {
        self.game = game
        self.onSave = onSave

        _location = State(initialValue: game.location)

        // Parse existing time
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var parsed = formatter.date(from: game.time)
        if parsed == nil {
            formatter.formatOptions = [.withInternetDateTime]
            parsed = formatter.date(from: game.time)
        }
        let date = parsed ?? Date()
        _gameDate = State(initialValue: date)
        _gameTime = State(initialValue: date)
    }

    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: gameDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: gameTime)
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        return calendar.date(from: combined) ?? Date()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    TextField("Where are we playing?", text: $location)
                }

                Section("Date & Time") {
                    DatePicker("Date", selection: $gameDate, displayedComponents: .date)
                        .accentColor(.accentBlue)
                    DatePicker("Time", selection: $gameTime, displayedComponents: .hourAndMinute)
                        .accentColor(.accentBlue)
                }
            }
            .navigationTitle("Edit Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.accentBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(location.isEmpty || isSaving)
                    .foregroundColor(.accentBlue)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() {
        isSaving = true
        let newTime = combinedDateTime
        let newLocation = location.trimmingCharacters(in: .whitespaces)
        print("[EditGame] Saving time: \(newTime), location: \(newLocation)")
        Task {
            do {
                let updatedGame = try await api.updateGameDetails(
                    id: game.id,
                    time: newTime,
                    location: newLocation
                )
                print("[EditGame] Save success, new time string: \(updatedGame.time)")
                onSave(updatedGame)
                dismiss()
            } catch {
                print("[EditGame] Save failed: \(error)")
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

#Preview {
    NavigationStack {
        GameDashboardView(gameId: "test-123")
    }
}
