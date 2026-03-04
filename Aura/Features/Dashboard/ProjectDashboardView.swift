// ProjectDashboardView.swift

import SwiftUI
import SwiftData

struct ProjectDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UIState.self) private var uiState
    @Query(sort: \AuraProject.createdAt, order: .reverse) private var projects: [AuraProject]
    
    @State private var showNewProject = false
    @State private var selectedProject: AuraProject? = nil
    @State private var headerAppeared = false
    
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default:      return "Late Night"
        }
    }
    
    private var greetingIcon: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12:  return "sunrise.fill"
        case 12..<17: return "sun.max.fill"
        case 17..<22: return "moon.stars.fill"
        default:      return "moon.zzz.fill"
        }
    }
    
    private var totalTasks: Int { projects.reduce(0) { $0 + $1.totalTasks } }
    private var doneTasks:  Int { projects.reduce(0) { $0 + $1.completedTasks } }
    private var overallProgress: Double {
        totalTasks == 0 ? 0 : Double(doneTasks) / Double(totalTasks)
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
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // ── Hero header
                    heroHeader(theme: theme)
                    
                    VStack(spacing: 16) {
                        // ── Portfolio strip
                        if !projects.isEmpty {
                            portfolioStrip(theme: theme)
                                .padding(.top, 4)
                        }
                        
                        // ── Section title
                        if !projects.isEmpty {
                            HStack {
                                Text("PROJECTS")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(theme.secondaryText.opacity(0.5))
                                    .tracking(1.5)
                                Spacer()
                                Text("\(projects.count)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(theme.secondaryText.opacity(0.4))
                            }
                        }
                        
                        // ── Project cards
                        if projects.isEmpty {
                            emptyState(theme: theme)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(Array(projects.enumerated()), id: \.element.id) { idx, project in
                                    DashboardProjectCard(project: project, theme: theme, index: idx)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                selectedProject = project
                                            }
                                        }
                                }
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .sheet(isPresented: $showNewProject) {
            NewProjectSheet(theme: theme) { name, emoji, colorHex in
                let project = AuraProject(name: name, emoji: emoji, colorHex: colorHex)
                modelContext.insert(project)
                try? modelContext.save()
            }
        }
        .fullScreenCover(item: $selectedProject) { project in
            ProjectWorkspaceView(project: project)
        }
    }
    
    // MARK: - Hero Header
    
    @ViewBuilder
    private func heroHeader(theme: AuraTheme) -> some View {
        ZStack(alignment: .bottom) {
            // Subtle glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [theme.accent.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 180)
                .offset(y: 40)
                .blur(radius: 20)
            
            VStack(spacing: 0) {
                // Top bar
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 5) {
                            Image(systemName: greetingIcon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(theme.accent)
                            Text(greeting)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(theme.secondaryText)
                        }
                        Text("Aura")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, theme.accent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Spacer()
                    
                    Button {
                        showNewProject = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("New")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(theme.accent)
                                .shadow(color: theme.accent.opacity(0.4), radius: 8, y: 4)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Overall progress bar (if has projects)
                if !projects.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Overall Progress")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(theme.secondaryText.opacity(0.6))
                            Spacer()
                            Text("\(doneTasks) / \(totalTasks) tasks")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(theme.secondaryText.opacity(0.5))
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.06))
                                    .frame(height: 5)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: theme.ringGradient,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * overallProgress, height: 5)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: overallProgress)
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                } else {
                    Spacer().frame(height: 24)
                }
            }
        }
    }
    
    // MARK: - Portfolio Strip
    
    @ViewBuilder
    private func portfolioStrip(theme: AuraTheme) -> some View {
        HStack(spacing: 0) {
            stripStat(
                value: "\(projects.count)",
                label: "Projects",
                icon: "folder.fill",
                color: theme.accent
            )
            
            Rectangle()
                .fill(theme.secondaryText.opacity(0.08))
                .frame(width: 1, height: 36)
            
            stripStat(
                value: "\(totalTasks)",
                label: "Total Tasks",
                icon: "square.stack.fill",
                color: .orange
            )
            
            Rectangle()
                .fill(theme.secondaryText.opacity(0.08))
                .frame(width: 1, height: 36)
            
            stripStat(
                value: "\(doneTasks)",
                label: "Completed",
                icon: "checkmark.circle.fill",
                color: Color(red: 0.45, green: 0.85, blue: 0.55)
            )
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func stripStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private func emptyState(theme: AuraTheme) -> some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 30)
            
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.08))
                    .frame(width: 100, height: 100)
                Circle()
                    .stroke(theme.accent.opacity(0.12), lineWidth: 1)
                    .frame(width: 100, height: 100)
                Text("🧠")
                    .font(.system(size: 44))
            }
            
            VStack(spacing: 8) {
                Text("No projects yet")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Create your first project to start\norganizing your thoughts with Aura.")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            
            Button {
                showNewProject = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))
                    Text("Create First Project")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: theme.ringGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: theme.accent.opacity(0.35), radius: 12, y: 6)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Project Card

