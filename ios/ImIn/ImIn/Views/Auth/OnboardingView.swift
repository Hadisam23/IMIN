import SwiftUI

// MARK: - Available Cities
enum AvailableCity: String, CaseIterable {
    case london = "London"
    case madrid = "Madrid"
    case newYork = "New York"
    case paris = "Paris"
    case berlin = "Berlin"
    case barcelona = "Barcelona"
    case amsterdam = "Amsterdam"
    case dubai = "Dubai"
    case singapore = "Singapore"
    case tokyo = "Tokyo"
}

struct OnboardingView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var currentStep = 0
    @State private var selectedCity: AvailableCity = .london
    @State private var selectedSports: [UserSport] = []
    @State private var freeTimeSlots: [FreeTimeSlot] = []

    private let totalSteps = 3

    private var canProceed: Bool {
        switch currentStep {
        case 0: return true // City is always selected from picker
        case 1: return !selectedSports.isEmpty
        case 2: return true // Free time is optional
        default: return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressBar
                .padding(.horizontal, 24)
                .padding(.top, 16)

            // Step content
            TabView(selection: $currentStep) {
                locationStep
                    .tag(0)

                sportsStep
                    .tag(1)

                freeTimeStep
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)

            // Navigation buttons
            navigationButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.accentBlue : Color(.systemGray4))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Step 1: Location

    private var locationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Where are you located?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("We'll show you games nearby")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // City grid picker
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AvailableCity.allCases, id: \.rawValue) { city in
                    Button {
                        selectedCity = city
                    } label: {
                        Text(city.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedCity == city ? .semibold : .regular)
                            .foregroundColor(selectedCity == city ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedCity == city ? Color.accentBlue : Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    // MARK: - Step 2: Sports Selection

    private var sportsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What sports do you play?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Select your sports and skill level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(AvailableSport.allCases, id: \.rawValue) { sport in
                    SportSelectionCard(
                        sport: sport,
                        selectedSport: selectedSportBinding(for: sport)
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
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

    // MARK: - Step 3: Free Time

    private var freeTimeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("When are you free to play?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("This helps match you with games (optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Weekday.allCases, id: \.rawValue) { day in
                        FreeTimeRow(day: day, selectedSlots: $freeTimeSlots)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.accentBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentBlue.opacity(0.12))
                        .cornerRadius(14)
                }
            }

            Button {
                if currentStep < totalSteps - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentStep < totalSteps - 1 ? "Continue" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canProceed ? Color.accentBlue : Color.gray.opacity(0.4))
                    .cornerRadius(14)
            }
            .disabled(!canProceed)
        }
    }

    private func completeOnboarding() {
        userManager.completeOnboarding(
            sports: selectedSports,
            location: selectedCity.rawValue
        )
        userManager.updateFreeTime(freeTimeSlots)
    }
}

// MARK: - Sport Selection Card

struct SportSelectionCard: View {
    let sport: AvailableSport
    @Binding var selectedSport: UserSport?

    private var isSelected: Bool {
        selectedSport != nil
    }

    var body: some View {
        VStack(spacing: 12) {
            Button {
                if isSelected {
                    selectedSport = nil
                } else {
                    selectedSport = UserSport(sport: sport.rawValue, level: .intermediate)
                }
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.accentBlue : Color(.secondarySystemBackground))
                            .frame(width: 60, height: 60)

                        Image(systemName: sport.iconName)
                            .font(.system(size: 26))
                            .foregroundColor(isSelected ? .white : .primary)
                    }

                    Text(sport.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)

            if isSelected {
                levelPicker
            }
        }
        .padding()
        .background(isSelected ? Color.accentBlue.opacity(0.1) : Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var levelPicker: some View {
        Menu {
            ForEach(SkillLevel.allCases.filter { $0 != .none }, id: \.rawValue) { level in
                Button {
                    selectedSport = UserSport(sport: sport.rawValue, level: level)
                } label: {
                    Text(level.rawValue)
                }
            }
        } label: {
            HStack {
                Text(selectedSport?.level.rawValue ?? "Level")
                    .font(.caption)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.accentBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
}

// MARK: - Free Time Row

struct FreeTimeRow: View {
    let day: Weekday
    @Binding var selectedSlots: [FreeTimeSlot]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                ForEach(TimeOfDay.allCases, id: \.rawValue) { timeOfDay in
                    TimeSlotButton(
                        timeOfDay: timeOfDay,
                        isSelected: isSlotSelected(day: day, timeOfDay: timeOfDay),
                        action: { toggleSlot(day: day, timeOfDay: timeOfDay) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func isSlotSelected(day: Weekday, timeOfDay: TimeOfDay) -> Bool {
        selectedSlots.contains { $0.day == day && $0.timeOfDay == timeOfDay }
    }

    private func toggleSlot(day: Weekday, timeOfDay: TimeOfDay) {
        if let index = selectedSlots.firstIndex(where: { $0.day == day && $0.timeOfDay == timeOfDay }) {
            selectedSlots.remove(at: index)
        } else {
            selectedSlots.append(FreeTimeSlot(day: day, timeOfDay: timeOfDay))
        }
    }
}

// MARK: - Time Slot Button

struct TimeSlotButton: View {
    let timeOfDay: TimeOfDay
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: timeOfDay.icon)
                    .font(.caption)
                Text(timeOfDay.rawValue)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .white : .secondary)
            .background(isSelected ? Color.accentBlue : Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserManager.shared)
}
