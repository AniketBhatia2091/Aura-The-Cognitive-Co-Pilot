// InputLogic.swift

import SwiftUI
import Observation

/// ViewModel for the Brain Dump input screen.
///
/// The parser is designed for real brain dumps — messy, mixed text that
/// might contain todo lists, thoughts, feelings, and random observations.
/// It extracts only *actionable* fragments and discards narrative prose.
@Observable
@MainActor
final class InputLogic {
    
    var rawText: String = ""
    var parsedTasks: [(title: String, category: String?)] = []
    
    /// Verbs that strongly signal a task / action item.
    private let actionVerbs: Set<String> = [
        // Do / Make
        "fix", "send", "email", "write", "review", "buy", "complete",
        "update", "check", "schedule", "plan", "create", "build",
        "design", "test", "deploy", "clean", "organize", "reply",
        "respond", "book", "cancel", "return", "remind", "ask",
        "pick", "drop", "pack", "wash", "cook", "pay", "print",
        "download", "upload", "register", "submit", "prepare",
        "study", "finish", "start", "do", "make", "get", "set",
        "move", "take", "bring", "order", "sign", "apply",
        "research", "practice", "arrange", "confirm", "follow",
        "read", "call", "text", "message", "meet", "visit",
        "renew", "refund", "file", "sort", "backup", "install",
        "setup", "configure", "edit", "proofread", "draft"
    ]
    
    /// Keywords that signal urgency / priority.
    private let urgencyKeywords: [String: Int] = [
        "urgent": 10, "asap": 10, "immediately": 10,
        "important": 8, "critical": 9, "deadline": 8,
        "today": 7, "now": 7, "first": 6, "priority": 7,
        "soon": 5, "later": 2, "eventually": 1, "sometime": 1
    ]
    
    /// Category keyword mapping.
    private let categoryMap: [(Set<String>, String)] = [
        (["assignment", "exam", "study", "homework", "slides", "lecture",
          "class", "professor", "quiz", "thesis", "research", "essay",
          "notes", "textbook", "lab", "semester", "grade"], "Academic"),
        
        (["email", "project", "boss", "meeting", "report", "client",
          "code", "deadline", "presentation", "office", "team",
          "standup", "deploy", "sprint", "jira", "slack", "agenda"], "Work"),
        
        (["mom", "dad", "call", "buy", "clean", "gym", "dinner",
          "grocery", "doctor", "appointment", "laundry", "cook",
          "walk", "dog", "cat", "rent", "bills", "pharmacy",
          "birthday", "pick up"], "Personal"),
        
        (["meditate", "journal", "breathe", "therapy", "sleep",
          "rest", "relax", "self-care", "water", "stretch"], "Wellness")
    ]
    
    /// Filler prefixes to strip from candidates.
    private let fillers = [
        "i need to", "i have to", "i should", "i want to", "i gotta",
        "i must", "need to", "have to", "gotta", "gonna",
        "maybe", "also", "please", "just", "can you", "could you",
        "don't forget to", "remember to", "make sure to", "try to"
    ]
    
