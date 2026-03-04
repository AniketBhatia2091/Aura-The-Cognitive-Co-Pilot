// PlanScreen.swift

import SwiftUI
import SwiftData

struct PlanScreen: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(UIState.self) private var uiState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @Query(sort: \BrainDumpSession.createdAt, order: .reverse)
    private var allSessions: [BrainDumpSession]
    
    var onNewDump: () -> Void
    var project: AuraProject? = nil
    
    @State private var focusModeEnabled: Bool = false
    @State private var isReordering: Bool = false
    @State private var showBoardView: Bool = false
    @State private var showAnalytics: Bool = false
    
    @State private var isResetting: Bool = false
    @State private var breathScale: CGFloat = 0.8
    @State private var breathOpacity: Double = 0.4
    
    @State private var showCelebration: Bool = false
    @State private var celebrationGlow: CGFloat = 0.3
    @State private var shimmerOffset: CGFloat = -200

    // Pre-computed particle data for completionCard — avoids random() in view body
    @State private var particleSizes: [CGFloat] = []
    @State private var particleOffsetsX: [CGFloat] = []
    @State private var particleOffsetsY: [CGFloat] = []
    
    private var currentSession: BrainDumpSession? {
        let sessions: [BrainDumpSession]
        if let project {
            sessions = allSessions.filter { $0.project?.id == project.id }
        } else {
            sessions = allSessions.filter { $0.project == nil }
        }
        return sessions.first(where: { $0.status == .active }) ?? sessions.first
    }
    
    private var activeTasks: [AuraTask] {
        guard let session = currentSession, session.status == .active else { return [] }
        return session.tasks
            .filter { $0.status != .done }
            .sorted(by: { $0.priority < $1.priority })
    }
    
    private var totalCount: Int { currentSession?.tasks.count ?? 0 }
    private var completedCount: Int { currentSession?.tasks.filter { $0.status == .done }.count ?? 0 }
    private var progress: Double { totalCount == 0 ? 0.0 : Double(completedCount) / Double(totalCount) }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default:      return "Late Night Mode"
        }
    }
    
    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "sunrise.fill"
        case 12..<17: return "sun.max.fill"
        case 17..<22: return "sunset.fill"
        default:      return "moon.stars.fill"
        }
    }
    
    private var dailyInsight: String {
        let todaySessions = allSessions.filter {
            Calendar.current.isDateInToday($0.createdAt)
        }
        let todayCompleted = todaySessions.filter { $0.status == .completed }.count
        let totalTasksDone = todaySessions.flatMap { $0.tasks }.filter { $0.status == .done }.count
        
        if todaySessions.isEmpty {
            return "This is your first session today. Let's make it count."
        } else if todayCompleted >= 3 {
            return "You've cleared \(todayCompleted) sessions today. Impressive focus."
        } else if totalTasksDone > 5 {
            return "\(totalTasksDone) tasks done today — you're building momentum."
        } else if totalTasksDone > 0 {
            return "\(totalTasksDone) task\(totalTasksDone == 1 ? "" : "s") completed today. Keep going."
        } else {
            return "Session \(todaySessions.count) today. Small steps, big clarity."
        }
    }
    
    var body: some View {
        let theme = uiState.theme
        let active = activeTasks.first
        
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    dashboardHeader(theme: theme)
                    
                    FocusRingView(
                        activeTask: active,
                        progress: progress,
                        theme: theme,
                        scalingFactor: uiState.sessionScalingFactor
                    )
                    
                    statsRow(theme: theme, completed: completedCount, total: totalCount)
                    
                    insightBanner(theme: theme)

                    focusModeToggle(theme: theme)
                    
                    if activeTasks.isEmpty && totalCount > 0 {
                        completionCard(theme: theme, completedCount: completedCount, totalCount: totalCount)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.9)),
                                removal: .opacity
                            ))
                    } else if activeTasks.isEmpty && totalCount == 0 {
                        emptyMindCard(theme: theme)
                    } else if focusModeEnabled && !showBoardView {
                        if let active {
                            singleTaskCard(task: active, theme: theme)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity
                                ))
                        }
                    } else {
                        taskList(theme: theme)
                    }
                    
                    actionButtons(theme: theme)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(
                LinearGradient(
                    colors: theme.backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            
            if isResetting {
                ZStack {
                    LinearGradient(
                        colors: theme.backgroundGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Image(systemName: "wind")
                            .font(.system(size: 80))
                            .foregroundColor(theme.accent)
                            .scaleEffect(breathScale)
                            .opacity(breathOpacity)
                        
                        Text("Clearing session...")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                            .opacity(breathOpacity)
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }
    
    @ViewBuilder
    private func dashboardHeader(theme: AuraTheme) -> some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: greetingIcon)
                            .font(.system(size: 14))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: theme.ringGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(greetingText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    Text("Your Plan")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundColor(theme.primaryText)
                }
                
                Spacer()
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(activeTasks.isEmpty ? Color(red: 0.45, green: 0.85, blue: 0.55) : theme.accent)
                        .frame(width: 6, height: 6)
                    
                    Text(activeTasks.isEmpty && totalCount > 0 ? "All Clear" : activeTasks.isEmpty ? "No Session" : "Active")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(theme.secondaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(theme.cardBackground)
                        .overlay(
                            Capsule()
                                .stroke(theme.accent.opacity(0.15), lineWidth: 1)
                        )
                )
                .padding(.top, 8)
            }
            
            HStack(spacing: 0) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.caption)
                    .foregroundColor(theme.secondaryText.opacity(0.7))
                
                Spacer()
            }
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func statsRow(theme: AuraTheme, completed: Int, total: Int) -> some View {
        HStack(spacing: 10) {
            premiumStatCard(
                title: "Total",
                value: total,
                icon: "list.bullet",
                iconGradient: theme.ringGradient,
                theme: theme
            )
            premiumStatCard(
                title: "Done",
                value: completed,
                icon: "checkmark.circle.fill",
                iconGradient: [Color(red: 0.45, green: 0.85, blue: 0.55), Color(red: 0.35, green: 0.78, blue: 0.98)],
                theme: theme
            )
            premiumStatCard(
                title: "Left",
                value: total - completed,
                icon: "hourglass",
                iconGradient: [Color(red: 1.0, green: 0.75, blue: 0.35), Color(red: 1.0, green: 0.55, blue: 0.45)],
                theme: theme
            )
        }
    }
    
    @ViewBuilder
    private func premiumStatCard(title: String, value: Int, icon: String, iconGradient: [Color], theme: AuraTheme) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: iconGradient.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: iconGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.primaryText)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
            
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [iconGradient.first?.opacity(0.12) ?? .clear, .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
    
    @ViewBuilder
    private func insightBanner(theme: AuraTheme) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: theme.ringGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Insight")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundColor(theme.accent)
                
                Text(dailyInsight)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.accent.opacity(0.08), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private func focusModeToggle(theme: AuraTheme) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(focusModeEnabled ? 0.15 : 0.08))
                    .frame(width: 36, height: 36)
                
                Image(systemName: focusModeEnabled ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 15))
                    .foregroundColor(theme.accent)
                    .contentTransition(.symbolEffect(.replace))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Focus Mode")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Text(focusModeEnabled ? "Showing one task only" : "One task at a time")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                    .animation(.easeInOut, value: focusModeEnabled)
            }
            
            Spacer()
            
            Toggle("", isOn: $focusModeEnabled)
                .toggleStyle(SwitchToggleStyle(tint: theme.accent))
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            focusModeEnabled ? theme.accent.opacity(0.25) : Color.clear,
                            lineWidth: 1
                        )
                        .animation(.easeInOut(duration: 0.3), value: focusModeEnabled)
                )
        )
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private func taskList(theme: AuraTheme) -> some View {
        VStack(spacing: 8) {
            HStack {
                // Board view dropdown
                Menu {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showBoardView = false
                        }
                    } label: {
                        Label("List View", systemImage: showBoardView ? "" : "checkmark")
                    }
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showBoardView = true
                            focusModeEnabled = false
                        }
                    } label: {
                        Label("Board View", systemImage: showBoardView ? "checkmark" : "")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showBoardView ? "rectangle.split.3x1" : "list.bullet")
                            .font(.caption2)
                        Text(showBoardView ? "Board" : "List")
                            .font(.caption2)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(theme.accent.opacity(0.1))
                    )
                }
                
                Spacer()
                
                if activeTasks.count > 1 && !showBoardView {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isReordering.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isReordering ? "checkmark" : "arrow.up.arrow.down")
                                .font(.caption2)
                            Text(isReordering ? "Done" : "Reorder")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(theme.accent.opacity(isReordering ? 0.2 : 0.1))
                        )
                    }
                }
            }
            .padding(.bottom, 4)
            
            if showBoardView {
                if let session = currentSession {
                    BoardView(tasks: session.tasks, theme: theme)
                        .transition(.opacity)
                }
            } else {
                let tasks = activeTasks
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    TaskRow(
                        task: task,
                        theme: theme,
                        onToggle: {
                            if task.status == .done {
                                task.status = .todo
                                task.completedAt = nil
                            } else {
                                complete(task: task)
                            }
                        },
                        onDelete: { deleteTask(task) },
                        onMoveUp: isReordering && index > 0 ? { moveTask(from: index, direction: -1) } : nil,
                        onMoveDown: isReordering && index < tasks.count - 1 ? { moveTask(from: index, direction: 1) } : nil
                    )
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap")
                        .font(.caption2)
                    Text("Long press for options · Tap title to edit")
                        .font(.caption2)
                }
                .foregroundColor(theme.secondaryText.opacity(0.4))
                .padding(.top, 6)
            }
        }
    }
    
    private func moveTask(from index: Int, direction: Int) {
        var tasks = activeTasks
        let newIndex = index + direction
        guard newIndex >= 0, newIndex < tasks.count else { return }
        
        tasks.swapAt(index, newIndex)
        for (i, t) in tasks.enumerated() {
            t.priority = i + 1
        }
        try? modelContext.save()
    }
    
    private func deleteTask(_ task: AuraTask) {
        modelContext.delete(task)
        try? modelContext.save()
        checkSessionCompletion()
    }
    
    @ViewBuilder
    private func singleTaskCard(task: AuraTask, theme: AuraTheme) -> some View {
        VStack(spacing: 20) {
            Text(task.isMicroWin ? "Micro Win Mode" : "Current Focus")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundColor(task.isMicroWin ? theme.accent : theme.secondaryText)
            
            Text(task.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            if task.isMicroWin {
                Text("Let's start with a short win. You're moving.")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    complete(task: task)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Mark Complete")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(theme.accent)
                )
            }
            .accessibilityLabel("Mark \(task.title) Complete")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
    }
    
    private var completionQuotes: [String] {
        [
            "Clarity earned. You showed up for yourself.",
            "Every thought tamed is a step toward peace.",
            "From chaos to calm — that's real strength.",
            "Your mind is lighter now. Well done.",
            "Small wins compound. You're proof."
        ]
    }
    
    @ViewBuilder
    private func completionCard(theme: AuraTheme, completedCount: Int, totalCount: Int) -> some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(theme.ringGradient[i % theme.ringGradient.count].opacity(0.08))
                        .frame(width: particleSizes.indices.contains(i) ? particleSizes[i] : 30)
                        .offset(
                            x: particleOffsetsX.indices.contains(i) ? particleOffsetsX[i] : 0,
                            y: particleOffsetsY.indices.contains(i) ? particleOffsetsY[i] : 0
                        )
                        .blur(radius: 6)
                        .opacity(showCelebration ? 0.8 : 0.0)
                        .animation(
                            .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.3),
                            value: showCelebration
                        )
                }
                
                Circle()
                    .fill(theme.accent.opacity(celebrationGlow * 0.3))
                    .frame(width: 100, height: 100)
                    .blur(radius: 25)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: theme.ringGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating, isActive: showCelebration)
            }

            .frame(height: 100)
            .accessibilityHidden(true)
            
            Text("Session Complete")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("\(completedCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.45, green: 0.85, blue: 0.55), Color(red: 0.35, green: 0.78, blue: 0.98)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Tasks Done")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(theme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                
                if let session = currentSession, let completed = session.completedAt {
                    Rectangle()
                        .fill(theme.accent.opacity(0.15))
                        .frame(width: 1, height: 36)
                    
                    VStack(spacing: 4) {
                        Text(sessionDuration(from: session.createdAt, to: completed))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: theme.ringGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("Duration")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
            
            Text(completionQuotes[completedCount % completionQuotes.count])
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .italic()
            

            HStack(spacing: 10) {
                Rectangle()
                    .fill(theme.accent.opacity(0.12))
                    .frame(height: 1)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 9))
                    .foregroundColor(theme.accent.opacity(0.4))
                
                Rectangle()
                    .fill(theme.accent.opacity(0.12))
                    .frame(height: 1)
            }
            .padding(.horizontal, 24)
            
            Text("Your mind is clear. Enjoy the calm.")
                .font(.caption)
                .foregroundColor(theme.secondaryText.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.accent.opacity(0.12), lineWidth: 1)
                )
        )
        .onAppear {
            // Seed particle positions once so random() never runs in the view body
            if particleSizes.isEmpty {
                particleSizes   = (0..<5).map { _ in CGFloat.random(in: 20...50) }
                particleOffsetsX = (0..<5).map { _ in CGFloat.random(in: -60...60) }
                particleOffsetsY = (0..<5).map { _ in CGFloat.random(in: -50...50) }
            }
            showCelebration = true
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                celebrationGlow = 1.0
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private func emptyMindCard(theme: AuraTheme) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.accent.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.45, green: 0.85, blue: 0.55), theme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .accessibilityHidden(true)
            
            Text("Mind is Clear")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            Text("You have no active tasks. Take a breath.")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
        )
        .accessibilityElement(children: .combine)
    }
    
    private func sessionDuration(from start: Date, to end: Date) -> String {
        let interval = Int(end.timeIntervalSince(start))
        if interval < 60 {
            return "\(interval)s"
        } else if interval < 3600 {
            return "\(interval / 60)m"
        } else {
            let h = interval / 3600
            let m = (interval % 3600) / 60
            return "\(h)h \(m)m"
        }
    }
    
    @ViewBuilder
    private func actionButtons(theme: AuraTheme) -> some View {
        VStack(spacing: 12) {
            Button(action: onNewDump) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Brain Dump")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: theme.ringGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .accessibilityLabel("New Brain Dump")
            
            Button {
                showAnalytics = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 13))
                    Text("Analytics")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showAnalytics) {
                AnalyticsView(project: project)
            }
            
            Button {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isResetting = true
                }
                
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        breathScale = 1.3
                        breathOpacity = 1.0
                    }
                } else {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        breathOpacity = 1.0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if let session = currentSession, session.status == .active {
                        session.status = .completed
                        session.completedAt = .now
                        
                        session.tasks.filter { $0.status != .done }.forEach {
                            $0.status = .done
                            $0.completedAt = .now
                        }
                        
                        try? modelContext.save()
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    onNewDump()
                }
            } label: {
                Text("Reset Mind")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.secondaryText)
                    .padding(.vertical, 8)
            }
            .padding(.top, 8)
            .accessibilityLabel("Reset Mind")
            .accessibilityHint("Clears the session and gently returns to the input screen")
        }
    }
    
    private func complete(task: AuraTask) {
        task.status = .done
        task.completedAt = .now
        checkSessionCompletion()
    }
    
    private func advanceStatus(task: AuraTask) {
        switch task.status {
        case .todo:
            task.status = .inProgress
            task.startedAt = .now
        case .inProgress:
            task.status = .done
            task.completedAt = .now
        case .done:
            task.status = .todo
            task.completedAt = nil
            task.startedAt = nil
        }
        checkSessionCompletion()
    }
    
    private func checkSessionCompletion() {
        guard let session = currentSession else { return }
        
        let allDone = session.tasks.allSatisfy {
            $0.status == .done
        }
        
        if allDone, session.status != .completed {
            session.status = .completed
            session.completedAt = .now
            try? modelContext.save()

            // Persist daily session count so sessionScalingFactor activates correctly
            let key = "sessionsCompletedToday"
            let calendar = Calendar.current
            let lastDateKey = "sessionsCompletedDate"
            let lastDateStored = UserDefaults.standard.object(forKey: lastDateKey) as? Date
            let isToday = lastDateStored.map { calendar.isDateInToday($0) } ?? false
            let current = isToday ? UserDefaults.standard.integer(forKey: key) : 0
            UserDefaults.standard.set(current + 1, forKey: key)
            UserDefaults.standard.set(Date.now, forKey: lastDateKey)
            uiState.sessionsCompletedToday = UserDefaults.standard.integer(forKey: key)
        }
    }
}
