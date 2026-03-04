// FocusRingView.swift

import SwiftUI

/// Circular focus-ring widget showing the active task.
struct FocusRingView: View {
    let activeTask: AuraTask?
    let progress: Double
    let theme: AuraTheme
    let scalingFactor: Double
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var animateRing: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    
    // Timer state
    @State private var timeRemaining: Int = 0
    @State private var timerActive: Bool = false
    @State private var timerMessage: String? = nil
    @State private var timer: Timer? = nil
    
    private let baseTimerOptions = [5, 10, 15]
    
    /// Ambiently scales down default timer limits when the user's computed burnout velocity is high.
    private var adaptiveTimerOptions: [Int] {
        baseTimerOptions.map { base in
            let scaled = Double(base) * scalingFactor
            return max(1, Int(scaled.rounded()))
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Focus Ring")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .tracking(2)
                .foregroundColor(theme.secondaryText.opacity(0.6))
                .accessibilityHidden(true)
            
            ZStack {
                // Background track
                Circle()
                    .stroke(
                        theme.cardBackground,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .accessibilityHidden(true)
                
                // Animated progress arc (or timer fill)
                Circle()
                    .trim(from: 0, to: timerActive ? timerProgress : (animateRing ? progress : 0))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: theme.ringGradient),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(timerActive ? .linear(duration: 1.0) : .spring(response: 1.0, dampingFraction: 0.7), value: timerActive ? timerProgress : progress)
                    .accessibilityHidden(true)
                
                // Inner circle with glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.accent.opacity(0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(pulseScale)
                    .accessibilityHidden(true)
                
                // Task label inside the ring
                VStack(spacing: 4) {
                    if let task = activeTask {
                        
                        Text(task.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 4)
                            .id(task.id)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.8)).animation(.easeIn(duration: 0.2).delay(0.3)),
                                removal: .opacity.combined(with: .scale(scale: 0.5)).animation(.easeOut(duration: 0.2))
                            ))
                            .accessibilityAddTraits(.isHeader)
                        
                        if timerActive {
                            Text(formatTime(timeRemaining))
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(theme.accent)
                                .transition(.opacity)
                            
                            Button(action: stopTimerEarly) {
                                Text("Stop")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(theme.secondaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(.ultraThinMaterial.opacity(0.3))
                                            .overlay(
                                                Capsule().stroke(theme.secondaryText.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }
                            .accessibilityLabel("Stop Timer")
                        } else {
                            if let msg = timerMessage {
                                Text(msg)
                                    .font(.system(size: 9))
                                    .foregroundColor(theme.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .transition(.opacity)
                            }
                            
                            HStack(spacing: 6) {
                                ForEach(adaptiveTimerOptions, id: \.self) { min in
                                    Button(action: { startTimer(minutes: min) }) {
                                        Text("\(min)m")
                                            .font(.caption2.bold())
                                            .foregroundColor(theme.accent)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(theme.accent.opacity(0.15)))
                                    }
                                    .accessibilityLabel("Start \(min) minute focus timer")
                                }
                            }
                        }
                        
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundColor(theme.accent)
                        
                        Text("All Done!")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryText)
                    }
                }
                .frame(width: 170, height: 170)
                .clipShape(Circle())
            }
            
            // Progress percentage
            Text("\(Int(progress * 100))% Complete")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(theme.secondaryText)
                .animation(.easeOut, value: progress)
                .accessibilityLabel("Overall progress: \(Int(progress * 100)) percent")
        }
        .padding(.vertical, 20)
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.6)) {
                animateRing = true
            }
            if !reduceMotion {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    pulseScale = 1.08
                }
            }
        }
        .onChange(of: activeTask?.title) { _, _ in
            animateRing = false
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1)) {
                animateRing = true
            }
            stopTimerEarly()
            timerMessage = nil
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    // Timer Logic
    private var timerProgress: Double {
        let total = Double(timerMinutes * 60)
        guard total > 0 else { return 0 }
        return 1.0 - (Double(timeRemaining) / total)
    }
    
    @State private var timerMinutes = 0
    
    private func startTimer(minutes: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        timerMinutes = minutes
        timeRemaining = minutes * 60
        timerMessage = nil
        
        withAnimation {
            timerActive = true
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    withAnimation {
                        timerActive = false
                        timerMessage = "Great focus session."
                    }
                    let endGen = UINotificationFeedbackGenerator()
                    endGen.notificationOccurred(.success)
                }
            }
        }
    }
    
    private func stopTimerEarly() {
        if timerActive {
            timer?.invalidate()
            withAnimation {
                timerActive = false
                timerMessage = "That's okay. We continue."
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
