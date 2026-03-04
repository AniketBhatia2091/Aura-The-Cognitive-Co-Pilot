// ReflectionLogView.swift

import SwiftUI
import SwiftData

struct ReflectionLogView: View {
    @Query(sort: \BrainDumpSession.createdAt, order: .reverse)
    private var allSessions: [BrainDumpSession]
    
    @Environment(UIState.self) private var uiState
    @Environment(\.dismiss) private var dismiss
    
    var project: AuraProject? = nil
    
    private var completedSessions: [BrainDumpSession] {
        let sessions = project.map { p in allSessions.filter { $0.project?.id == p.id } } ?? allSessions
        return sessions.filter { $0.status == .completed }
    }
    
    var body: some View {
        let theme = uiState.theme
        ZStack {
            LinearGradient(
                colors: theme.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if completedSessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(theme.secondaryText)
                    Text("Nothing left for now.")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(completedSessions) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                sessionCard(session: session, theme: theme)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Reflection Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.secondaryText)
                        .font(.body)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sessionCard(session: BrainDumpSession, theme: AuraTheme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.secondaryText)
                
                Spacer()
                
                Text("\(session.tasks.count) tasks")
                    .font(.caption2)
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(theme.accent.opacity(0.15)))
            }
            
            let snippet = String(session.rawText.prefix(60))
            Text(snippet + (session.rawText.count > 60 ? "..." : ""))
                .font(.subheadline)
                .foregroundColor(theme.primaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            if let completed = session.completedAt {
                Text("Completed: \(completed.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryText.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.accent.opacity(0.1), lineWidth: 1)
        )
    }
}
