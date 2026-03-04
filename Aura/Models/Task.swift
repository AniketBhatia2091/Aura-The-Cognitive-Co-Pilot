// Task.swift

import Foundation
import SwiftData
import SwiftUI

enum TaskStatus: String, Codable, CaseIterable {
    case todo = "active"
    case inProgress = "inProgress"
    case done = "completed"
    
    var label: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        }
    }
    
    var icon: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .done: return "checkmark.circle.fill"
        }
    }
    
    var next: TaskStatus {
        switch self {
        case .todo: return .inProgress
        case .inProgress: return .done
        case .done: return .todo
        }
    }
}

enum PriorityLevel: String, Codable, CaseIterable {
    case critical
    case high
    case medium
    case low
    
    var label: String {
        switch self {
        case .critical: return "CRITICAL"
        case .high: return "HIGH"
        case .medium: return "MED"
        case .low: return "LOW"
        }
    }
    
    var color: Color {
        switch self {
        case .critical: return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .high: return Color(red: 1.0, green: 0.65, blue: 0.30)
        case .medium: return Color(red: 1.0, green: 0.85, blue: 0.35)
        case .low: return Color(red: 0.45, green: 0.85, blue: 0.55)
        }
    }
    
    static func from(priority: Int) -> PriorityLevel {
        switch priority {
        case 1...2: return .critical
        case 3...4: return .high
        case 5...6: return .medium
        default: return .low
        }
    }
}

enum SessionStatus: String, Codable {
    case active
    case completed
}

/// A structured session retaining the original chaotic thought process.
@Model
final class BrainDumpSession {
    var id: UUID
    var rawText: String
    var createdAt: Date
    var completedAt: Date?
    var status: SessionStatus
    var initialLoadScore: Int
    var project: AuraProject?
    
    @Relationship(deleteRule: .cascade, inverse: \AuraTask.session)
    var tasks: [AuraTask]
    
    init(rawText: String, initialLoadScore: Int, project: AuraProject? = nil) {
        self.id = UUID()
        self.rawText = rawText
        self.createdAt = .now
        self.status = .active
        self.initialLoadScore = initialLoadScore
        self.project = project
        self.tasks = []
    }
}

/// A single micro-task that the user needs to accomplish.
@Model
final class AuraTask {
    var id: UUID
    var title: String
    var priority: Int
    var status: TaskStatus
    var category: String?
    var isMicroWin: Bool
    var createdAt: Date
    var completedAt: Date?
    var startedAt: Date?
    var dueDate: Date?
    var subtasks: [String]?
    var subtasksDone: [Bool]?
    
    var session: BrainDumpSession?
    
    var priorityLevel: PriorityLevel {
        PriorityLevel.from(priority: priority)
    }
    
    var subtaskProgress: String? {
        guard let subs = subtasks, !subs.isEmpty else { return nil }
        let done = (subtasksDone ?? []).filter { $0 }.count
        return "\(done)/\(subs.count)"
    }
    
    var isOverdue: Bool {
        guard let due = dueDate else { return false }
        return due < .now && status != .done
    }
    
    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }
    
    init(title: String, priority: Int, category: String? = nil, isMicroWin: Bool = false, session: BrainDumpSession? = nil) {
        self.id = UUID()
        self.title = title
        self.priority = priority
        self.status = .todo
        self.category = category
        self.isMicroWin = isMicroWin
        self.createdAt = .now
        self.subtasks = []
        self.subtasksDone = []
        self.session = session
    }
}
