// OnboardingView.swift

import SwiftUI

struct OnboardingView: View {
    
    let onComplete: () -> Void
    
    @State private var currentPage = 0
    @State private var animateIcon = false
    @State private var glowOpacity: Double = 0.3
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain.head.profile",
            title: "Dump Your Thoughts",
            subtitle: "Pour everything out — tasks, worries, ideas.\nAura structures the chaos for you.",
            gradient: [
                Color(red: 0.55, green: 0.48, blue: 1.0),
                Color(red: 0.35, green: 0.78, blue: 0.98)
            ]
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "Task Prioritization",
            subtitle: "Aura detects urgency, assigns priorities,\nand surfaces your quick wins first.",
            gradient: [
                Color(red: 0.45, green: 0.85, blue: 0.55),
                Color(red: 0.35, green: 0.78, blue: 0.98)
            ]
        ),
        OnboardingPage(
            icon: "circle.hexagongrid",
            title: "Focus Ring",
            subtitle: "One task at a time. A calm interface\nthat adapts to your cognitive load.",
            gradient: [
                Color(red: 0.55, green: 0.48, blue: 1.0),
                Color(red: 0.75, green: 0.45, blue: 0.95)
            ]
        ),
        OnboardingPage(
            icon: "leaf.fill",
            title: "Built for Your Mind",
            subtitle: "No cloud. No sign-up. No noise.\nJust clarity, on your device.",
            gradient: [
                Color(red: 0.35, green: 0.78, blue: 0.98),
                Color(red: 0.55, green: 0.48, blue: 1.0)
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.14),
                    Color(red: 0.11, green: 0.10, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            onComplete()
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.trailing, 24)
                        .padding(.top, 8)
                    }
                }
                .frame(height: 40)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page: page, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentPage)
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage
                                  ? pages[currentPage].gradient.first ?? .white
                                  : .white.opacity(0.2))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 32)
                
                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage == pages.count - 1 ? "Begin" : "Next")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if currentPage == pages.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: pages[currentPage].gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
    
    
    @ViewBuilder
    private func pageView(page: OnboardingPage, index: Int) -> some View {
        VStack(spacing: 28) {
            Spacer()
            
            // Icon with animated glow
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.gradient.first?.opacity(0.3) ?? .clear, .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .opacity(currentPage == index ? glowOpacity : 0.1)
                
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 120, height: 120)
                    .opacity(0.3)
                
                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating, isActive: currentPage == index)
            }
            
            // Title
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text(page.subtitle)
                .font(.body)
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }
    }
}


private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
}
