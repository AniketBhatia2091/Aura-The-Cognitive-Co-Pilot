// UIState.swift

import SwiftUI
import Observation

@Observable
@MainActor
final class UIState {
    
    var session = SessionState()
    var theme: AuraTheme = .forLoad(.normal)
    var loadLabel: String = "Normal"
    var supportiveMessage: String = ""
    
    /// Cached representation of daily fatigue to avoid UserDefault reads during computations.
    var sessionsCompletedToday: Int = UserDefaults.standard.integer(forKey: "sessionsCompletedToday")
    
    private let textLengthElevated: Int = 150
    private let textLengthOverloaded: Int = 300
    private let typingSpeedThreshold: Double = 5.0
    private let windowDuration: TimeInterval = 5.0
    
    // New Heuristic thresholds
    private let conjunctionThreshold: Int = 4
    private let sentenceThreshold: Int = 5
    
    private let calmMessages = [
        "Take a breath. Let's simplify this together.",
        "You don't have to do everything at once.",
        "One step at a time. You've got this.",
        "Let me help you untangle your thoughts.",
        "It's okay to feel overwhelmed. Let's break it down."
    ]
    
    func onTextChanged(_ text: String, containsEmotionalWords: Bool = false) {
        let now = Date()
        
        // --- Keystroke speed tracking ---
        if now.timeIntervalSince(session.windowStart) > windowDuration {
            session.keystrokeCount = 0
            session.windowStart = now
        }
        session.keystrokeCount += 1
        
        // --- Calculate Cognitive Load Score (0-100) ---
        var newScore = 0
        
        let lowerText = text.lowercased()
        let words = lowerText.components(separatedBy: .whitespacesAndNewlines)
        
        // 1. Word count (Max ~30 points)
        newScore += min(words.count, 30)
        
        // 2. Emotional Words (+40 points)
        if containsEmotionalWords {
            newScore += 40
        }
        
        // 3. Conjunction density (Max ~20 points)
        let conjunctions: Set<String> = ["and", "also", "then", "but", "so"]
        let conjunctionCount = words.filter { conjunctions.contains($0) }.count
        newScore += min(conjunctionCount * 5, 20)
        
        // 4. Sentence Count (Max ~10 points)
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".?!"))
        let sentenceCount = sentences.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        newScore += min(sentenceCount * 2, 10)
        
        // Clamp to 100
        session.score = min(max(newScore, 0), 100)
        
        // --- Determine cognitive load state ---
        if session.score > 75 {
            session.load = .overwhelmed
        } else if session.score > 33 {
            session.load = .loaded
        } else {
            session.load = .normal
        }
        
        // Update derived properties with smooth animation.
        withAnimation(.easeInOut(duration: 0.6)) {
            theme = .forLoad(session.load)
            loadLabel = labelForLoad(session.load)
            
            if session.load == .overwhelmed {
                if supportiveMessage.isEmpty {
                    supportiveMessage = calmMessages.randomElement() ?? calmMessages[0]
                }
            } else {
                supportiveMessage = ""
            }
        }
    }
    
    func resetLoad() {
        session = SessionState()
        withAnimation(.easeInOut(duration: 0.6)) {
            theme = .forLoad(.normal)
            loadLabel = "Normal"
            supportiveMessage = ""
        }
    }
    
    private func labelForLoad(_ load: CognitiveLoad) -> String {
        switch load {
        case .normal: return "Normal"
        case .loaded: return "Loaded"
        case .overwhelmed: return "Overwhelmed"
        }
    }
    
    
    /// A deterministic multiplier (0.6 - 1.0) calculated from burnout velocity.
    /// It silently limits the length of suggested timers to protect the user's attention.
    var sessionScalingFactor: Double {
        let scoreImpact = min(Double(session.score) / 200.0, 0.5)
        let sessionImpact = sessionsCompletedToday >= 3 ? 0.3 : 0.0
        
        let rawVelocity = scoreImpact + sessionImpact
        let scaled = 1.0 - rawVelocity
        
        // Clamp explicitly between 60% and 100% capacity
        return min(max(scaled, 0.6), 1.0)
    }
}
