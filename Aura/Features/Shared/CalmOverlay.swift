// CalmOverlay.swift

import SwiftUI

/// Overlay triggered by Calm Mode.
/// Provides a breathing animation and supportive message to help the user de-escalate.
struct CalmOverlay: View {
    let message: String
    let theme: AuraTheme
    
    @State private var breatheScale: CGFloat = 0.85
    @State private var breatheOpacity: Double = 0.15
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let calmAccent = Color(red: 0.39, green: 0.40, blue: 0.945)
    
    var body: some View {
        ZStack {
            // Dim vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.7)
                ],
                center: .center,
                startRadius: 60,
                endRadius: 400
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)
            
            VStack(spacing: 32) {
                Spacer()
                
                // Breathing circle
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(calmAccent.opacity(breatheOpacity))
                        .frame(width: 160, height: 160)
                        .scaleEffect(breatheScale)
                    
                    // Inner ring
                    Circle()
                        .stroke(calmAccent.opacity(0.3), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(breatheScale)
                    
                    // Center dot
                    Circle()
                        .fill(calmAccent.opacity(0.6))
                        .frame(width: 12, height: 12)
                }
                .accessibilityHidden(true)
                
                // Supportive message
                if !message.isEmpty {
                    VStack(spacing: 8) {
                        Text("Take a breath.")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.primaryText)
                        
                        Text(message)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .accessibilityLabel("Calm mode. \(message)")
                }
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            guard !reduceMotion else {
                breatheScale = 1.0
                breatheOpacity = 0.2
                return
            }
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) {
                breatheScale = 1.15
                breatheOpacity = 0.3
            }
        }
        .animation(.easeInOut(duration: 1.0), value: message)
    }
}
