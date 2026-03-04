import SwiftUI
import UIKit

/// A lightweight manager for triggering haptic feedback across the app.
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// Triggers a light impact (e.g., standard button taps, changing states)
    func playLightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Triggers a medium impact (e.g., creating a new project, larger structural changes)
    func playMediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Triggers a success notification (e.g., finishing a task or session)
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Triggers an error notification
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}
