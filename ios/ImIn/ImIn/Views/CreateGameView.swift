import SwiftUI

// MARK: - CreateGameView (Modal with Navigation)
struct CreateGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var userManager: UserManager
    private let api = APIService.shared

    let onGameCreated: (Game) -> Void

    @State private var sport = "Basketball"
    @State private var selectedFormat = "5v5"
    @State private var gameDate = Date()
    @State private var gameTime = Date().addingTimeInterval(3600)
    @State private var location = ""
    @State private var level = "Intermediate"
    @State private var customMaxPlayers = 10

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var createdGame: Game?
    @State private var showShareSheet = false
    @State private var imPlaying = true

    private let sports = ["Football", "Padel", "Tennis", "Basketball"]
    private let levels = ["Beginner", "Intermediate", "Advanced", "Pro"]

    private let sportFormats: [String: [(format: String, players: Int)]] = [
        "Football": [("5v5", 10), ("6v6", 12), ("7v7", 14), ("11v11", 22)],
        "Basketball": [("3v3", 6), ("4v4", 8), ("5v5", 10)],
        "Tennis": [("Singles", 2), ("Doubles", 4)],
        "Padel": [("Doubles", 4)],
    ]

    private var availableFormats: [(format: String, players: Int)] {
        sportFormats[sport] ?? [("5v5", 10)]
    }

    private var maxPlayers: Int {
        availableFormats.first { $0.format == selectedFormat }?.players ?? customMaxPlayers
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

    private var canCreate: Bool {
        !location.isEmpty
    }

    private var dateDisplayText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(gameDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(gameDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: gameDate)
        }
    }

    private var timeDisplayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: gameTime)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let game = createdGame {
                    successView(game: game)
                } else {
                    formView
                }
            }
            .navigationTitle(createdGame == nil ? "New Game" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.accentBlue)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showShareSheet) {
                if let game = createdGame, let url = game.joinUrl {
                    ShareSheet(items: [URL(string: url)!])
                }
            }
        }
    }

    private var formView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Sport Selection
                sportSelectionSection

                // Location
                locationSection

                // Date & Time
                dateTimeSection

                // Format & Max Players
                formatSection

                // Skill Level
                skillLevelSection

                // I'm Playing Toggle
                organizerSection

                // Create Button
                createButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Sport Selection
    private var sportSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECT SPORT")
                .fieldLabel()

            HStack(spacing: 12) {
                ForEach(sports, id: \.self) { sportName in
                    SportButton(
                        sport: sportName,
                        isSelected: sport == sportName
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            sport = sportName
                            selectedFormat = availableFormats.first?.format ?? "5v5"
                            customMaxPlayers = availableFormats.first?.players ?? 10
                        }
                    }
                }
            }
        }
    }

    // MARK: - Location
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LOCATION")
                .fieldLabel()

            TextField("Where are we playing?", text: $location)
                .font(.body)
                .padding(.vertical, 12)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.systemGray4)),
                    alignment: .bottom
                )
        }
    }

    // MARK: - Date & Time
    private var dateTimeSection: some View {
        HStack(spacing: 16) {
            // Date
            VStack(alignment: .leading, spacing: 8) {
                Text("DATE")
                    .fieldLabel()

                DatePicker("", selection: $gameDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .accentColor(.accentBlue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Time
            VStack(alignment: .leading, spacing: 8) {
                Text("TIME")
                    .fieldLabel()

                DatePicker("", selection: $gameTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .accentColor(.accentBlue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Format & Max Players
    private var formatSection: some View {
        HStack(spacing: 16) {
            // Format
            VStack(alignment: .leading, spacing: 8) {
                Text("FORMAT")
                    .fieldLabel()

                Menu {
                    ForEach(availableFormats, id: \.format) { item in
                        Button {
                            selectedFormat = item.format
                            customMaxPlayers = item.players
                        } label: {
                            Text(item.format)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedFormat)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Max Players
            VStack(alignment: .leading, spacing: 8) {
                Text("MAX PLAYERS")
                    .fieldLabel()

                TextField("10", value: $customMaxPlayers, format: .number)
                    .font(.title3)
                    .fontWeight(.medium)
                    .keyboardType(.numberPad)
                    .padding(.vertical, 8)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Skill Level
    private var skillLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SKILL LEVEL")
                .fieldLabel()

            SegmentedLevelPicker(levels: levels, selectedLevel: $level)
        }
    }

    // MARK: - Organizer Section
    private var organizerSection: some View {
        Toggle(isOn: $imPlaying) {
            HStack(spacing: 12) {
                Image(systemName: "person.fill.checkmark")
                    .font(.title3)
                    .foregroundColor(imPlaying ? .accentBlue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("I'm In")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Count me as a player")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .tint(.accentBlue)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Create Button
    private var createButton: some View {
        VStack(spacing: 8) {
            Button {
                createGame()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "link.badge.plus")
                        Text("Create & Get Link")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canCreate ? Color.accentBlue : Color.gray.opacity(0.4))
                .cornerRadius(14)
            }
            .disabled(!canCreate || isLoading)
        }
        .padding(.top, 8)
    }

    // MARK: - Success View
    private func successView(game: Game) -> some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.successGreen.opacity(0.1))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(Color.successGreen.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.successGreen)
            }
            .padding(.bottom, 24)

            Text("Game Created!")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 6) {
                Text("\(SportIcon(rawValue: game.sport)?.emoji ?? "🏆") \(game.sport)")
                    .font(.headline)
                Text(game.formattedTime)
                    .foregroundColor(.secondary)
                Text(game.location)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)

            if let joinUrl = game.joinUrl {
                VStack(spacing: 8) {
                    Text("Share this link")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(joinUrl)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.accentBlue)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentBlue.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.top, 24)
                .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 12) {
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

                Button {
                    onGameCreated(game)
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.accentBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentBlue.opacity(0.12))
                        .cornerRadius(14)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    private func createGame() {
        isLoading = true
        Task {
            do {
                var game = try await api.createGame(
                    sport: sport,
                    time: combinedDateTime,
                    location: location,
                    level: level,
                    maxPlayers: maxPlayers
                )

                if imPlaying, let userName = userManager.currentUser?.name {
                    game = try await api.joinGame(id: game.id, name: userName)
                }

                createdGame = game
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Sport Button
struct SportButton: View {
    let sport: String
    let isSelected: Bool
    let action: () -> Void

    private var iconName: String {
        switch sport.lowercased() {
        case "football": return "figure.soccer"
        case "padel": return "figure.racquetball"
        case "tennis": return "figure.tennis"
        case "basketball": return "figure.basketball"
        case "volleyball": return "volleyball.fill"
        default: return "sportscourt.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentBlue : Color(.secondarySystemBackground))
                        .frame(width: 56, height: 56)

                    Image(systemName: iconName)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : .primary)
                }

                Text(sport.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(isSelected ? .accentBlue : .secondary)
                    .tracking(0.3)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Segmented Level Picker
struct SegmentedLevelPicker: View {
    let levels: [String]
    @Binding var selectedLevel: String

    private func shortName(for level: String) -> String {
        switch level.lowercased() {
        case "beginner": return "Beg"
        case "intermediate": return "Int"
        case "advanced": return "Adv"
        case "pro": return "Pro"
        default: return String(level.prefix(3))
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(levels, id: \.self) { lvl in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedLevel = lvl
                    }
                } label: {
                    Text(shortName(for: lvl))
                        .font(.subheadline)
                        .fontWeight(selectedLevel == lvl ? .semibold : .regular)
                        .foregroundColor(selectedLevel == lvl ? .white : .secondary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedLevel == lvl ?
                            Color.accentBlue : Color.clear
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - CreateGameFormView (For Tab Context)
struct CreateGameFormView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var userManager: UserManager
    private let api = APIService.shared

    let onGameCreated: (Game) -> Void

    @State private var sport = "Basketball"
    @State private var selectedFormat = "5v5"
    @State private var gameDate = Date()
    @State private var gameTime = Date().addingTimeInterval(3600)
    @State private var location = ""
    @State private var level = "Intermediate"
    @State private var customMaxPlayers = 10

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var createdGame: Game?
    @State private var showShareSheet = false
    @State private var imPlaying = true

    private let sports = ["Football", "Padel", "Tennis", "Basketball"]
    private let levels = ["Beginner", "Intermediate", "Advanced", "Pro"]

    private let sportFormats: [String: [(format: String, players: Int)]] = [
        "Football": [("5v5", 10), ("6v6", 12), ("7v7", 14), ("11v11", 22)],
        "Basketball": [("3v3", 6), ("4v4", 8), ("5v5", 10)],
        "Tennis": [("Singles", 2), ("Doubles", 4)],
        "Padel": [("Doubles", 4)],
    ]

    private var availableFormats: [(format: String, players: Int)] {
        sportFormats[sport] ?? [("5v5", 10)]
    }

    private var maxPlayers: Int {
        availableFormats.first { $0.format == selectedFormat }?.players ?? customMaxPlayers
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

    private var canCreate: Bool {
        !location.isEmpty
    }

    var body: some View {
        Group {
            if let game = createdGame {
                successView(game: game)
            } else {
                formView
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showShareSheet) {
            if let game = createdGame, let url = game.joinUrl {
                ShareSheet(items: [URL(string: url)!])
            }
        }
    }

    private var formView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Sport Selection
                sportSelectionSection

                // Location
                locationSection

                // Date & Time
                dateTimeSection

                // Format & Max Players
                formatSection

                // Skill Level
                skillLevelSection

                // I'm Playing Toggle
                organizerSection

                // Create Button
                createButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Sport Selection
    private var sportSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECT SPORT")
                .fieldLabel()

            HStack(spacing: 12) {
                ForEach(sports, id: \.self) { sportName in
                    SportButton(
                        sport: sportName,
                        isSelected: sport == sportName
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            sport = sportName
                            selectedFormat = availableFormats.first?.format ?? "5v5"
                            customMaxPlayers = availableFormats.first?.players ?? 10
                        }
                    }
                }
            }
        }
    }

    // MARK: - Location
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LOCATION")
                .fieldLabel()

            TextField("Where are we playing?", text: $location)
                .font(.body)
                .padding(.vertical, 12)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.systemGray4)),
                    alignment: .bottom
                )
        }
    }

    // MARK: - Date & Time
    private var dateTimeSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("DATE")
                    .fieldLabel()

                DatePicker("", selection: $gameDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .accentColor(.accentBlue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("TIME")
                    .fieldLabel()

                DatePicker("", selection: $gameTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .accentColor(.accentBlue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Format & Max Players
    private var formatSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("FORMAT")
                    .fieldLabel()

                Menu {
                    ForEach(availableFormats, id: \.format) { item in
                        Button {
                            selectedFormat = item.format
                            customMaxPlayers = item.players
                        } label: {
                            Text(item.format)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedFormat)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("MAX PLAYERS")
                    .fieldLabel()

                TextField("10", value: $customMaxPlayers, format: .number)
                    .font(.title3)
                    .fontWeight(.medium)
                    .keyboardType(.numberPad)
                    .padding(.vertical, 8)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Skill Level
    private var skillLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SKILL LEVEL")
                .fieldLabel()

            SegmentedLevelPicker(levels: levels, selectedLevel: $level)
        }
    }

    // MARK: - Organizer Section
    private var organizerSection: some View {
        Toggle(isOn: $imPlaying) {
            HStack(spacing: 12) {
                Image(systemName: "person.fill.checkmark")
                    .font(.title3)
                    .foregroundColor(imPlaying ? .accentBlue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("I'm In")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Count me as a player")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .tint(.accentBlue)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Create Button
    private var createButton: some View {
        VStack(spacing: 8) {
            Button {
                createGame()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "link.badge.plus")
                        Text("Create & Get Link")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canCreate ? Color.accentBlue : Color.gray.opacity(0.4))
                .cornerRadius(14)
            }
            .disabled(!canCreate || isLoading)
        }
        .padding(.top, 8)
    }

    // MARK: - Success View
    private func successView(game: Game) -> some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.successGreen.opacity(0.1))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(Color.successGreen.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.successGreen)
            }
            .padding(.bottom, 24)

            Text("Game Created!")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 6) {
                Text("\(SportIcon(rawValue: game.sport)?.emoji ?? "🏆") \(game.sport)")
                    .font(.headline)
                Text(game.formattedTime)
                    .foregroundColor(.secondary)
                Text(game.location)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)

            if let joinUrl = game.joinUrl {
                VStack(spacing: 8) {
                    Text("Share this link")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(joinUrl)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.accentBlue)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentBlue.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.top, 24)
                .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 12) {
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

                Button {
                    // Reset form for new game
                    createdGame = nil
                    location = ""
                    onGameCreated(game)
                } label: {
                    Text("Create Another")
                        .font(.headline)
                        .foregroundColor(.accentBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentBlue.opacity(0.12))
                        .cornerRadius(14)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    private func createGame() {
        isLoading = true
        Task {
            do {
                var game = try await api.createGame(
                    sport: sport,
                    time: combinedDateTime,
                    location: location,
                    level: level,
                    maxPlayers: maxPlayers
                )

                if imPlaying, let userName = userManager.currentUser?.name {
                    game = try await api.joinGame(id: game.id, name: userName)
                }

                createdGame = game
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    CreateGameView(onGameCreated: { _ in })
}

#Preview("Tab Form") {
    NavigationStack {
        CreateGameFormView(onGameCreated: { _ in })
            .environmentObject(UserManager.shared)
    }
}
