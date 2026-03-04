// ContentView.swift

import SwiftUI

struct ContentView: View {
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(UIState.self) private var uiState
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView {
                withAnimation(.easeInOut(duration: 0.5)) {
                    hasCompletedOnboarding = true
                }
            }
            .transition(.opacity)
        } else {
            ProjectDashboardView()
        }
    }
}
