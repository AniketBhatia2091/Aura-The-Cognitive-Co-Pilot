// InputScreen.swift
// The brain-dump entry screen. Replaces InputView and no longer includes Speech framework elements.

import SwiftUI
import SwiftData

struct InputScreen: View {
    @Environment(InputLogic.self) private var inputLogic
    @Environment(UIState.self) private var uiState
    @Environment(\.modelContext) private var modelContext
    
    var onStructured: () -> Void
    var project: AuraProject? = nil
    @State private var showTagline = true
    @State private var showReflectionLog = false
    @State private var showEmptyAlert = false
    @State private var showAnalytics = false
    
    var body: some View {
        let theme = uiState.theme
        let isCalm = uiState.session.load == .overwhelmed
        
        ZStack {
            // Background
            LinearGradient(
                colors: theme.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: isCalm ? 32 : 20) {
                
                headerSection(theme: theme, isCalm: isCalm)
                
                loadBadge(theme: theme)
                
                textEditorSection(theme: theme, isCalm: isCalm)
                
                // CTA fades in only after user starts typing
                if !inputLogic.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    structureButton(theme: theme)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
                
                quickAccessRow(theme: theme)
                
                Text("Aura doesn't manage tasks. It helps manage your mind.")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(theme.secondaryText.opacity(0.35))
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: inputLogic.rawText.isEmpty)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            if isCalm {
                CalmOverlay(message: uiState.supportiveMessage, theme: theme)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeOut(duration: 1.0)) {
                    showTagline = false
                }
            }
        }
        .sheet(isPresented: $showReflectionLog) {
            NavigationStack {
                ReflectionLogView(project: project)
            }
        }
        .sheet(isPresented: $showAnalytics) {
            AnalyticsView(project: project)
        }
        .alert("Need a bit more", isPresented: $showEmptyAlert) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Try adding a bit more detail — a short phrase or sentence — so Aura can structure it for you.")
        }
    }
    
    @ViewBuilder
    private func headerSection(theme: AuraTheme, isCalm: Bool) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: isCalm ? 52 : 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: theme.ringGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating, isActive: isCalm)
                .accessibilityHidden(true)
            
            Text("Aura")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.primaryText, theme.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .accessibilityAddTraits(.isHeader)
            
            if showTagline {
                Text("What's on your mind?")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(theme.secondaryText)
                    .transition(.opacity)
            }
        }
        .padding(.top, 20)
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private func loadBadge(theme: AuraTheme) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(badgeColor)
                .frame(width: 7, height: 7)
            
            Text(uiState.loadLabel)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(theme.secondaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cognitive Load: \(uiState.loadLabel)")
    }
    
    @ViewBuilder
    private func textEditorSection(theme: AuraTheme, isCalm: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Brain Dump")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundColor(theme.secondaryText)
                .opacity(isCalm ? 0.3 : 1.0)
                .accessibilityHidden(true)
            
            ZStack(alignment: .topLeading) {
                if inputLogic.rawText.isEmpty {
                    Text("Pour your thoughts here…\nJust keep typing, Aura will sort it out.")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(theme.secondaryText.opacity(0.4))
                        .lineSpacing(4)
                        .padding(.top, 12)
                        .padding(.leading, 8)
                }
                
                @Bindable var inputBindable = inputLogic
                TextEditor(text: $inputBindable.rawText)
                    .font(.system(size: isCalm ? 19 : 17, weight: isCalm ? .medium : .regular, design: .rounded))
                    .foregroundColor(theme.primaryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: isCalm ? 260 : 220)
                    .padding(6)
                    .accessibilityLabel("Brain Dump Input")
                    .accessibilityHint("Type your thoughts freely. Aura will organize them into tasks.")
                    .onChange(of: inputLogic.rawText) { _, newValue in
                        uiState.onTextChanged(
                            newValue,
                            containsEmotionalWords: inputLogic.containsEmotionalWords
                        )
                    }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(theme.accent.opacity(isCalm ? 0.08 : 0.15), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private func structureButton(theme: AuraTheme) -> some View {
        VStack(spacing: 12) {
            Button {
                inputLogic.parseText()
                
                // Guard: never navigate to an empty plan
                guard !inputLogic.parsedTasks.isEmpty else {
                    showEmptyAlert = true
                    return
                }
                
                uiState.session.initialScore = uiState.session.score
                
                let session = BrainDumpSession(rawText: inputLogic.rawText, initialLoadScore: uiState.session.score, project: project)
                modelContext.insert(session)
                
                var orderedItems = inputLogic.parsedTasks
                if uiState.session.score > 75 && orderedItems.count > 1 {
                    if let shortestIndex = orderedItems.enumerated().min(by: { $0.element.title.count < $1.element.title.count })?.offset {
                        let shortest = orderedItems.remove(at: shortestIndex)
                        orderedItems.insert(shortest, at: 0)
                    }
                }
                
                for (index, item) in orderedItems.enumerated() {
                    let isMicroWin = (uiState.session.score > 75 && index == 0)
                    let task = AuraTask(title: item.title, priority: index + 1, category: item.category, isMicroWin: isMicroWin, session: session)
                    modelContext.insert(task)
                }
                
                uiState.resetLoad()
                inputLogic.clear()
                try? modelContext.save()
                onStructured()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.body)
                    Text("Structure My Thoughts")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: theme.ringGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: theme.accent.opacity(0.3), radius: 12, y: 6)
            }
            .disabled(inputLogic.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(inputLogic.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            .accessibilityLabel("Structure My Thoughts")
            .accessibilityHint("Analyzes your text and generates a structured task plan")
            
            HStack(spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption2)
                Text("100% On-Device Processing")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(theme.secondaryText.opacity(0.6))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("100 percent on-device processing. Your data is private.")
        }
    }
    @State private var shimmerPhase: CGFloat = -1.0
    
    @ViewBuilder
    private func quickAccessRow(theme: AuraTheme) -> some View {
        let reflectionGradient: [Color] = [
            Color(red: 0.45, green: 0.85, blue: 0.55),
            Color(red: 0.35, green: 0.78, blue: 0.98)
        ]
        
        HStack(spacing: 10) {
            // Reflection Log card
            Button(action: { showReflectionLog = true }) {
                quickAccessCard(
                    icon: "book.closed.fill",
                    title: "Reflection Log",
                    subtitle: "Past sessions",
                    gradient: reflectionGradient,
                    theme: theme
                )
            }
            .buttonStyle(QuickAccessButtonStyle())
            .accessibilityLabel("View Reflection Log")
            .accessibilityHint("Opens your past brain dump sessions")
            
            // Analytics card
            Button(action: { showAnalytics = true }) {
                quickAccessCard(
                    icon: "chart.bar.fill",
                    title: "Analytics",
                    subtitle: "Your patterns",
                    gradient: theme.ringGradient,
                    theme: theme
                )
            }
            .buttonStyle(QuickAccessButtonStyle())
            .accessibilityLabel("View Analytics")
            .accessibilityHint("Opens your cognitive wellness dashboard")
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmerPhase = 1.5
            }
        }
    }
    
    @ViewBuilder
    private func quickAccessCard(
        icon: String,
        title: String,
        subtitle: String,
        gradient: [Color],
        theme: AuraTheme
    ) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                gradient[0].opacity(0.25),
                                gradient[1].opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 34, height: 34)
                
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        gradient[0].opacity(0.35),
                                        gradient[1].opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: gradient[0].opacity(0.4), radius: 3, y: 1)
                    .symbolEffect(.bounce, options: .speed(0.5), value: shimmerPhase > 0)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(theme.secondaryText.opacity(0.7))
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(gradient[0].opacity(0.45))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial.opacity(0.35))
                
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                gradient[0].opacity(0.04),
                                gradient[1].opacity(0.02),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.04),
                                .white.opacity(0.07),
                                .white.opacity(0.04),
                                .clear
                            ],
                            startPoint: UnitPoint(x: shimmerPhase - 0.3, y: 0.5),
                            endPoint: UnitPoint(x: shimmerPhase + 0.3, y: 0.5)
                        )
                    )
                
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [
                                gradient[0].opacity(0.2),
                                gradient[1].opacity(0.06),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: gradient[0].opacity(0.05), radius: 10, y: 4)
        )
    }
    
    private var badgeColor: Color {
        switch uiState.session.load {
        case .normal: return .green
        case .loaded: return .orange
        case .overwhelmed: return .red
        }
    }
}

private struct QuickAccessButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
