import SwiftUI

struct LaunchAnimationView: View {
    let onFinished: () -> Void

    private let symbols = [
        "figure.run",
        "figure.soccer",
        "figure.basketball",
        "figure.tennis",
        "figure.baseball",
        "figure.volleyball",
        "figure.2"
    ]

    @State private var currentIndex = 0
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var showTitle = false
    @State private var fadeOut = false

    var body: some View {
        ZStack {
            Color.accentBlue
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: symbols[currentIndex])
                    .font(.system(size: 80, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                    .id(currentIndex)

                if showTitle {
                    Text("I'm In")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .opacity(fadeOut ? 0 : 1)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // First icon appears
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // Cycle through figures
        for i in 1..<symbols.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.35) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    iconScale = 0.7
                    iconOpacity = 0.5
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    currentIndex = i
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        iconScale = 1.0
                        iconOpacity = 1.0
                    }
                }
            }
        }

        // Show title after last icon
        let titleDelay = Double(symbols.count) * 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + titleDelay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showTitle = true
            }
        }

        // Fade out and finish
        DispatchQueue.main.asyncAfter(deadline: .now() + titleDelay + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                fadeOut = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onFinished()
            }
        }
    }
}

#Preview {
    LaunchAnimationView(onFinished: {})
}
