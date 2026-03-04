// AnalyticsView.swift

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(UIState.self) private var uiState
    
    @Query(sort: \BrainDumpSession.createdAt, order: .reverse)
    private var allSessions: [BrainDumpSession]
    
    var project: AuraProject? = nil
    
    private var sessions: [BrainDumpSession] {
        if let project {
            return allSessions.filter { $0.project?.id == project.id }
        }
        return allSessions
    }
    
    private var theme: AuraTheme { uiState.theme }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: theme.backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        
                        if sessions.isEmpty {
                            emptyState
                        } else {
                            summaryCards
                            tasksCompletedChart
                            cognitiveLoadChart
                            categoryBreakdown
                            sessionHistoryList
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.accent)
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.ringGradient.map { $0.opacity(0.15) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: theme.ringGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Analytics")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundColor(theme.primaryText)
                    
                    Text("Your cognitive wellness at a glance")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.accent.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: theme.ringGradient.map { $0.opacity(0.4) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("No sessions yet")
                .font(.headline)
                .foregroundColor(theme.secondaryText)
            
            Text("Complete a brain dump session to see\nyour analytics here.")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    private var summaryCards: some View {
        let totalSessions = sessions.count
        let completedSessions = sessions.filter { $0.status == .completed }.count
        let allTasks = sessions.flatMap { $0.tasks }
        let completedTasks = allTasks.filter { $0.status == .done }.count
        let avgLoad = sessions.isEmpty ? 0 : (sessions.map(\.initialLoadScore).reduce(0, +) / sessions.count) / 10
        let completionRate = allTasks.isEmpty ? 0 : Int(Double(completedTasks) / Double(allTasks.count) * 100)
        
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 10) {
            AnalyticsStatCard(
                icon: "brain",
                title: "Sessions",
                value: "\(totalSessions)",
                subtitle: "\(completedSessions) completed",
                iconGradient: theme.ringGradient,
                theme: theme
            )
            
            AnalyticsStatCard(
                icon: "checkmark.circle.fill",
                title: "Tasks Done",
                value: "\(completedTasks)",
                subtitle: "of \(allTasks.count) total",
                iconGradient: [Color(red: 0.45, green: 0.85, blue: 0.55), Color(red: 0.35, green: 0.78, blue: 0.98)],
                theme: theme
            )
            
            AnalyticsStatCard(
                icon: "gauge.medium",
                title: "Avg Load",
                value: "\(avgLoad)/10",
                subtitle: loadLabel(avgLoad),
                iconGradient: loadGradient(avgLoad),
                theme: theme
            )
            
            AnalyticsStatCard(
                icon: "target",
                title: "Completion",
                value: "\(completionRate)%",
                subtitle: completionRate >= 80 ? "excellent" : completionRate >= 50 ? "good progress" : "building up",
                iconGradient: completionRate >= 80
                    ? [Color(red: 0.45, green: 0.85, blue: 0.55), Color(red: 0.35, green: 0.78, blue: 0.98)]
                    : [Color(red: 1.0, green: 0.75, blue: 0.35), Color(red: 1.0, green: 0.55, blue: 0.45)],
                theme: theme
            )
        }
    }
    
    private var tasksCompletedChart: some View {
        let data = tasksPerDay()
        
        return chartCard(title: "Tasks Completed", icon: "chart.bar.fill") {
            if data.isEmpty {
                noDataPlaceholder
            } else {
                Chart(data, id: \.date) { entry in
                    BarMark(
                        x: .value("Day", entry.date, unit: .day),
                        y: .value("Tasks", entry.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: theme.ringGradient,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(5)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .foregroundStyle(theme.secondaryText)
                        AxisGridLine()
                            .foregroundStyle(theme.secondaryText.opacity(0.08))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(theme.secondaryText)
                        AxisGridLine()
                            .foregroundStyle(theme.secondaryText.opacity(0.08))
                    }
                }
                .frame(height: 180)
                .padding(.top, 4)
            }
        }
    }
    
    private var cognitiveLoadChart: some View {
        let data = loadOverTime()
        
        return chartCard(title: "Cognitive Load Trend", icon: "waveform.path.ecg") {
            if data.isEmpty {
                noDataPlaceholder
            } else {
                let sameDay = isSameDay(data)
                
                Chart(data, id: \.date) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Load", entry.score)
                    )
                    .foregroundStyle(theme.accent)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    
                    AreaMark(
                        x: .value("Date", entry.date),
                        y: .value("Load", entry.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accent.opacity(0.25), theme.accent.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Load", entry.score)
                    )
                    .foregroundStyle(theme.accent)
                    .symbolSize(30)
                }
                .chartYScale(domain: 0...10)
                .chartXAxis {
                    AxisMarks(preset: .aligned, values: .automatic(desiredCount: 4)) { _ in
                        if sameDay {
                            AxisValueLabel(format: .dateTime.hour().minute())
                                .foregroundStyle(theme.secondaryText)
                        } else {
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(theme.secondaryText)
                        }
                        AxisGridLine()
                            .foregroundStyle(theme.secondaryText.opacity(0.08))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 2, 4, 6, 8, 10]) { _ in
                        AxisValueLabel()
                            .foregroundStyle(theme.secondaryText)
                        AxisGridLine()
                            .foregroundStyle(theme.secondaryText.opacity(0.08))
                    }
                }
                .frame(height: 180)
                .padding(.top, 4)
                .padding(.trailing, 4)
            }
        }
    }
    
    private var categoryBreakdown: some View {
        let data = categoryData()
        
        return chartCard(title: "Task Categories", icon: "circle.hexagongrid") {
            if data.isEmpty {
                noDataPlaceholder
            } else {
                HStack(spacing: 20) {
                    Chart(data, id: \.category) { entry in
                        SectorMark(
                            angle: .value("Count", entry.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(entry.color)
                        .cornerRadius(4)
                    }
                    .frame(width: 130, height: 130)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(data, id: \.category) { entry in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(entry.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(entry.category)
                                    .font(.caption)
                                    .foregroundColor(theme.primaryText)
                                
                                Spacer()
                                
                                Text("\(entry.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.secondaryText)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var sessionHistoryList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Sessions")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Text("\(sessions.count) total")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            ForEach(Array(sessions.prefix(5)), id: \.id) { session in
                let completed = session.tasks.filter { $0.status == .done }.count
                let total = session.tasks.count
                let rate = total > 0 ? Double(completed) / Double(total) : 0
                
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(
                                    session.status == .completed
                                        ? Color(red: 0.45, green: 0.85, blue: 0.55).opacity(0.3)
                                        : theme.accent.opacity(0.2),
                                    lineWidth: 2
                                )
                                .frame(width: 28, height: 28)
                            
                            Circle()
                                .trim(from: 0, to: rate)
                                .stroke(
                                    session.status == .completed
                                        ? Color(red: 0.45, green: 0.85, blue: 0.55)
                                        : theme.accent,
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                )
                                .frame(width: 28, height: 28)
                                .rotationEffect(.degrees(-90))
                            
                            Image(systemName: session.status == .completed ? "checkmark" : "circle.fill")
                                .font(.system(size: session.status == .completed ? 10 : 5, weight: .bold))
                                .foregroundColor(
                                    session.status == .completed
                                        ? Color(red: 0.45, green: 0.85, blue: 0.55)
                                        : theme.accent
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(theme.primaryText)
                            
                            HStack(spacing: 6) {
                                Text("\(total) tasks")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryText)
                                
                                Circle()
                                    .fill(theme.secondaryText.opacity(0.3))
                                    .frame(width: 3, height: 3)
                                
                                Text("Load: \(min(session.initialLoadScore / 10, 10))/10")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryText)
                                
                                if let completedAt = session.completedAt {
                                    Circle()
                                        .fill(theme.secondaryText.opacity(0.3))
                                        .frame(width: 3, height: 3)
                                    
                                    Text(sessionDuration(from: session.createdAt, to: completedAt))
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryText)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Text(total > 0 ? "\(Int(rate * 100))%" : "—")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(session.status == .completed
                                             ? Color(red: 0.45, green: 0.85, blue: 0.55)
                                             : theme.secondaryText)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    session.status == .completed
                                        ? Color(red: 0.45, green: 0.85, blue: 0.55).opacity(0.08)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )
            }
        }
    }
    
    @ViewBuilder
    private func chartCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(theme.accent)
                Text(title)
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
            }
            
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(theme.accent.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private var noDataPlaceholder: some View {
        Text("Not enough data yet")
            .font(.caption)
            .foregroundColor(theme.secondaryText.opacity(0.5))
            .frame(height: 100)
            .frame(maxWidth: .infinity)
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
    
    private func tasksPerDay() -> [(date: Date, count: Int)] {
        let allTasks = sessions.flatMap { $0.tasks }
        let completed = allTasks.filter { $0.status == .done && $0.completedAt != nil }
        
        let calendar = Calendar.current
        var grouped: [Date: Int] = [:]
        
        for task in completed {
            if let date = task.completedAt {
                let day = calendar.startOfDay(for: date)
                grouped[day, default: 0] += 1
            }
        }
        
        return grouped.map { (date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
            .suffix(7)
            .map { $0 }
    }
    
    private func loadOverTime() -> [(date: Date, score: Int)] {
        return sessions
            .sorted { $0.createdAt < $1.createdAt }
            .suffix(10)
            .map { (date: $0.createdAt, score: min($0.initialLoadScore / 10, 10)) }
    }
    
    private func isSameDay(_ data: [(date: Date, score: Int)]) -> Bool {
        guard let first = data.first else { return true }
        let cal = Calendar.current
        return data.allSatisfy { cal.isDate($0.date, inSameDayAs: first.date) }
    }
    
    private func categoryData() -> [(category: String, count: Int, color: Color)] {
        let allTasks = sessions.flatMap { $0.tasks }
        var counts: [String: Int] = [:]
        
        for task in allTasks {
            let cat = task.category ?? "Uncategorized"
            counts[cat, default: 0] += 1
        }
        
        let colors: [String: Color] = [
            "Academic": Color(red: 0.55, green: 0.48, blue: 1.0),
            "Work": Color(red: 0.35, green: 0.78, blue: 0.98),
            "Personal": Color(red: 0.45, green: 0.85, blue: 0.55),
            "Wellness": Color(red: 0.85, green: 0.65, blue: 1.0),
            "Uncategorized": Color.white.opacity(0.3)
        ]
        
        return counts
            .sorted { $0.value > $1.value }
            .map { (category: $0.key, count: $0.value, color: colors[$0.key] ?? .gray) }
    }
    
    private func loadLabel(_ score: Int) -> String {
        switch score {
        case 0...3: return "manageable"
        case 4...6: return "moderate"
        default: return "intense"
        }
    }
    
    private func loadGradient(_ score: Int) -> [Color] {
        switch score {
        case 0...3: return [Color(red: 0.45, green: 0.85, blue: 0.55), Color(red: 0.35, green: 0.78, blue: 0.98)]
        case 4...6: return [Color(red: 1.0, green: 0.75, blue: 0.35), Color(red: 1.0, green: 0.45, blue: 0.45)]
        default: return [Color(red: 1.0, green: 0.45, blue: 0.45), Color(red: 0.85, green: 0.2, blue: 0.2)]
        }
    }
}

private struct AnalyticsStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let iconGradient: [Color]
    let theme: AuraTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: iconGradient.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                
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
            
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryText)
                
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .foregroundColor(theme.secondaryText)
            }
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(theme.secondaryText.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [iconGradient.first?.opacity(0.1) ?? .clear, .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}
