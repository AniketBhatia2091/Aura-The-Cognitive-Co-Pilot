import SwiftUI

/// A premium, slow-moving blurred orb background that matches the app's 'aura' aesthetic.
struct AmbientBackground: View {
    let accentColor: Color
    let theme: AuraTheme
    
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            // Base background
            LinearGradient(
                colors: theme.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Aura Orbs — subtler opacity for a calmer feel
            GeometryReader { geo in
                ZStack {
                    // Orb 1 (Top Left) — primary accent
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: geo.size.width * 1.1)
                        .offset(
                            x: animate ? -30 : -60,
                            y: animate ? -geo.size.height * 0.2 : -geo.size.height * 0.1
                        )
                        .blur(radius: 90)
                    
                    // Orb 2 (Right middle) — theme accent
                    Circle()
                        .fill(theme.accent.opacity(0.08))
                        .frame(width: geo.size.width * 0.9)
                        .offset(
                            x: animate ? geo.size.width * 0.35 : geo.size.width * 0.2,
                            y: animate ? geo.size.height * 0.1 : geo.size.height * 0.3
                        )
                        .blur(radius: 110)
                    
                    // Orb 3 (Bottom center) — softer spread
                    Ellipse()
                        .fill(accentColor.opacity(0.10))
                        .frame(width: geo.size.width * 1.4, height: geo.size.width * 0.9)
                        .offset(y: animate ? geo.size.height * 0.6 : geo.size.height * 0.7)
                        .blur(radius: 100)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 10.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
