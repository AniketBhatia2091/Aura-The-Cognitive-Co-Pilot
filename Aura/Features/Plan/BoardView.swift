// BoardView.swift

import SwiftUI

struct BoardView: View {
    let tasks: [AuraTask]
    let theme: AuraTheme
    
    @State private var selectedColumn: TaskStatus = .todo
    
    private func tasksFor(_ status: TaskStatus) -> [AuraTask] {
        tasks.filter { $0.status == status }
            .sorted { $0.priority < $1.priority }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Column tabs
            HStack(spacing: 0) {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    let count = tasksFor(status).count
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedColumn = status
                        }
                    } label: {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: statusIcon(status))
                                    .font(.system(size: 10, weight: .semibold))
                                Text(status.label.uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                            }
                            
                            Text("\(count)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(selectedColumn == status ? .white : theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedColumn == status ? statusColor(status) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.secondaryText.opacity(0.06), lineWidth: 1)
                    )
            )
            
            // Task cards for selected column
            let columnTasks = tasksFor(selectedColumn)
            
            if columnTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: emptyIcon(selectedColumn))
                        .font(.system(size: 28))
                        .foregroundColor(theme.secondaryText.opacity(0.2))
                    Text(emptyMessage(selectedColumn))
                        .font(.caption)
                        .foregroundColor(theme.secondaryText.opacity(0.4))
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(.vertical, 8)
            } else {
                ForEach(columnTasks) { task in
                    boardCard(task: task)
                }
            }
        }
    }
    
    @ViewBuilder
    private func boardCard(task: AuraTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row
            HStack(alignment: .top) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(
                        task.status == .done
                            ? theme.secondaryText.opacity(0.6)
                            : theme.primaryText
                    )
                    .strikethrough(task.status == .done, color: theme.secondaryText.opacity(0.3))
                    .lineLimit(3)
                
                Spacer(minLength: 8)
                
                // Priority badge
                Text(task.priorityLevel.label)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(task.priorityLevel.color)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(task.priorityLevel.color.opacity(0.12))
                    )
            }
            
            // Bottom row: metadata + move buttons
            HStack(spacing: 6) {
                if let cat = task.category {
                    Text(cat.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(theme.secondaryText.opacity(0.6))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(theme.secondaryText.opacity(0.15), lineWidth: 0.5)
                        )
                }
                
                if task.isOverdue {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 8))
                        Text("Overdue")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(.red)
                } else if let due = task.dueDate {
                    Text(shortDate(due))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(task.isDueToday ? .orange : theme.secondaryText.opacity(0.5))
                }
                
                Spacer()
                
                // Move buttons — tap to change status
                if task.status != .todo {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            let prev = previousStatus(task.status)
                            task.status = prev
                            if prev == .todo { task.startedAt = nil; task.completedAt = nil }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 8, weight: .bold))
                            Text(previousStatus(task.status).label)
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(statusColor(previousStatus(task.status)))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusColor(previousStatus(task.status)).opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                if task.status != .done {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            let next = nextStatus(task.status)
                            task.status = next
                            if next == .inProgress { task.startedAt = task.startedAt ?? .now }
                            if next == .done { task.completedAt = .now }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text(nextStatus(task.status).label)
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(statusColor(nextStatus(task.status)))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusColor(nextStatus(task.status)).opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            task.status == .inProgress
                                ? Color.orange.opacity(0.15)
                                : theme.secondaryText.opacity(0.06),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // Helpers
    
    private func statusIcon(_ status: TaskStatus) -> String {
        switch status {
        case .todo: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .done: return "checkmark.circle.fill"
        }
    }
    
    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .todo: return Color(red: 0.45, green: 0.55, blue: 0.75)
        case .inProgress: return .orange
        case .done: return Color(red: 0.45, green: 0.85, blue: 0.55)
        }
    }
    
    private func nextStatus(_ status: TaskStatus) -> TaskStatus {
        switch status {
        case .todo: return .inProgress
        case .inProgress: return .done
        case .done: return .done
        }
    }
    
    private func previousStatus(_ status: TaskStatus) -> TaskStatus {
        switch status {
        case .todo: return .todo
        case .inProgress: return .todo
        case .done: return .inProgress
        }
    }
    
    private func emptyIcon(_ status: TaskStatus) -> String {
        switch status {
        case .todo: return "tray"
        case .inProgress: return "play.slash"
        case .done: return "checkmark.seal"
        }
    }
    
    private func emptyMessage(_ status: TaskStatus) -> String {
        switch status {
        case .todo: return "No tasks to do"
        case .inProgress: return "Nothing in progress"
        case .done: return "Nothing completed yet"
        }
    }
    
    private func shortDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: date)
    }
}
