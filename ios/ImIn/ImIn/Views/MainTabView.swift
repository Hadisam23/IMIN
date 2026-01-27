import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(0)

            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(1)

            CreateGameTabView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.accentBlue)
    }
}

// MARK: - Create Game Tab Wrapper
struct CreateGameTabView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var createdGame: Game?
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            CreateGameFormView(
                onGameCreated: { game in
                    createdGame = game
                    showSuccess = true
                },
                userName: userManager.currentUser?.name ?? ""
            )
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserManager.shared)
}
