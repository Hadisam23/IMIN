import Foundation
import SwiftUI
import Combine

class UserManager: ObservableObject {
    @MainActor static let shared = UserManager()

    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false

    private let userDefaultsKey = "currentUser"
    private let onboardingKey = "hasCompletedOnboarding"

    init() {
        loadUser()
    }

    // MARK: - Authentication

    func signIn(name: String, phone: String) {
        let user = User(name: name, phone: phone)
        currentUser = user
        isAuthenticated = true
        saveUser()
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: onboardingKey)
    }

    // MARK: - Onboarding

    func completeOnboarding(sports: [UserSport], location: String) {
        guard var user = currentUser else { return }
        user.sports = sports
        user.location = location
        currentUser = user
        hasCompletedOnboarding = true
        saveUser()
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    // MARK: - Profile Updates

    func updateName(_ name: String) {
        guard var user = currentUser else { return }
        user.name = name
        currentUser = user
        saveUser()
    }

    func updateLocation(_ location: String) {
        guard var user = currentUser else { return }
        user.location = location
        currentUser = user
        saveUser()
    }

    func updateSports(_ sports: [UserSport]) {
        guard var user = currentUser else { return }
        user.sports = sports
        currentUser = user
        saveUser()
    }

    func updateFreeTime(_ slots: [FreeTimeSlot]) {
        guard var user = currentUser else { return }
        user.freeTimeSlots = slots
        currentUser = user
        saveUser()
    }

    func addFreeTimeSlot(_ slot: FreeTimeSlot) {
        guard var user = currentUser else { return }
        user.freeTimeSlots.append(slot)
        currentUser = user
        saveUser()
    }

    func removeFreeTimeSlot(_ slot: FreeTimeSlot) {
        guard var user = currentUser else { return }
        user.freeTimeSlots.removeAll { $0.id == slot.id }
        currentUser = user
        saveUser()
    }

    // MARK: - Persistence

    private func saveUser() {
        guard let user = currentUser else { return }
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
            hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        }
    }
}
