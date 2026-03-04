// TaskRow.swift

import SwiftUI

struct TaskRow: View {
    let task: AuraTask
    let theme: AuraTheme
    let onToggle: () -> Void
    var onDelete: (() -> Void)? = nil
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    
    @State private var appeared = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var showDatePicker = false
    @State private var selectedDate: Date = .now
    
    var body: some View {
        mainContent
            .padding(.leading, 16)
            .padding(.trailing, onMoveUp != nil || onMoveDown != nil ? 8 : 16)
            .padding(.vertical, 14)
            .background(cardBackground)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(task.priority) * 0.04)) {
                    appeared = true
                }
            }
            .contextMenu { contextMenuContent }
            .sheet(isPresented: $isEditing) { editSheet }
            .sheet(isPresented: $showDatePicker) { datePickerSheet }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(task.title)
            .accessibilityValue(task.status == .done ? "Done" : "\(task.status.label), Priority \(task.priorityLevel.label)")
            .accessibilityHint(task.isMicroWin ? "Quick win task. Double tap to advance status." : "Double tap to advance status.")
            .accessibilityAction(named: "Advance Status") { onToggle() }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        HStack(spacing: 12) {
            statusButton
            taskContentColumn
            Spacer(minLength: 0)
            editButton
            reorderSidebar
        }
    }
    
    // MARK: - Status Button
    
    private var statusButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                onToggle()
            }
        }) {
            ZStack {
                Circle()
                    .stroke(statusColor, lineWidth: 1.5)
                    .frame(width: 28, height: 28)
                
                if task.status == .done {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 28, height: 28)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else if task.status == .inProgress {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
    }
    
    // MARK: - Task Content Column
    
    private var taskContentColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(
                    task.status == .done
                        ? theme.secondaryText.opacity(0.6)
                        : theme.primaryText
                )
                .strikethrough(task.status == .done, color: theme.secondaryText.opacity(0.4))
                .lineLimit(3)
                .onTapGesture {
                    if task.status != .done {
                        editedTitle = task.title
                        isEditing = true
                    }
                }
            
            badgeRow
        }
    }
    
    // MARK: - Badge Row
    
    private var badgeRow: some View {
        HStack(spacing: 6) {
            statusMenu
            priorityBadge
            categoryBadge
            microWinBadge
            subtaskBadge
            dueDateBadge
        }
    }
    
    private var statusMenu: some View {
        Menu {
            Button {
                withAnimation { task.status = .todo; task.completedAt = nil; task.startedAt = nil }
            } label: {
                Label("To Do", systemImage: task.status == .todo ? "checkmark" : "circle")
            }
            
            Button {
                withAnimation { task.status = .inProgress; task.startedAt = task.startedAt ?? .now }
            } label: {
                Label("In Progress", systemImage: task.status == .inProgress ? "checkmark" : "circle.lefthalf.filled")
            }
            
            Button {
                withAnimation { task.status = .done; task.completedAt = .now }
            } label: {
                Label("Done", systemImage: task.status == .done ? "checkmark" : "checkmark.circle")
            }
        } label: {
            HStack(spacing: 3) {
                Text(task.status.label.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                Image(systemName: "chevron.down")
                    .font(.system(size: 6, weight: .bold))
            }
            .foregroundColor(statusBadgeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(statusBadgeColor.opacity(0.12))
            )
        }
    }
    
    private var priorityBadge: some View {
        Text(task.priorityLevel.label)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundColor(task.priorityLevel.color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(task.priorityLevel.color.opacity(0.12))
            )
    }

    @ViewBuilder
    private var categoryBadge: some View {
        if let category = task.category {
            Text(category.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(theme.secondaryText.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(theme.secondaryText.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    @ViewBuilder
    private var microWinBadge: some View {
        if task.isMicroWin {
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 8))
                Text("QUICK WIN")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(theme.accent)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.accent.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private var subtaskBadge: some View {
        if let progress = task.subtaskProgress {
            HStack(spacing: 3) {
                Image(systemName: "checklist")
                    .font(.system(size: 8))
                Text(progress)
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(theme.secondaryText.opacity(0.7))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.secondaryText.opacity(0.08))
            )
        }
    }
    
    @ViewBuilder
    private var dueDateBadge: some View {
        if let due = task.dueDate, task.status != .done {
            let isOverdue = task.isOverdue
            let isDueToday = task.isDueToday
            let foreground: Color = isOverdue ? .red : isDueToday ? .orange : theme.secondaryText.opacity(0.7)
            let background: Color = isOverdue ? Color.red.opacity(0.12) : isDueToday ? Color.orange.opacity(0.1) : theme.secondaryText.opacity(0.08)
            
            HStack(spacing: 3) {
                Image(systemName: "clock")
                    .font(.system(size: 8))
                Text(dueDateLabel(due))
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(foreground)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(background)
            )
        }
    }
    
    // MARK: - Edit Button
    
    @ViewBuilder
    private var editButton: some View {
        if task.status != .done {
            Button {
                editedTitle = task.title
                isEditing = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryText.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Reorder Sidebar
    
    @ViewBuilder
    private var reorderSidebar: some View {
        if onMoveUp != nil || onMoveDown != nil {
            Rectangle()
                .fill(theme.secondaryText.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 4)
            
            VStack(spacing: 14) {
                if let onMoveUp {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onMoveUp()
                        }
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.accent)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.secondaryText.opacity(0.15))
                }
                
                if let onMoveDown {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onMoveDown()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.accent)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.secondaryText.opacity(0.15))
                }
            }
            .frame(width: 28)
        }
    }
    
    // MARK: - Card Background
    
    private var cardBackground: some View {
        let strokeColor: Color = task.isMicroWin
            ? theme.accent.opacity(0.15)
            : task.status == .inProgress
                ? Color.orange.opacity(0.12)
                : Color.white.opacity(0.04)
        
        return RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial.opacity(0.25))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(strokeColor, lineWidth: 1)
            )
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var contextMenuContent: some View {
        if task.status != .done {
            Button {
                editedTitle = task.title
                isEditing = true
            } label: {
                Label("Edit Title", systemImage: "pencil")
            }
            
            if task.status == .todo {
                Button {
                    withAnimation { task.status = .inProgress; task.startedAt = .now }
                } label: {
                    Label("Start Task", systemImage: "play.fill")
                }
            }
            
            Button {
                withAnimation { task.status = .done; task.completedAt = .now }
            } label: {
                Label("Mark Done", systemImage: "checkmark.circle.fill")
            }
            
            Button {
                selectedDate = task.dueDate ?? Calendar.current.date(byAdding: .day, value: 1, to: .now)!
                showDatePicker = true
            } label: {
                Label(task.dueDate == nil ? "Set Due Date" : "Change Due Date", systemImage: "calendar")
            }
            
            if task.dueDate != nil {
                Button(role: .destructive) {
                    task.dueDate = nil
                } label: {
                    Label("Remove Due Date", systemImage: "calendar.badge.minus")
                }
            }
        } else {
            Button {
                withAnimation { task.status = .todo; task.completedAt = nil }
            } label: {
                Label("Reopen Task", systemImage: "arrow.uturn.backward")
            }
        }
        
        if let onDelete {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Edit Sheet
    
    private var editSheet: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: theme.backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Edit Task")
                        .font(.headline)
                        .foregroundColor(theme.primaryText)
                    
                    TextField("Task title", text: $editedTitle)
                        .font(.body)
                        .foregroundColor(theme.primaryText)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                                )
                        )
                    
                    Button {
                        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            task.title = trimmed
                        }
                        isEditing = false
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: theme.ringGradient,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    
                    Spacer()
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                    }
                    .foregroundColor(theme.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Date Picker Sheet
    
    private var datePickerSheet: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: theme.backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Set Due Date")
                        .font(.headline)
                        .foregroundColor(theme.primaryText)
                    
                    DatePicker("Due", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(theme.accent)
                    
                    Button {
                        task.dueDate = selectedDate
                        showDatePicker = false
                    } label: {
                        Text("Set Date")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: theme.ringGradient,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showDatePicker = false
                    }
                    .foregroundColor(theme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        switch task.status {
        case .todo: return theme.secondaryText.opacity(0.5)
        case .inProgress: return .orange
        case .done: return theme.accent
        }
    }
    
    private var statusBadgeColor: Color {
        switch task.status {
        case .todo: return Color(red: 0.45, green: 0.55, blue: 0.75)
        case .inProgress: return .orange
        case .done: return Color(red: 0.45, green: 0.85, blue: 0.55)
        }
    }
    
    private func dueDateLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
