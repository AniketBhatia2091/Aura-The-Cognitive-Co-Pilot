// ProjectWorkspaceView.swift

import SwiftUI
import SwiftData

struct ProjectWorkspaceView: View {
    let project: AuraProject
    
    @Environment(UIState.self) private var uiState
    @Environment(InputLogic.self) private var inputLogic
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \BrainDumpSession.createdAt, order: .reverse)
    private var allSessions: [BrainDumpSession]
    
    @State private var currentScreen: WorkspaceScreen = .input
    
    enum WorkspaceScreen { case input, plan }
    
    private var hasExistingSession: Bool {
        allSessions.contains { $0.project?.id == project.id }
    }
    
    var body: some View {
        let theme = uiState.theme
        
        VStack(spacing: 0) {
            // ── Redesigned top bar — clean, minimal
            HStack(spacing: 12) {
                // Back button — simplified
                Button {
                    HapticManager.shared.playLightImpact()
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text(project.emoji)
                            .font(.system(size: 14))
                        Text(project.name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundColor(theme.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
                
                // Screen indicator — clear text labels instead of confusing dots
                HStack(spacing: 2) {
                    screenTab("Input", screen: .input, theme: theme)
                    screenTab("Plan", screen: .plan, theme: theme)
                }
                .padding(3)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                theme.backgroundGradient.first?.opacity(0.95) ?? Color.clear
            )
            
            // ── Screen content
            ZStack {
                switch currentScreen {
                case .input:
                    InputScreen(
                        onStructured: {
                            withAnimation(.easeInOut(duration: 0.45)) {
                                currentScreen = .plan
                            }
                        },
                        project: project
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .leading)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                    
                case .plan:
                    PlanScreen(
                        onNewDump: {
                            withAnimation(.easeInOut(duration: 0.45)) {
                                currentScreen = .input
                            }
                        },
                        project: project
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .trailing))
                    ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            if hasExistingSession {
                currentScreen = .plan
            }
        }
    }
    
    @ViewBuilder
    private func screenTab(_ label: String, screen: WorkspaceScreen, theme: AuraTheme) -> some View {
        Button {
            HapticManager.shared.playLightImpact()
            withAnimation(.easeInOut(duration: 0.25)) {
                currentScreen = screen
            }
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(currentScreen == screen ? .white : theme.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    currentScreen == screen
                        ? Capsule().fill(theme.accent.opacity(0.35))
                        : Capsule().fill(Color.clear)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: currentScreen)
    }
}
