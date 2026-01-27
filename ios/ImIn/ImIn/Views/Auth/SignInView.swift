import SwiftUI

struct SignInView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var name = ""
    @FocusState private var isNameFocused: Bool

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App branding
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentBlue.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentBlue)
                }

                VStack(spacing: 8) {
                    Text("Im In")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Find games. Join players.\nPlay together.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.bottom, 48)

            // Name input
            VStack(alignment: .leading, spacing: 12) {
                Text("What's your name?")
                    .font(.headline)

                TextField("Enter your name", text: $name)
                    .font(.body)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .focused($isNameFocused)
                    .submitLabel(.continue)
                    .onSubmit {
                        if canContinue {
                            continueToOnboarding()
                        }
                    }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            VStack(spacing: 16) {
                Button {
                    continueToOnboarding()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canContinue ? Color.accentBlue : Color.gray.opacity(0.4))
                        .cornerRadius(14)
                }
                .disabled(!canContinue)

                // Future social login placeholders
                VStack(spacing: 12) {
                    Text("or continue with")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        socialButton(title: "Google", icon: "g.circle.fill", color: .red)
                        socialButton(title: "Facebook", icon: "f.circle.fill", color: .blue)
                    }
                }
                .opacity(0.5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .onAppear {
            isNameFocused = true
        }
    }

    private func socialButton(title: String, icon: String, color: Color) -> some View {
        Button {
            // Future: Social login
        } label: {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .disabled(true)
    }

    private func continueToOnboarding() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        userManager.signIn(name: trimmedName)
    }
}

#Preview {
    SignInView()
        .environmentObject(UserManager.shared)
}
