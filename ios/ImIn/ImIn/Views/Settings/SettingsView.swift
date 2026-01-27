import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section {
                    NavigationLink {
                        PersonalInfoView()
                    } label: {
                        SettingsRow(icon: "person.fill", title: "Personal Info", color: .accentBlue)
                    }

                    NavigationLink {
                        NotificationsSettingsView()
                    } label: {
                        SettingsRow(icon: "bell.fill", title: "Notifications", color: .warningOrange)
                    }

                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        SettingsRow(icon: "lock.fill", title: "Privacy & Security", color: .successGreen)
                    }
                } header: {
                    Text("ACCOUNT")
                }

                // App Settings Section
                Section {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        SettingsRow(icon: "moon.fill", title: "Dark Mode", color: .purple)
                    }

                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        SettingsRow(icon: "globe", title: "Language", color: .accentBlue)
                    }

                    NavigationLink {
                        UnitsSettingsView()
                    } label: {
                        SettingsRow(icon: "ruler", title: "Units", color: .gray)
                    }
                } header: {
                    Text("APP SETTINGS")
                }

                // Support Section
                Section {
                    NavigationLink {
                        HelpCenterView()
                    } label: {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help Center", color: .accentBlue)
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRow(icon: "info.circle.fill", title: "About imin", color: .secondary)
                    }

                    NavigationLink {
                        FeedbackView()
                    } label: {
                        SettingsRow(icon: "envelope.fill", title: "Feedback", color: .successGreen)
                    }
                } header: {
                    Text("SUPPORT")
                }

                // Sign Out
                Section {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.errorRed)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    userManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .cornerRadius(6)

            Text(title)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Personal Info View

struct PersonalInfoView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var name = ""
    @State private var location = ""

    var body: some View {
        Form {
            Section("Name") {
                TextField("Your name", text: $name)
            }

            Section("Location") {
                TextField("City or neighborhood", text: $location)
            }
        }
        .navigationTitle("Personal Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = userManager.currentUser?.name ?? ""
            location = userManager.currentUser?.location ?? ""
        }
        .onDisappear {
            if !name.isEmpty {
                userManager.updateName(name)
            }
            userManager.updateLocation(location)
        }
    }
}

// MARK: - Placeholder Settings Views

struct NotificationsSettingsView: View {
    @State private var gameReminders = true
    @State private var newGamesNearby = true
    @State private var playerUpdates = true

    var body: some View {
        Form {
            Section {
                Toggle("Game Reminders", isOn: $gameReminders)
                Toggle("New Games Nearby", isOn: $newGamesNearby)
                Toggle("Player Updates", isOn: $playerUpdates)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    @State private var showProfile = true
    @State private var showLocation = true

    var body: some View {
        Form {
            Section("Visibility") {
                Toggle("Show Profile to Others", isOn: $showProfile)
                Toggle("Show Location", isOn: $showLocation)
            }
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode = 0

    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $appearanceMode) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
            } footer: {
                Text("Choose how the app appears on your device.")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LanguageSettingsView: View {
    @State private var selectedLanguage = "English"
    let languages = ["English", "Spanish", "French", "German"]

    var body: some View {
        Form {
            Section {
                ForEach(languages, id: \.self) { language in
                    Button {
                        selectedLanguage = language
                    } label: {
                        HStack {
                            Text(language)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentBlue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UnitsSettingsView: View {
    @State private var useMetric = true

    var body: some View {
        Form {
            Section {
                Toggle("Use Metric Units", isOn: $useMetric)
            } footer: {
                Text(useMetric ? "Distances in kilometers" : "Distances in miles")
            }
        }
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpCenterView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentBlue)

            Text("Help Center")
                .font(.title2)
                .fontWeight(.bold)

            Text("Need help? Visit our website for FAQs and support.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(32)
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentBlue)

            Text("Im In")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Find games. Join players. Play together.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(32)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeedbackView: View {
    @State private var feedback = ""

    var body: some View {
        Form {
            Section("Your Feedback") {
                TextEditor(text: $feedback)
                    .frame(minHeight: 150)
            }

            Section {
                Button {
                    // Submit feedback
                } label: {
                    HStack {
                        Spacer()
                        Text("Submit Feedback")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(feedback.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserManager.shared)
}
