import SwiftUI

struct SummaryView: View {
    let summaries: [SessionSummary]
    let onDismiss: () -> Void
    @EnvironmentObject var store: StudyStore

    var primary: SessionSummary? { summaries.first }
    var avgFocus: Double { summaries.map { $0.focusedPercent }.reduce(0,+) / Double(max(summaries.count,1)) }
    var avgDrowsy: Double { summaries.map { $0.drowsyPercent }.reduce(0,+) / Double(max(summaries.count,1)) }
    var avgAway: Double { summaries.map { $0.awayPercent }.reduce(0,+) / Double(max(summaries.count,1)) }
    var avgScore: Int { summaries.map { $0.focusScore }.reduce(0,+) / max(summaries.count,1) }
    var totalDuration: TimeInterval { summaries.map { $0.totalDuration }.reduce(0,+) }
    var totalSnapshots: Int { summaries.map { $0.dataPoints.count }.reduce(0,+) }

    var scoreColor: Color {
        avgScore >= 70 ? .focusGreen : avgScore >= 40 ? .strugglingOrange : .awayRed
    }

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // HEADER
                    VStack(spacing: 4) {
                        Text("Session Complete! 🎉")
                            .font(.title2).bold()
                            .foregroundColor(.white)
                            .padding(.top, 32)
                        if let p = primary {
                            Text(p.subject)
                                .font(.subheadline)
                                .foregroundColor(.accentPurple)
                        }
                        Text("\(totalSnapshots) snapshots recorded")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }

                    // CIRCULAR SCORE
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 14)
                            .frame(width: 150, height: 150)
                        Circle()
                            .trim(from: 0, to: CGFloat(avgScore) / 100)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.2), value: avgScore)
                        VStack(spacing: 2) {
                            Text("\(avgScore)")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)
                            Text("Focus Score")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    // 3 TOP STATS
                    HStack(spacing: 12) {
                        SummaryStatBox(value: "\(Int(avgFocus))%", label: "Focused", color: .focusGreen)
                        SummaryStatBox(value: "\(Int(avgDrowsy))%", label: "Drowsy", color: .drowsyPurple)
                        SummaryStatBox(value: "\(Int(avgAway))%", label: "Away", color: .awayRed)
                    }
                    .padding(.horizontal)

                    // TIMELINE CHART
                    if let first = summaries.first, !first.dataPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Focus Timeline")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            TimelineChart(dataPoints: first.dataPoints)
                                .frame(height: 100)

                            HStack(spacing: 14) {
                                LegendDot(color: .focusGreen, label: "Focused")
                                LegendDot(color: .drowsyPurple, label: "Drowsy")
                                LegendDot(color: .awayRed, label: "Away")
                            }
                            .font(.caption2)
                        }
                        .padding()
                        .glassCard()
                        .padding(.horizontal)
                    }

                    // STREAK
                    HStack(spacing: 12) {
                        Text("🔥")
                            .font(.title)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(store.streakDays) Day Streak!")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Text("Keep it up, you're doing great!")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                    }
                    .padding()
                    .glassCard(color: Color(hex: "2A1500"))
                    .padding(.horizontal)

                    // BREAKDOWN
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Breakdown")
                            .font(.headline)
                            .foregroundColor(.white)

                        BreakdownRow(emoji: "🎯", label: "Focused", percent: avgFocus, color: .focusGreen)
                        BreakdownRow(emoji: "😴", label: "Drowsy", percent: avgDrowsy, color: .drowsyPurple)
                        BreakdownRow(emoji: "👻", label: "Away", percent: avgAway, color: .awayRed)
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)

                    // PER SUBJECT if multiple
                    if summaries.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Per Subject")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            ForEach(summaries, id: \.subject) { s in
                                HStack {
                                    Text(s.subject)
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(s.focusScore)%")
                                        .fontWeight(.bold)
                                        .foregroundColor(s.focusScore >= 70 ? .focusGreen : .awayRed)
                                }
                                .padding()
                                .glassCard()
                                .padding(.horizontal)
                            }
                        }
                    }

                    // DONE
                    Button(action: onDismiss) {
                        Text("Done 🎉")
                            .font(.headline).bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(colors: [.accentPurple, .accentBlue],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(18)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct SummaryStatBox: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2).bold()
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassCard(color: color.opacity(0.1))
    }
}

struct BreakdownRow: View {
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
                .frame(width: 80, alignment: .leading)
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
                .frame(width: 36, alignment: .trailing)
        }
    }
}

struct TimelineChart: View {
    let dataPoints: [EmotionDataPoint]

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(dataPoints) { point in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(point.emotion.swiftColor)
                        .frame(width: max(2, geo.size.width / CGFloat(max(dataPoints.count, 1)) - 2))
                }
            }
        }
    }
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundColor(.white.opacity(0.6))
        }
    }
}
