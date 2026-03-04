// CalmOverlay.swift

import SwiftUI

/// Overlay triggered by Calm Mode.
/// Softens the background and displays the encouraging message to visually pace the user.
struct CalmOverlay: View {
    let message: String
    let theme: AuraTheme
    
    var body: some View {
        ZStack {
            // A subtle vignette/blur over the edges
            RadialGradient(
                colors: [
                    Color.clear,
                    theme.backgroundGradient[0].opacity(0.85)
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)
            
            // Soft floating light at the top
            Circle()
                .fill(theme.accent.opacity(0.15))
                .blur(radius: 60)
                .frame(width: 300, height: 300)
                .offset(y: -250)
                .accessibilityHidden(true)
                
            VStack {
                Spacer()
                
                if !message.isEmpty {
                    Text(message)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.accent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 60)
                        .shadow(color: theme.accent.opacity(0.5), radius: 10, y: 0)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .accessibilityLabel("Supportive Message: \(message)")
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
        }
        .animation(.easeInOut(duration: 1.0), value: message)
    }
}