struct DashboardProjectCard: View {
    let project: AuraProject
    let theme: AuraTheme
    let index: Int
    
    @State private var appeared = false
    
    private var activeTasks: Int {
        project.allTasks.filter { $0.status != .done }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: emoji + ring
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(project.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(project.emoji)
                        .font(.system(size: 22))
                }
                
                Spacer()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: 3.5)
                    Circle()
                        .trim(from: 0, to: appeared ? project.progress : 0)
                        .stroke(
                            project.accentColor,
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(
                            .spring(response: 0.9, dampingFraction: 0.7)
                            .delay(Double(index) * 0.08),
                            value: appeared
                        )
                    Text("\(Int(project.progress * 100))%")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(project.accentColor)
                }
                .frame(width: 36, height: 36)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            
            Spacer().frame(height: 12)
            
            // Name
            Text(project.name)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding(.horizontal, 14)
            
            Spacer().frame(height: 8)
            
            // Stats row
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(project.totalTasks)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("tasks")
                        .font(.system(size: 9))
                        .foregroundColor(project.accentColor.opacity(0.7))
                }
                
                Spacer()
                
                if activeTasks > 0 {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 5, height: 5)
                        Text("\(activeTasks) active")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.orange.opacity(0.85))
                    }
                } else if project.totalTasks > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(red: 0.45, green: 0.85, blue: 0.55))
                        Text("All done")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(red: 0.45, green: 0.85, blue: 0.55).opacity(0.85))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            project.accentColor.opacity(0.13),
                            project.accentColor.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(project.accentColor.opacity(0.18), lineWidth: 1)
                )
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appeared = true
            }
        }
    }
}

// MARK: - New Project Sheet

struct NewProjectSheet: View {
    let theme: AuraTheme
    let onCreate: (String, String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedEmoji = "🧠"
    @State private var selectedColorHex = "8C7AFF"
    
    private let emojis = ["🧠","🚀","💡","🎯","📱","🔥","⚡️","🌊","🎨","📊","🏗️","🌱","💎","🛠️","📝"]
    
    private let colors: [(name: String, hex: String)] = [
        ("Violet", "8C7AFF"),
        ("Blue",   "4A90E2"),
        ("Teal",   "2EC4B6"),
        ("Green",  "72C35A"),
        ("Orange", "FF9F40"),
        ("Pink",   "FF6B9D"),
        ("Red",    "FF5A5F"),
        ("Gold",   "FFD166"),
    ]
    
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var selectedColor: Color { Color(hex: selectedColorHex) ?? theme.accent }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: theme.backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        
                        // Preview card
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(selectedColor.opacity(0.18))
                                    .frame(width: 56, height: 56)
                                Text(selectedEmoji)
                                    .font(.system(size: 28))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(name.isEmpty ? "Project Name" : name)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(name.isEmpty ? theme.secondaryText.opacity(0.4) : .white)
                                Text("New project")
                                    .font(.caption)
                                    .foregroundColor(selectedColor)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedColor.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedColor.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Name
                        field(label: "PROJECT NAME") {
                            TextField("e.g. App Redesign", text: $name)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.cardBackground)
                                )
                        }
                        
                        // Emoji
                        field(label: "ICON") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                                ForEach(emojis, id: \.self) { emoji in
                                    Button {
                                        selectedEmoji = emoji
                                    } label: {
                                        Text(emoji)
                                            .font(.title2)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(selectedEmoji == emoji
                                                        ? selectedColor.opacity(0.22)
                                                        : theme.cardBackground
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(selectedEmoji == emoji
                                                                ? selectedColor
                                                                : Color.clear, lineWidth: 1.5)
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Color
                        field(label: "COLOR") {
                            HStack(spacing: 12) {
                                ForEach(colors, id: \.hex) { item in
                                    Button {
                                        selectedColorHex = item.hex
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: item.hex) ?? .gray)
                                                .frame(width: 34, height: 34)
                                            if selectedColorHex == item.hex {
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2.5)
                                                    .frame(width: 34, height: 34)
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Create button
                        Button {
                            guard isValid else { return }
                            onCreate(name.trimmingCharacters(in: .whitespaces), selectedEmoji, selectedColorHex)
                            dismiss()
                        } label: {
                            Text("Create Project")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isValid ? selectedColor : theme.secondaryText.opacity(0.2))
                                        .shadow(color: isValid ? selectedColor.opacity(0.35) : .clear, radius: 10, y: 5)
                                )
                        }
                        .disabled(!isValid)
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(theme.secondaryText)
                }
            }
        }
    }
    
    @ViewBuilder
    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(theme.secondaryText.opacity(0.5))
                .tracking(1.5)
            content()
        }
    }
}
