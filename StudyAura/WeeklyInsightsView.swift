import SwiftUI

struct WeeklyInsightsView: View {
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) var dismiss

    var last7Summaries: [SessionSummary] {
        Array(store.recentSummaries.prefix(7))
    }

    var avgFocusScore: Int {
        guard !last7Summaries.isEmpty else { return 0 }
        return last7Summaries.map { $0.focusScore }.reduce(0,+) / last7Summaries.count
    }

    var totalHours: String {
        let mins = last7Summaries.map { $0.totalDuration }.reduce(0,+) / 60
        return String(format: "%.1f", mins / 60)
    }

    var totalSessions: Int { last7Summaries.count }

    var bestSession: SessionSummary? {
        last7Summaries.max(by: { $0.focusScore < $1.focusScore })
    }

    var avgFocused: Double {
        guard !last7Summaries.isEmpty else { return 0 }
        return last7Summaries.map { $0.focusedPercent }.reduce(0,+) / Double(last7Summaries.count)
    }

    var avgDrowsy: Double {
        guard !last7Summaries.isEmpty else { return 0 }
        return last7Summaries.map { $0.drowsyPercent }.reduce(0,+) / Double(last7Summaries.count)
    }

    var avgAway: Double {
        guard !last7Summaries.isEmpty else { return 0 }
        return last7Summaries.map { $0.awayPercent }.reduce(0,+) / Double(last7Summaries.count)
    }

    var scoreColor: Color {
        avgFocusScore >= 70 ? .focusGreen : avgFocusScore >= 40 ? .strugglingOrange : .awayRed
    }

    var motivationalMessage: String {
        if avgFocusScore >= 80 { return "🔥 You're on fire! Keep it up!" }
        else if avgFocusScore >= 60 { return "💪 Good progress! Push harder!" }
        else if avgFocusScore >= 40 { return "📈 You're improving! Stay consistent!" }
        else if last7Summaries.isEmpty { return "🌟 Start your first session today!" }
        else { return "💡 Keep going, every session counts!" }
    }

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // HEADER
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                        Spacer()
                        Text("Weekly Insights 📊")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .padding(.top, 8)

                    // MOTIVATIONAL BANNER
                    Text(motivationalMessage)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .glassCard(color: Color.accentPurple.opacity(0.2))
                        .padding(.horizontal)

                    // TOP 3 STATS
                    HStack(spacing: 12) {
                        WeekStatCard(icon: "⏱️", value: "\(totalHours)h", label: "Total Hours", color: .accentBlue)
                        WeekStatCard(icon: "📚", value: "\(totalSessions)", label: "Sessions", color: .accentPurple)
                        WeekStatCard(icon: "🔥", value: "\(store.streakDays)", label: "Day Streak", color: .orange)
                    }
                    .padding(.horizontal)

                    // AVG FOCUS SCORE CIRCLE
                    VStack(spacing: 16) {
                        Text("Average Focus Score")
                            .font(.headline)
                            .foregroundColor(.white)

                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 16)
                                .frame(width: 160, height: 160)
                            Circle()
                                .trim(from: 0, to: CGFloat(avgFocusScore) / 100)
                                .stroke(scoreColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut(duration: 1.2), value: avgFocusScore)
                            VStack(spacing: 4) {
                                Text("\(avgFocusScore)")
                                    .font(.system(size: 46, weight: .bold))
                                    .foregroundColor(.white)
                                Text("/ 100")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)

                    // EMOTION BREAKDOWN
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Weekly Emotion Breakdown")
                            .font(.headline)
                            .foregroundColor(.white)

                        WeekBreakdownRow(emoji: "🎯", label: "Focused", percent: avgFocused, color: .focusGreen)
                        WeekBreakdownRow(emoji: "😴", label: "Drowsy", percent: avgDrowsy, color: .drowsyPurple)
                        WeekBreakdownRow(emoji: "👻", label: "Away", percent: avgAway, color: .awayRed)
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)

                    // SESSION HISTORY CHART
                    if !last7Summaries.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Session History")
                                .font(.headline)
                                .foregroundColor(.white)

                            // Bar chart
                            HStack(alignment: .bottom, spacing: 10) {
                                ForEach(Array(last7Summaries.enumerated()), id: \.offset) { i, summary in
                                    VStack(spacing: 6) {
                                        Text("\(summary.focusScore)")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.6))

                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(summary.focusScore >= 70 ? Color.focusGreen :
                                                    summary.focusScore >= 40 ? Color.strugglingOrange : Color.awayRed)
                                            .frame(height: CGFloat(summary.focusScore) * 1.2)
                                            .frame(maxWidth: .infinity)

                                        Text(summary.subject.prefix(4) + ".")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .frame(height: 140)
                        }
                        .padding()
                        .glassCard()
                        .padding(.horizontal)
                    }

                    // BEST SESSION
                    if let best = bestSession {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("🏆 Best Session This Week")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(best.subject)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text(best.date.formatted(date: .numeric, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                Spacer()
                                VStack(spacing: 2) {
                                    Text("\(best.focusScore)")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.focusGreen)
                                    Text("score")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }

                            HStack(spacing: 12) {
                                MiniStat(label: "Focused", value: "\(Int(best.focusedPercent))%", color: .focusGreen)
                                MiniStat(label: "Drowsy", value: "\(Int(best.drowsyPercent))%", color: .drowsyPurple)
                                MiniStat(label: "Away", value: "\(Int(best.awayPercent))%", color: .awayRed)
                            }
                        }
                        .padding()
                        .glassCard(color: Color.focusGreen.opacity(0.08))
                        .padding(.horizontal)
                    }

                    // STREAK CARD
                    HStack(spacing: 14) {
                        Text("🔥")
                            .font(.system(size: 40))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(store.streakDays) Day Streak!")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text(store.streakDays >= 7 ? "Amazing! A full week of studying!" :
                                    store.streakDays >= 3 ? "Great consistency! Keep it going!" :
                                    "Good start! Don't break the streak!")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                    }
                    .padding()
                    .glassCard(color: Color(hex: "2A1500"))
                    .padding(.horizontal)

                    // TIPS BASED ON DATA
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💡 Personalized Tips")
                            .font(.headline)
                            .foregroundColor(.white)

                        if avgDrowsy > 20 {
                            TipRow(icon: "💧", tip: "You get drowsy often — try studying after a walk or with cold water nearby.")
                        }
                        if avgAway > 15 {
                            TipRow(icon: "📱", tip: "You leave frame frequently — put your phone away and sit closer to the camera.")
                        }
                        if avgFocusScore >= 70 {
                            TipRow(icon: "⭐", tip: "Excellent focus! You're in your peak study zone. Keep this routine!")
                        }
                        if last7Summaries.isEmpty {
                            TipRow(icon: "🚀", tip: "Complete your first session to get personalized tips!")
                        }
                        if avgFocusScore < 40 && !last7Summaries.isEmpty {
                            TipRow(icon: "😴", tip: "Try studying in shorter 25-min bursts with 5-min breaks (Pomodoro technique).")
                        }
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct WeekStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(icon).font(.title2)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard()
    }
}

struct WeekBreakdownRow: View {
    let emoji: String
    let label: String
    let percent: Double
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji).font(.title3)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: 70, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(percent / 100))
                        .animation(.easeOut(duration: 1.0), value: percent)
                }
            }
            .frame(height: 10)
            Text("\(Int(percent))%")
                .font(.caption).fontWeight(.bold)
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline).fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .glassCard(color: color.opacity(0.08))
    }
}

struct TipRow: View {
    let icon: String
    let tip: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon).font(.title3)
            Text(tip)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}