    func parseText() {
        let sanitizedText = sanitize(rawText)
        
        // ── Split into candidate fragments ──
        var candidates = splitIntoFragments(sanitizedText)
        
        // ── Strip filler prefixes ──
        candidates = candidates.map(stripFillers)
        
        // ── Basic quality filter (min length, has alphanumeric) ──
        candidates = candidates.filter { candidate in
            let hasAlpha = candidate.unicodeScalars.contains {
                CharacterSet.alphanumerics.contains($0)
            }
            return candidate.count > 2 && hasAlpha
        }
        
        // ── Capitalize ──
        candidates = candidates.map { line in
            guard let first = line.first else { return line }
            return String(first).uppercased() + line.dropFirst()
        }
        
        // ── De-duplicate ──
        var seen = Set<String>()
        candidates = candidates.filter { line in
            let key = line.lowercased()
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
        
        // ── Actionability filter ──
        // This is the KEY step: only keep fragments that look like tasks.
        // A fragment is actionable if it:
        //   - Starts with a verb (strongest signal)
        //   - Contains a verb + object pattern
        //   - Is short (< 5 words) — likely a quick note/task
        //   - Contains urgency keywords
        candidates = candidates.filter { isActionable($0) }
        
        // ── Score by urgency ──
        let scored: [(String, Int)] = candidates.map { line in
            let lower = line.lowercased()
            var score = 5
            
            for (keyword, weight) in urgencyKeywords {
                if lower.contains(keyword) {
                    score = max(score, weight)
                }
            }
            
            let words = lower.components(separatedBy: .whitespaces)
            if let firstWord = words.first, actionVerbs.contains(firstWord) {
                score += 3
            }
            
            return (line, min(score, 10))
        }
        
        let sorted = scored.sorted { $0.1 > $1.1 }
        
        // ── Assign categories ──
        parsedTasks = sorted.map { (title, _) in
            let lower = title.lowercased()
            var category: String? = nil
            
            for (keywords, cat) in categoryMap {
                if keywords.contains(where: { lower.contains($0) }) {
                    category = cat
                    break
                }
            }
            
            return (title: title, category: category)
        }
        
        // ── Fallback ──
        // If nothing actionable was extracted, use the raw input as a single entry.
        if parsedTasks.isEmpty {
            let fallback = sanitize(rawText).trimmingCharacters(in: .whitespacesAndNewlines)
            if !fallback.isEmpty {
                // Truncate to a reasonable task-length
                let maxLen = 80
                var title = fallback.count > maxLen
                    ? String(fallback.prefix(maxLen)) + "…"
                    : fallback
                title = String(title.prefix(1)).uppercased() + title.dropFirst()
                parsedTasks = [(title: title, category: nil)]
            }
        }
    }
    
    
    /// Determines if a candidate fragment looks like an actionable task
    /// rather than a narrative observation or statement.
    private func isActionable(_ text: String) -> Bool {
        let lower = text.lowercased()
        let words = lower.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !words.isEmpty else { return false }
        
        let firstWord = words[0]
        
        // 1. Starts with an action verb → definitely a task
        //    "Buy groceries", "Call mom", "Fix the bug"
        if actionVerbs.contains(firstWord) {
            return true
        }
        
        // 2. Very short fragments (1-4 words) are likely quick task notes
        //    "groceries", "dentist appointment", "pay rent"
        if words.count <= 4 {
            return true
        }
        
        // 3. Contains urgency keywords → the person wants something done
        //    "submit report by today", "asap fix login"
        for keyword in urgencyKeywords.keys {
            if lower.contains(keyword) { return true }
        }
        
        // 4. Contains a verb anywhere (not just first word) + is moderately short
        //    "the report needs to be submitted" (contains "submit")
        if words.count <= 10 {
            for word in words {
                if actionVerbs.contains(word) { return true }
            }
        }
        
        // 5. Pattern: starts with "I" + verb-like structure after filler removal
        //    Already handled by filler stripping, but catch stragglers
        if firstWord == "i" && words.count >= 2 {
            let secondWord = words[1]
            let personalActionPrefixes = ["will", "can", "shall", "might", "may"]
            if personalActionPrefixes.contains(secondWord) { return true }
        }
        
        // Otherwise it's probably a statement/thought/observation — skip it
        return false
    }
    
    
    /// Splits raw text into candidate task fragments using intelligent heuristics.
    private func splitIntoFragments(_ text: String) -> [String] {
        // 1. Split by newlines (each line is a distinct thought)
        var fragments = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // 2. Split by semicolons
        fragments = fragments.flatMap { $0.components(separatedBy: ";") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // 3. Period splitting — only for multi-sentence segments
        fragments = fragments.flatMap { segment -> [String] in
            let parts = segment.components(separatedBy: ".")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return parts.count > 1 ? parts : [segment.trimmingCharacters(in: CharacterSet(charactersIn: "."))]
        }
        .filter { !$0.isEmpty }
        
        // 4. Comma-list detection (3+ short items)
        fragments = fragments.flatMap { segment -> [String] in
            let parts = segment.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            if parts.count >= 3 {
                let allShort = parts.allSatisfy {
                    $0.components(separatedBy: .whitespaces).count <= 5
                }
                if allShort { return parts }
            }
            if parts.count == 2 {
                let bothShort = parts.allSatisfy {
                    $0.components(separatedBy: .whitespaces).count <= 3
                }
                if bothShort { return parts }
            }
            return [segment]
        }
        
        // 5. Conjunction splitting — only for short segments (≤ 10 words)
        fragments = fragments.flatMap { segment -> [String] in
            let wordCount = segment.components(separatedBy: .whitespaces).count
            guard wordCount <= 10 else { return [segment] }
            
            var parts = [segment]
            parts = parts.flatMap { splitConjunction($0, by: " and then ") }
            parts = parts.flatMap { splitConjunction($0, by: " and ") }
            parts = parts.flatMap { splitConjunction($0, by: " then ") }
            return parts
        }
        
        return fragments
    }
    
    /// Splits by conjunction only if both halves are meaningful (> 2 chars).
    private func splitConjunction(_ text: String, by conjunction: String) -> [String] {
        let parts = text.components(separatedBy: conjunction)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard parts.count > 1 else { return [text] }
        return parts.allSatisfy({ $0.count > 2 }) ? parts : [text]
    }
    
    
    /// Iteratively strips filler prefixes from a candidate.
    private func stripFillers(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var changed = true
        while changed {
            changed = false
            let lower = cleaned.lowercased()
            for filler in fillers {
                if lower.hasPrefix(filler + " ") {
                    let start = cleaned.index(cleaned.startIndex, offsetBy: filler.count + 1)
                    cleaned = String(cleaned[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    changed = true
                    break
                }
            }
        }
        
        // Strip leftover "to " prefix
        if cleaned.lowercased().hasPrefix("to ") && cleaned.count > 3 {
            let start = cleaned.index(cleaned.startIndex, offsetBy: 3)
            cleaned = String(cleaned[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleaned
    }
    
    var containsEmotionalWords: Bool {
        let emotionalWords: Set<String> = [
            "stressed", "anxious", "overwhelmed", "worried", "panic",
            "frustrated", "angry", "tired", "exhausted", "confused",
            "scared", "nervous", "too much", "help", "can't",
            "lost", "stuck", "drowning", "chaos", "mess",
            "everything", "hopeless", "impossible", "crazy"
        ]
        let lower = rawText.lowercased()
        return emotionalWords.contains { lower.contains($0) }
    }
    
    func clear() {
        rawText = ""
        parsedTasks = []
    }
    
    
    /// Strips Markdown formatting, numbered lists, and structural artifacts.
    private func sanitize(_ text: String) -> String {
        var cleanLines: [String] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            var l = line.trimmingCharacters(in: .whitespaces)
            
            // Ignore Markdown headers
            if l.hasPrefix("#") { continue }
            
            // Strip bullet points
            if l.hasPrefix("- ") || l.hasPrefix("* ") || l.hasPrefix("• ") {
                l = String(l.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            }
            
            // Strip numbered lists
            let numberedPattern = /^\d+[\.\)\-]\s*/
            if let match = l.prefixMatch(of: numberedPattern) {
                l = String(l[match.range.upperBound...]).trimmingCharacters(in: .whitespaces)
            }
            
            // Remove formatting
            l = l.replacingOccurrences(of: "**", with: "")
            l = l.replacingOccurrences(of: "__", with: "")
            l = l.replacingOccurrences(of: "`", with: "")
            l = l.replacingOccurrences(of: "*", with: "")
            
            // Keep lines with actual content
            let hasContent = l.unicodeScalars.contains {
                CharacterSet.alphanumerics.contains($0)
            }
            if hasContent {
                l = l.trimmingCharacters(in: CharacterSet(charactersIn: "): "))
                if l.hasPrefix(":") { l.removeFirst() }
                l = l.trimmingCharacters(in: .whitespaces)
                if !l.isEmpty { cleanLines.append(l) }
            }
        }
        
        return cleanLines.joined(separator: "\n")
    }
}
