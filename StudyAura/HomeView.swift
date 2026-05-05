import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: StudyStore
    @State private var showTodoSetup = false
    @State private var showTimetable = false
    @State private var showInsights = false
    @State private var selectedTask: TodoTask? = nil

    var weekHours: String {
        let h = store.totalWeekMinutes / 60
        return String(format: "%.1f hrs", h)
    }

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // HEADER
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("StudyAura 🧠")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Let's get focused today!")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("🔥")
                                .font(.title)
                            Text("\(store.streakDays) days")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        .padding(10)
                        .background(Color(hex: "2A1500"))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)

                    // STAT CARDS
                    HStack(spacing: 12) {
                        StatMiniCard(icon: "clock.fill", value: weekHours, label: "This Week", color: .accentBlue)
                        StatMiniCard(icon: "checklist", value: "\(store.pendingTasks().count) left", label: "Tasks", color: .accentPurple)
                        StatMiniCard(icon: "sun.max.fill", value: "\(Int(store.totalWeekMinutes)) min", label: "Today", color: Color(hex: "FFB300"))
                    }
                    .padding(.horizontal)

                    // PEAK FOCUS
                    HStack(spacing: 10) {
                        Text("🧠")
                        Text("Your peak focus time: \(store.peakFocusTime)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                    }
                    .padding()
                    .glassCard(color: Color.accentPurple.opacity(0.2))
                    .padding(.horizontal)

                    // WEEKLY INSIGHTS BANNER
                    Button {
                        showInsights = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundColor(.accentBlue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Weekly Insights")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("See your focus trends this week")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding()
                        .glassCard(color: Color.accentBlue.opacity(0.1))
                    }
                    .padding(.horizontal)

                    // PENDING TASKS
                    if !store.pendingTasks().isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pending Tasks")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal)

                            ForEach(store.pendingTasks()) { task in
                                PendingTaskRow(task: task) {
                                    selectedTask = task
                                } onDelete: {
                                    store.deleteTask(id: task.id)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // RECENT SESSIONS
                    if !store.recentSummaries.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Sessions")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal)

                            ForEach(store.recentSummaries.prefix(5), id: \.subject) { summary in
                                RecentSessionRow(summary: summary)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
            }

            // BOTTOM BUTTONS
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        showTodoSetup = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Add Task & Study")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [.accentPurple, .accentBlue],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(18)
                        .shadow(color: .accentPurple.opacity(0.5), radius: 12, y: 4)
                    }

                    Button {
                        showTimetable = true
                    } label: {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(18)
                            .background(Color.accentBlue.opacity(0.3))
                            .cornerRadius(18)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showTodoSetup) {
            TodoSetupView().environmentObject(store)
        }
        .sheet(isPresented: $showTimetable) {
            TimetableView().environmentObject(store)
        }
        .sheet(isPresented: $showInsights) {
            WeeklyInsightsView().environmentObject(store)
        }
        .fullScreenCover(item: $selectedTask) { task in
            LiveSessionView(subject: task.subject, duration: task.remainingDuration, taskId: task.id)
                .environmentObject(store)
        }
    }
}

struct StatMiniCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard()
    }
}

struct PendingTaskRow: View {
    let task: TodoTask
    let onStart: () -> Void
    let onDelete: () -> Void

    var progressPercent: Double {
        guard task.totalDuration > 0 else { return 0 }
        let done = task.totalDuration - task.remainingDuration
        return Double(done) / Double(task.totalDuration)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.accentPurple.opacity(0.7))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.subject)
                        .font(.headline)
                        .foregroundColor(.white)
                    HStack(spacing: 6) {
                        Text("\(task.remainingDuration) min remaining")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        if task.sessions.count > 0 {
                            Text("• \(task.sessions.count) session(s) done")
                                .font(.caption)
                                .foregroundColor(.focusGreen.opacity(0.8))
                        }
                    }
                }

                Spacer()

                Button(action: onStart) {
                    Text(task.sessions.isEmpty ? "Start" : "Continue")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(task.sessions.isEmpty ? Color.accentBlue : Color.focusGreen)
                        .cornerRadius(10)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.awayRed.opacity(0.8))
                }
            }

            if task.sessions.count > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.focusGreen)
                            .frame(width: geo.size.width * CGFloat(progressPercent))
                    }
                }
                .frame(height: 4)
            }
        }
        .padding()
        .glassCard()
    }
}

struct RecentSessionRow: View {
    let summary: SessionSummary

    var focusColor: Color {
        summary.focusScore >= 70 ? .focusGreen : summary.focusScore >= 40 ? .strugglingOrange : .awayRed
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(summary.subject)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(summary.date.formatted(date: .numeric, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Text("\(summary.focusScore)%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(focusColor)
        }
        .padding()
        .glassCard()
    }
}
