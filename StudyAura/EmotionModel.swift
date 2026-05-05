import Foundation

enum EmotionState: String, CaseIterable {
    case focused = "Focused"
    case drowsy = "Drowsy"
    case away = "Away"

    var emoji: String {
        switch self {
        case .focused: return "🎯"
        case .drowsy: return "😴"
        case .away: return "👻"
        }
    }

    var message: String {
        switch self {
        case .focused: return "Great job! Keep it up!"
        case .drowsy: return "Splash water on your face!"
        case .away: return "Come back to your desk!"
        }
    }

    var color: String {
        switch self {
        case .focused: return "00C853"
        case .drowsy: return "AA00FF"
        case .away: return "FF1744"
        }
    }
}

struct EmotionDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let emotion: EmotionState
    let smileScore: Double
    let attentionScore: Double
    let secondsFromStart: Double
}

struct SessionSummary {
    let totalDuration: TimeInterval
    let dataPoints: [EmotionDataPoint]
    let subject: String
    let date: Date

    init(totalDuration: TimeInterval, dataPoints: [EmotionDataPoint], subject: String, date: Date = Date()) {
        self.totalDuration = totalDuration
        self.dataPoints = dataPoints
        self.subject = subject
        self.date = date
    }

    var focusedPercent: Double {
        guard !dataPoints.isEmpty else { return 0 }
        return Double(dataPoints.filter { $0.emotion == .focused }.count) / Double(dataPoints.count) * 100
    }
    var drowsyPercent: Double {
        guard !dataPoints.isEmpty else { return 0 }
        return Double(dataPoints.filter { $0.emotion == .drowsy }.count) / Double(dataPoints.count) * 100
    }
    var awayPercent: Double {
        guard !dataPoints.isEmpty else { return 0 }
        return Double(dataPoints.filter { $0.emotion == .away }.count) / Double(dataPoints.count) * 100
    }
    var strugglingPercent: Double { 0 }
    var focusScore: Int {
        let score = focusedPercent - (drowsyPercent * 0.7) - (awayPercent * 1.0)
        return max(0, min(100, Int(score + (focusedPercent * 0.3))))
    }
    var engagedPercent: Double { focusedPercent }
    var distractedPercent: Double { awayPercent + drowsyPercent }
}
