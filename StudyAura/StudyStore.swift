import Foundation
import Combine

struct TodoTask: Identifiable, Codable {
    let id: UUID
    var subject: String
    var totalDuration: Int // original total minutes
    var remainingDuration: Int // minutes left
    var isCompleted: Bool
    var sessions: [CompletedSession]
    var createdDate: Date

    init(id: UUID = UUID(), subject: String, duration: Int, isCompleted: Bool = false, sessions: [CompletedSession] = [], createdDate: Date = Date()) {
        self.id = id
        self.subject = subject
        self.totalDuration = duration
        self.remainingDuration = duration
        self.isCompleted = isCompleted
        self.sessions = sessions
        self.createdDate = createdDate
    }
}

struct CompletedSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let focusedPercent: Double
    let strugglingPercent: Double
    let drowsyPercent: Double
    let awayPercent: Double
    let focusScore: Int

    init(id: UUID = UUID(), date: Date = Date(), duration: TimeInterval, focusedPercent: Double, strugglingPercent: Double, drowsyPercent: Double, awayPercent: Double, focusScore: Int) {
        self.id = id
        self.date = date
        self.duration = duration
        self.focusedPercent = focusedPercent
        self.strugglingPercent = strugglingPercent
        self.drowsyPercent = drowsyPercent
        self.awayPercent = awayPercent
        self.focusScore = focusScore
    }
}

struct TimetableEntry: Identifiable, Codable {
    let id: UUID
    var subject: String
    var duration: Int
    var order: Int

    init(id: UUID = UUID(), subject: String, duration: Int, order: Int) {
        self.id = id
        self.subject = subject
        self.duration = duration
        self.order = order
    }
}

class StudyStore: ObservableObject {
    static let shared = StudyStore()

    @Published var tasks: [TodoTask] = []
    @Published var timetable: [TimetableEntry] = []
    @Published var recentSummaries: [SessionSummary] = []
    @Published var streakDays: Int = 1
    @Published var totalWeekMinutes: Double = 0

    private let tasksKey = "studystore_tasks_v2"
    private let timetableKey = "studystore_timetable"
    private let streakKey = "studystore_streak"

    init() {
        loadTasks()
        loadTimetable()
        streakDays = UserDefaults.standard.integer(forKey: streakKey)
        if streakDays == 0 { streakDays = 1 }
    }

    func addTask(subject: String, duration: Int) {
        let task = TodoTask(subject: subject, duration: duration)
        tasks.append(task)
        saveTasks()
    }

    // Called when a session ends — deducts time spent, keeps task pending if time remains
    func recordSession(id: UUID, summary: SessionSummary) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            let minutesSpent = Int(summary.totalDuration / 60)
            let newRemaining = max(0, tasks[index].remainingDuration - minutesSpent)

            let session = CompletedSession(
                duration: summary.totalDuration,
                focusedPercent: summary.focusedPercent,
                strugglingPercent: summary.strugglingPercent,
                drowsyPercent: summary.drowsyPercent,
                awayPercent: summary.awayPercent,
                focusScore: summary.focusScore
            )
            tasks[index].sessions.append(session)
            tasks[index].remainingDuration = newRemaining

            // Only mark completed if time is fully done
            if newRemaining <= 0 {
                tasks[index].isCompleted = true
            }
            saveTasks()
        }
        recentSummaries.insert(summary, at: 0)
        totalWeekMinutes += summary.totalDuration / 60
        streakDays = max(streakDays, 1)
        UserDefaults.standard.set(streakDays, forKey: streakKey)
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        saveTasks()
    }

    func pendingTasks() -> [TodoTask] {
        tasks.filter { !$0.isCompleted }
    }

    func addTimetableEntry(subject: String, duration: Int) {
        let entry = TimetableEntry(subject: subject, duration: duration, order: timetable.count)
        timetable.append(entry)
        saveTimetable()
    }

    func removeTimetableEntry(id: UUID) {
        timetable.removeAll { $0.id == id }
        saveTimetable()
    }

    func clearTimetable() {
        timetable.removeAll()
        saveTimetable()
    }

    var peakFocusTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5 && hour < 12 { return "Morning (your best time!)" }
        else if hour >= 12 && hour < 17 { return "Afternoon" }
        else { return "Evening" }
    }

    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksKey)
        }
    }

    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([TodoTask].self, from: data) {
            tasks = decoded
        }
    }

    private func saveTimetable() {
        if let data = try? JSONEncoder().encode(timetable) {
            UserDefaults.standard.set(data, forKey: timetableKey)
        }
    }

    private func loadTimetable() {
        if let data = UserDefaults.standard.data(forKey: timetableKey),
           let decoded = try? JSONDecoder().decode([TimetableEntry].self, from: data) {
            timetable = decoded
        }
    }
}
