// SessionState.swift

import SwiftUI

enum CognitiveLoad: String, CaseIterable {
    case normal      // Default — standard vibrant UI
    case loaded      // Slightly high — subtle dimming begins
    case overwhelmed // Threshold exceeded — full calm mode activated
}

struct SessionState {
    var load: CognitiveLoad = .normal
    var score: Int = 0          // 0-100 cognitive load score
    var initialScore: Int = 0   // Score at the start of the session for reflection
    var activeTaskID: UUID? = nil
    var keystrokeCount: Int = 0
    var windowStart: Date = .now
}

struct AuraTheme {
    let backgroundGradient: [Color]
    let cardBackground: Color
    let primaryText: Color
    let secondaryText: Color
    let accent: Color
    let ringGradient: [Color]
    
    static func forLoad(_ load: CognitiveLoad) -> AuraTheme {
        switch load {
        case .normal:
            return AuraTheme(
                backgroundGradient: [
                    Color(red: 0.07, green: 0.07, blue: 0.14),
                    Color(red: 0.11, green: 0.10, blue: 0.22)
                ],
                cardBackground: Color.white.opacity(0.06),
                primaryText: .white,
                secondaryText: .white.opacity(0.55),
                accent: Color(red: 0.55, green: 0.48, blue: 1.0),
                ringGradient: [
                    Color(red: 0.55, green: 0.48, blue: 1.0),
                    Color(red: 0.35, green: 0.78, blue: 0.98)
                ]
            )
        case .loaded:
            return AuraTheme(
                backgroundGradient: [
                    Color(red: 0.06, green: 0.06, blue: 0.12),
                    Color(red: 0.09, green: 0.09, blue: 0.18)
                ],
                cardBackground: Color.white.opacity(0.04),
                primaryText: .white.opacity(0.85),
                secondaryText: .white.opacity(0.45),
                accent: Color(red: 0.45, green: 0.40, blue: 0.85),
                ringGradient: [
                    Color(red: 0.45, green: 0.40, blue: 0.85),
                    Color(red: 0.30, green: 0.65, blue: 0.82)
                ]
            )
        case .overwhelmed:
            return AuraTheme(
                backgroundGradient: [
                    Color(red: 0.05, green: 0.05, blue: 0.09),
                    Color(red: 0.07, green: 0.07, blue: 0.12)
                ],
                cardBackground: Color.white.opacity(0.03),
                primaryText: .white.opacity(0.70),
                secondaryText: .white.opacity(0.35),
                accent: Color(red: 0.35, green: 0.55, blue: 0.65),
                ringGradient: [
                    Color(red: 0.35, green: 0.55, blue: 0.65),
                    Color(red: 0.25, green: 0.45, blue: 0.55)
                ]
            )
        }
    }
}
