// SessionDetailView.swift

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: BrainDumpSession
    @Environment(UIState.self) private var uiState
    
    var body: some View {
        let theme = uiState.theme
        ZStack {
            LinearGradient(
                colors: theme.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Original Thought")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .textCase(.uppercase)
                            .tracking(1.5)
                            .foregroundColor(theme.secondaryText)
                        
                        Text(session.rawText)
                            .font(.body)
                            .foregroundColor(theme.primaryText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.cardBackground)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Extracted Tasks")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .textCase(.uppercase)
                            .tracking(1.5)
                            .foregroundColor(theme.secondaryText)
                        
                        let sortedTasks = session.tasks.sorted(by: { $0.priority < $1.priority })
                        
                        ForEach(sortedTasks) { task in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.accent.opacity(0.6))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.subheadline)
                                        .foregroundColor(theme.primaryText.opacity(0.6))
                                        .strikethrough(true)
                                    
                                    if let completedAt = task.completedAt {
                                        Text(completedAt.formatted(date: .omitted, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(theme.secondaryText)
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.cardBackground)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(session.createdAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }
}
