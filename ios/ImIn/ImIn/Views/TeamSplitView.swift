import SwiftUI

struct TeamSplitView: View {
    let gameId: String
    let initialPlayersPerTeam: Int
    @Binding var players: [Player]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var teams: [[Player]] = []
    @State private var selectedPlayer: Player?
    @State private var showingUnassignedWarning = false
    @State private var numberOfTeams: Int = 2

    private var playersPerTeam: Int {
        guard numberOfTeams > 0 else { return players.count }
        return (players.count + numberOfTeams - 1) / numberOfTeams // Round up
    }

    private var possibleTeamCounts: [Int] {
        // Offer 2, 3, 4 teams or more based on player count
        let maxTeams = min(players.count / 2, 6) // At least 2 per team, max 6 teams
        return Array(2...max(2, maxTeams))
    }

    private var teamColors: [Color] {
        [.accentBlue, .successGreen, .warningOrange, .purple, .pink, .teal]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Team totals header
                teamTotalsHeader

                // Teams grid
                ScrollView {
                    if teams.isEmpty {
                        emptyState
                    } else {
                        teamsGrid
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Split Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        splitTeams()
                    } label: {
                        Label("Reshuffle", systemImage: "shuffle")
                    }
                }
            }
            .onAppear {
                // Calculate initial number of teams based on players per team
                if initialPlayersPerTeam > 0 {
                    numberOfTeams = max(2, players.count / initialPlayersPerTeam)
                }
                if teams.isEmpty {
                    splitTeams()
                }
            }
            .alert("Unassigned Skills", isPresented: $showingUnassignedWarning) {
                Button("Split Anyway") {
                    performSplit()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Some players don't have skill levels assigned. They will be treated as skill level 3 (average).")
            }
        }
    }

    private var teamTotalsHeader: some View {
        VStack(spacing: 12) {
            // Team count picker
            HStack {
                Text("Teams:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Number of teams", selection: $numberOfTeams) {
                    ForEach(possibleTeamCounts, id: \.self) { count in
                        Text("\(count) teams").tag(count)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: numberOfTeams) { _, _ in
                    performSplit()
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Team totals
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(teams.enumerated()), id: \.offset) { index, team in
                        VStack(spacing: 4) {
                            Text("Team \(index + 1)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(teamColors[index % teamColors.count])

                            Text("\(teamTotal(team))")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("\(team.count) players")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(minWidth: 80)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(teamColors[index % teamColors.count].opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.systemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No players to split")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Add players to the game first")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var teamsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(Array(teams.enumerated()), id: \.offset) { teamIndex, team in
                teamCard(teamIndex: teamIndex, team: team)
            }
        }
        .padding()
    }

    private func teamCard(teamIndex: Int, team: [Player]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Team header
            HStack {
                Circle()
                    .fill(teamColors[teamIndex % teamColors.count])
                    .frame(width: 12, height: 12)

                Text("Team \(teamIndex + 1)")
                    .font(.headline)

                Spacer()

                Text("Total: \(teamTotal(team))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Players
            VStack(spacing: 8) {
                ForEach(team) { player in
                    teamPlayerRow(player: player, teamIndex: teamIndex)
                }
            }

            if team.count < playersPerTeam {
                Text("\(playersPerTeam - team.count) more needed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(
            color: colorScheme == .dark ? .clear : .black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 2
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    selectedPlayer != nil ? teamColors[teamIndex % teamColors.count].opacity(0.5) : .clear,
                    lineWidth: 2
                )
        )
        .onTapGesture {
            if let selected = selectedPlayer {
                movePlayer(selected, toTeam: teamIndex)
            }
        }
    }

    private func teamPlayerRow(player: Player, teamIndex: Int) -> some View {
        HStack(spacing: 8) {
            // Skill badge
            Text("\(player.skillLevel ?? 3)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(skillColor(player.skillLevel ?? 3))
                .cornerRadius(6)

            // Name
            Text(player.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(selectedPlayer?.id == player.id ? teamColors[teamIndex % teamColors.count].opacity(0.2) : .clear)
        .cornerRadius(8)
        .onTapGesture {
            if selectedPlayer?.id == player.id {
                selectedPlayer = nil
            } else {
                selectedPlayer = player
            }
        }
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

    private func teamTotal(_ team: [Player]) -> Int {
        team.reduce(0) { $0 + ($1.skillLevel ?? 3) }
    }

    private func splitTeams() {
        // Check if any players don't have skill levels
        let hasUnassigned = players.contains { $0.skillLevel == nil }

        if hasUnassigned {
            showingUnassignedWarning = true
        } else {
            performSplit()
        }
    }

    private func performSplit() {
        // Shuffled Greedy Assignment algorithm
        var shuffledPlayers = players.shuffled()

        // Sort by skill (descending), keeping shuffle order for same-skill players
        shuffledPlayers.sort { ($0.skillLevel ?? 3) > ($1.skillLevel ?? 3) }

        // Initialize empty teams
        var newTeams: [[Player]] = Array(repeating: [], count: numberOfTeams)

        // Assign each player to the team with lowest total skill
        for player in shuffledPlayers {
            // Find team with lowest total (prefer teams with fewer players on tie)
            let teamIndex = newTeams.enumerated().min { team1, team2 in
                let total1 = teamTotal(team1.element)
                let total2 = teamTotal(team2.element)
                if total1 == total2 {
                    return team1.element.count < team2.element.count
                }
                return total1 < total2
            }?.offset ?? 0

            newTeams[teamIndex].append(player)
        }

        teams = newTeams
        selectedPlayer = nil
    }

    private func movePlayer(_ player: Player, toTeam destinationIndex: Int) {
        // Find current team
        guard let sourceIndex = teams.firstIndex(where: { $0.contains(player) }),
              sourceIndex != destinationIndex else {
            selectedPlayer = nil
            return
        }

        // Remove from source
        teams[sourceIndex].removeAll { $0.id == player.id }

        // Add to destination
        teams[destinationIndex].append(player)

        selectedPlayer = nil
    }
}

#Preview {
    TeamSplitView(
        gameId: "test",
        initialPlayersPerTeam: 5,
        players: .constant([
            Player(id: "1", name: "John Doe", phone: nil, timestamp: nil, skillLevel: 5),
            Player(id: "2", name: "Jane Smith", phone: nil, timestamp: nil, skillLevel: 4),
            Player(id: "3", name: "Bob Wilson", phone: nil, timestamp: nil, skillLevel: 3),
            Player(id: "4", name: "Alice Brown", phone: nil, timestamp: nil, skillLevel: 3),
            Player(id: "5", name: "Charlie Davis", phone: nil, timestamp: nil, skillLevel: 2),
            Player(id: "6", name: "Diana Evans", phone: nil, timestamp: nil, skillLevel: 4),
            Player(id: "7", name: "Edward Fox", phone: nil, timestamp: nil, skillLevel: 5),
            Player(id: "8", name: "Fiona Green", phone: nil, timestamp: nil, skillLevel: 2),
            Player(id: "9", name: "George Hill", phone: nil, timestamp: nil, skillLevel: 3),
            Player(id: "10", name: "Helen Ivy", phone: nil, timestamp: nil, skillLevel: 1)
        ])
    )
}
