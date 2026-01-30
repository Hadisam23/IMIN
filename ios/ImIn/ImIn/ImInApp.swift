//
//  ImInApp.swift
//  ImIn
//
//  Created by Hadi Samara on 26/01/2026.
//

import SwiftUI

@main
struct ImInApp: App {
    @StateObject private var userManager = UserManager()
    @AppStorage("appearanceMode") private var appearanceMode = 0
    @State private var showLaunch = true

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil // System default
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if userManager.isAuthenticated {
                        if userManager.hasCompletedOnboarding {
                            MainTabView()
                        } else {
                            OnboardingView()
                        }
                    } else {
                        SignInView()
                    }
                }
                .environmentObject(userManager)
                .preferredColorScheme(colorScheme)

                if showLaunch {
                    LaunchAnimationView {
                        showLaunch = false
                    }
                    .ignoresSafeArea()
                    .zIndex(1)
                }
            }
        }
    }
}
