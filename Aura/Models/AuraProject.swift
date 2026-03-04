// AuraProject.swift

import Foundation
import SwiftData
import SwiftUI

@Model
final class AuraProject {
    var id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \BrainDumpSession.project)
    var sessions: [BrainDumpSession]
    
    init(name: String, emoji: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.createdAt = .now
        self.sessions = []
    }
    
    var allTasks: [AuraTask] {
        sessions.flatMap { $0.tasks }
    }
    
    var totalTasks: Int { allTasks.count }
    
    var completedTasks: Int {
        allTasks.filter { $0.status == .done }.count
    }
    
    var progress: Double {
        totalTasks == 0 ? 0.0 : Double(completedTasks) / Double(totalTasks)
    }
    
    var lastActiveAt: Date? {
        sessions.map { $0.createdAt }.max()
    }
    
    var accentColor: Color {
        Color(hex: colorHex) ?? Color(red: 0.55, green: 0.48, blue: 1.0)
    }
}

// MARK: - Color hex helper
extension Color {
    init?(hex: String) {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("#") { str.removeFirst() }
        guard str.count == 6, let value = UInt64(str, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
