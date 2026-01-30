import SwiftUI

// MARK: - Wizard Step
enum WizardStep: Int, CaseIterable {
    case sport = 0, where_, when, settings

    var title: String {
        switch self {
        case .sport: return "Sport"
        case .where_: return "Where"
        case .when: return "When"
        case .settings: return "Settings"
        }
    }
}

// MARK: - Step Indicator
struct StepIndicator: View {
    let currentStep: WizardStep
    let onTap: (WizardStep) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(WizardStep.allCases, id: \.rawValue) { step in
                Button {
                    onTap(step)
                } label: {
                    VStack(spacing: 6) {
                        Text(step.title)
                            .font(.subheadline)
                            .fontWeight(step == currentStep ? .bold : .regular)
                            .foregroundColor(step.rawValue <= currentStep.rawValue ? .primary : Color(.systemGray3))

                        Rectangle()
                            .fill(step == currentStep ? Color.accentBlue : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(step.rawValue > currentStep.rawValue)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - Game Creation Wizard (shared logic)
struct GameCreationWizard: View {
    @EnvironmentObject var userManager: UserManager
    private let api = APIService.shared

    let onGameCreated: (Game) -> Void
    let onDismiss: (() -> Void)?

    @State private var currentStep: WizardStep = .sport
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
    @State private var isPublic = false

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

    private var canAdvance: Bool {
        switch currentStep {
        case .sport: return true
        case .where_: return !location.isEmpty
        case .when: return true
        case .settings: return true
        }
    }

    var body: some View {
        Group {
            if let game = createdGame {
                successView(game: game)
            } else {
                wizardContent
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

    private var wizardContent: some View {
        VStack(spacing: 0) {
            StepIndicator(currentStep: currentStep) { step in
                if step.rawValue < currentStep.rawValue {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentStep = step
                    }
                }
            }

            Divider()
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 24) {
                    switch currentStep {
                    case .sport:
                        stepSport
                    case .where_:
                        stepWhere
                    case .when:
                        stepWhen
                    case .settings:
                        stepSettings
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))

            // Bottom button
            bottomButton
        }
    }

    // MARK: - Step 1: Sport
    private var stepSport: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("SELECT SPORT")
                    .fieldLabel()

                HStack(spacing: 0) {
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
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("FORMAT")
                    .fieldLabel()

                HStack(spacing: 8) {
                    ForEach(availableFormats, id: \.format) { item in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFormat = item.format
                                customMaxPlayers = item.players
                            }
                        } label: {
                            Text(item.format)
                                .font(.subheadline)
                                .fontWeight(selectedFormat == item.format ? .semibold : .regular)
                                .foregroundColor(selectedFormat == item.format ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    selectedFormat == item.format ? Color.accentBlue : Color(.secondarySystemBackground)
                                )
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("MAX PLAYERS")
                    .fieldLabel()

                HStack(spacing: 12) {
                    Button {
                        if customMaxPlayers > 2 { customMaxPlayers -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(customMaxPlayers > 2 ? .accentBlue : Color(.systemGray4))
                    }
                    .disabled(customMaxPlayers <= 2)

                    Text("\(customMaxPlayers)")
                        .font(.title)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .frame(minWidth: 44)

                    Button {
                        if customMaxPlayers < 50 { customMaxPlayers += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(customMaxPlayers < 50 ? .accentBlue : Color(.systemGray4))
                    }
                    .disabled(customMaxPlayers >= 50)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Step 2: Where
    private var stepWhere: some View {
        VStack(alignment: .leading, spacing: 12) {
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

    // MARK: - Step 3: When
    private var stepWhen: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("DATE")
                    .fieldLabel()

                DatePicker("", selection: $gameDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accentColor(.accentBlue)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("TIME")
                    .fieldLabel()

                DatePicker("", selection: $gameTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 100)
            }
        }
    }

    // MARK: - Step 4: Settings
    private var stepSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("SKILL LEVEL")
                    .fieldLabel()

                SegmentedLevelPicker(levels: levels, selectedLevel: $level)
            }

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

            Toggle(isOn: $isPublic) {
                HStack(spacing: 12) {
                    Image(systemName: isPublic ? "globe" : "lock.fill")
                        .font(.title3)
                        .foregroundColor(isPublic ? .accentBlue : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isPublic ? "Public Game" : "Private Game")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(isPublic ? "Visible in Discover" : "Only accessible via link")
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
    }

    // MARK: - Bottom Button
    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                if currentStep == .settings {
                    createGame()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if let next = WizardStep(rawValue: currentStep.rawValue + 1) {
                            currentStep = next
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else if currentStep == .settings {
                        Image(systemName: "link.badge.plus")
                        Text("Create & Get Link")
                    } else {
                        Text("Next")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canAdvance ? Color.accentBlue : Color.gray.opacity(0.4))
                .cornerRadius(14)
            }
            .disabled(!canAdvance || isLoading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
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

                if let dismissAction = onDismiss {
                    Button {
                        onGameCreated(game)
                        dismissAction()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.accentBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentBlue.opacity(0.12))
                            .cornerRadius(14)
                    }
                } else {
                    Button {
                        createdGame = nil
                        location = ""
                        currentStep = .sport
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
                    maxPlayers: customMaxPlayers,
                    isPublic: isPublic,
                    creatorPhone: userManager.currentUser?.phone
                )

                if imPlaying, let userName = userManager.currentUser?.name,
                   let userPhone = userManager.currentUser?.phone {
                    game = try await api.joinGame(id: game.id, name: userName, phone: userPhone)
                }

                createdGame = game
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - CreateGameView (Modal with Navigation)
struct CreateGameView: View {
    @Environment(\.dismiss) private var dismiss
    let onGameCreated: (Game) -> Void

    var body: some View {
        NavigationStack {
            GameCreationWizard(
                onGameCreated: onGameCreated,
                onDismiss: { dismiss() }
            )
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.accentBlue)
                }
            }
        }
    }
}

// MARK: - CreateGameFormView (For Tab Context)
struct CreateGameFormView: View {
    let onGameCreated: (Game) -> Void

    var body: some View {
        GameCreationWizard(
            onGameCreated: onGameCreated,
            onDismiss: nil
        )
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

#Preview {
    CreateGameView(onGameCreated: { _ in })
        .environmentObject(UserManager.shared)
}

#Preview("Tab Form") {
    NavigationStack {
        CreateGameFormView(onGameCreated: { _ in })
            .environmentObject(UserManager.shared)
    }
}
