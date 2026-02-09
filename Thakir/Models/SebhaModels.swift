import Foundation

// History entry for tracking sebha usage over time
struct HistoryEntry: Codable {
    let date: Date
    let count: Int
}

// Per-sebha statistics
struct SebhaStatistics: Codable {
    var todayCount: Int = 0
    var weekCount: Int = 0
    var monthCount: Int = 0
    var allTimeCount: Int = 0
    var lastUpdated: Date = Date()
    var history: [HistoryEntry] = []
    
    mutating func increment(by count: Int = 1) {
        todayCount += count
        weekCount += count
        monthCount += count
        allTimeCount += count
        lastUpdated = Date()
        history.append(HistoryEntry(date: Date(), count: count))
    }
    
    mutating func resetDaily() {
        todayCount = 0
        lastUpdated = Date()
    }
    
    mutating func resetAll() {
        todayCount = 0
        weekCount = 0
        monthCount = 0
        allTimeCount = 0
        history.removeAll()
        lastUpdated = Date()
    }
}

struct Sebha: Identifiable, Codable, Hashable {
    let id = UUID()
    var text: String
    var target: Int
    var count: Int
    var totalCount: Int
    var voiceRecordingURL: URL?
    var createdDate: Date
    var lastUsedDate: Date?
    
    init(text: String, target: Int, count: Int = 0, totalCount: Int = 0) {
        self.text = text
        self.target = target
        self.count = count
        self.totalCount = totalCount
        self.createdDate = Date()
    }
    
    mutating func incrementCount() {
        count += 1
        totalCount += 1
        lastUsedDate = Date()
    }
    
    mutating func resetDailyCount() {
        count = 0
    }
    
    var isCompleted: Bool {
        return count >= target
    }
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return Double(count) / Double(target)
    }
}

struct SebhaSession: Codable {
    let id = UUID()
    let sebhaText: String
    let count: Int
    let target: Int
    let date: Date
    let completed: Bool
    
    init(sebha: Sebha) {
        self.sebhaText = sebha.text
        self.count = sebha.count
        self.target = sebha.target
        self.date = Date()
        self.completed = sebha.isCompleted
    }
}

struct DailyStats: Codable {
    let date: Date
    let totalCount: Int
    let completedSebhas: Int
    let sessions: [SebhaSession]
    
    init(date: Date = Date(), totalCount: Int = 0, completedSebhas: Int = 0, sessions: [SebhaSession] = []) {
        self.date = date
        self.totalCount = totalCount
        self.completedSebhas = completedSebhas
        self.sessions = sessions
    }
}
