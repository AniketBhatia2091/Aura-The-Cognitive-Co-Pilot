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
                    Color(red: 0.05, green: 0.055, blue: 0.094),   // #0D0E18
                    Color(red: 0.086, green: 0.09, blue: 0.14)     // #161724
                ],
                cardBackground: Color.white.opacity(0.055),
                primaryText: Color(red: 0.945, green: 0.945, blue: 0.957),  // #F1F1F4
                secondaryText: Color(red: 0.42, green: 0.44, blue: 0.58),   // #6B7094
                accent: Color(red: 0.55, green: 0.48, blue: 1.0),           // #8C7AFF
                ringGradient: [
                    Color(red: 0.55, green: 0.48, blue: 1.0),
                    Color(red: 0.39, green: 0.40, blue: 0.945)              // #6366F1
                ]
            )
        case .loaded:
            return AuraTheme(
                backgroundGradient: [
                    Color(red: 0.045, green: 0.05, blue: 0.08),
                    Color(red: 0.075, green: 0.08, blue: 0.125)
                ],
                cardBackground: Color.white.opacity(0.04),
                primaryText: Color(red: 0.92, green: 0.92, blue: 0.94).opacity(0.9),
                secondaryText: Color(red: 0.42, green: 0.44, blue: 0.58).opacity(0.8),
                accent: Color(red: 0.45, green: 0.40, blue: 0.85),
                ringGradient: [
                    Color(red: 0.45, green: 0.40, blue: 0.85),
                    Color(red: 0.39, green: 0.40, blue: 0.945)
                ]
            )
        case .overwhelmed:
            return AuraTheme(
                backgroundGradient: [
                    Color(red: 0.04, green: 0.04, blue: 0.065),
                    Color(red: 0.06, green: 0.06, blue: 0.09)
                ],
                cardBackground: Color.white.opacity(0.03),
                primaryText: Color(red: 0.92, green: 0.92, blue: 0.94).opacity(0.75),
                secondaryText: Color(red: 0.42, green: 0.44, blue: 0.58).opacity(0.6),
                accent: Color(red: 0.39, green: 0.40, blue: 0.945),  // Calm indigo
                ringGradient: [
                    Color(red: 0.39, green: 0.40, blue: 0.945),
                    Color(red: 0.20, green: 0.83, blue: 0.60)        // Calming teal
                ]
            )
        }
    }
}
