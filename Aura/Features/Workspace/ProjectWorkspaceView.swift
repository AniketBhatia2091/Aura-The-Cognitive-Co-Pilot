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
            // ── Modern top bar
            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                        Text(project.emoji)
                            .font(.system(size: 13))
                        Text(project.name)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.9), project.accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(project.accentColor.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(project.accentColor.opacity(0.22), lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
                
                // Current screen indicator dots
                HStack(spacing: 5) {
                    Circle()
                        .fill(currentScreen == .input ? .white : .white.opacity(0.2))
                        .frame(width: 5, height: 5)
                    Circle()
                        .fill(currentScreen == .plan ? .white : .white.opacity(0.2))
                        .frame(width: 5, height: 5)
                }
                .animation(.easeInOut(duration: 0.25), value: currentScreen)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack(alignment: .bottom) {
                    (theme.backgroundGradient.first ?? .clear).opacity(0.98)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [project.accentColor.opacity(0.4), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                }
            )
            
            // ── Screen content
            ZStack {
                switch currentScreen {
                case .input:
                    InputScreen(
                        onStructured: {
                            withAnimation(.easeInOut(duration: 0.5)) {
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
                            withAnimation(.easeInOut(duration: 0.5)) {
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
}
