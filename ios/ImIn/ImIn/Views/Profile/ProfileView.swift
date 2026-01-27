import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var isEditingSports = false
    @State private var showAddFreeTime = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader

                    // My Sports & Levels
                    sportsSection

                    // Free Time
                    freeTimeSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .sheet(isPresented: $isEditingSports) {
                EditSportsView()
            }
            .sheet(isPresented: $showAddFreeTime) {
                AddFreeTimeView()
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.accentBlue)
                    .frame(width: 80, height: 80)

                Text(userManager.currentUser?.initials ?? "?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // Name and location
            VStack(spacing: 4) {
                Text(userManager.currentUser?.name ?? "Player")
                    .font(.title2)
                    .fontWeight(.bold)

                if let location = userManager.currentUser?.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(location)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Sports Section

    private var sportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MY SPORTS & LEVELS")
                    .fieldLabel()

                Spacer()

                Button {
                    isEditingSports = true
                } label: {
                    Text("Edit")
                        .font(.subheadline)
                        .foregroundColor(.accentBlue)
                }
            }

            if let sports = userManager.currentUser?.sports, !sports.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(sports) { sport in
                        SportCard(sport: sport)
                    }
                }
            } else {
                emptyStateCard(
                    icon: "sportscourt.fill",
                    message: "No sports added yet",
                    action: { isEditingSports = true }
                )
            }
        }
    }

    // MARK: - Free Time Section

    private var freeTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FREE TIME")
                    .fieldLabel()

                Spacer()

                Button {
                    showAddFreeTime = true
                } label: {
                    Text("Add")
                        .font(.subheadline)
                        .foregroundColor(.accentBlue)
                }
            }

            if let slots = userManager.currentUser?.freeTimeSlots, !slots.isEmpty {
                VStack(spacing: 8) {
                    ForEach(slots) { slot in
                        FreeTimeSlotRow(slot: slot) {
                            userManager.removeFreeTimeSlot(slot)
                        }
                    }
                }
            } else {
                emptyStateCard(
                    icon: "clock.fill",
                    message: "No free time added",
                    action: { showAddFreeTime = true }
                )
            }
        }
    }

    // MARK: - Empty State Card

    private func emptyStateCard(icon: String, message: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sport Card

struct SportCard: View {
    let sport: UserSport

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: sport.iconName)
                .font(.title2)
                .foregroundColor(.accentBlue)

            Text(sport.sport)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(sport.level.shortName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(levelColor(sport.level))
                .cornerRadius(6)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func levelColor(_ level: SkillLevel) -> Color {
        switch level {
        case .none: return .gray
        case .beginner: return .successGreen
        case .intermediate: return .accentBlue
        case .advanced: return .warningOrange
        case .pro: return .purple
        }
    }
}

// MARK: - Free Time Slot Row

struct FreeTimeSlotRow: View {
    let slot: FreeTimeSlot
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .foregroundColor(.accentBlue)

            Text(slot.displayText)
                .font(.subheadline)

            Spacer()

            Circle()
                .fill(Color.successGreen)
                .frame(width: 8, height: 8)

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Edit Sports View

struct EditSportsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var selectedSports: [UserSport] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(AvailableSport.allCases, id: \.rawValue) { sport in
                        SportSelectionCard(
                            sport: sport,
                            selectedSport: selectedSportBinding(for: sport)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Sports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        userManager.updateSports(selectedSports)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedSports = userManager.currentUser?.sports ?? []
            }
        }
    }

    private func selectedSportBinding(for sport: AvailableSport) -> Binding<UserSport?> {
        Binding(
            get: {
                selectedSports.first { $0.sport == sport.rawValue }
            },
            set: { newValue in
                if let newValue = newValue {
                    if let index = selectedSports.firstIndex(where: { $0.sport == sport.rawValue }) {
                        selectedSports[index] = newValue
                    } else {
                        selectedSports.append(newValue)
                    }
                } else {
                    selectedSports.removeAll { $0.sport == sport.rawValue }
                }
            }
        )
    }
}

// MARK: - Add Free Time View

struct AddFreeTimeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var selectedDay: Weekday = .monday
    @State private var selectedTimeOfDay: TimeOfDay = .evening

    var body: some View {
        NavigationStack {
            Form {
                Section("Day") {
                    Picker("Day", selection: $selectedDay) {
                        ForEach(Weekday.allCases, id: \.self) { day in
                            Text(day.rawValue).tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section("Time of Day") {
                    Picker("Time", selection: $selectedTimeOfDay) {
                        ForEach(TimeOfDay.allCases, id: \.self) { time in
                            Label(time.rawValue, systemImage: time.icon).tag(time)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Free Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let slot = FreeTimeSlot(day: selectedDay, timeOfDay: selectedTimeOfDay)
                        userManager.addFreeTimeSlot(slot)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserManager.shared)
}
