import SwiftUI
import AVFoundation

struct LiveSessionView: View {
    let subject: String
    let duration: Int
    let taskId: UUID?

    @EnvironmentObject var store: StudyStore
    @StateObject private var analyzer = FaceEmotionAnalyzer()
    @Environment(\.dismiss) var dismiss

    @State private var timeRemaining: Int
    @State private var isRunning = false
    @State private var dataPoints: [EmotionDataPoint] = []
    @State private var startTime = Date()
    @State private var showSummary = false
    @State private var summary: SessionSummary?
    @State private var timer: Timer?
    @State private var timeline: [EmotionState] = []
    @State private var alertCooldown = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var audioPlayer: AVAudioPlayer?
    @State private var selectedSound: AmbientSound? = nil
    @State private var showSoundPicker = false

    // Haptic generators — prepared upfront
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)

    init(subject: String, duration: Int, taskId: UUID? = nil) {
        self.subject = subject
        self.duration = duration
        self.taskId = taskId
        _timeRemaining = State(initialValue: duration * 60)
    }

    var timeString: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showSummary, let s = summary {
                SummaryView(summaries: [s]) { dismiss() }
                    .environmentObject(store)
            } else {
                VStack(spacing: 0) {

                    // TOP BAR
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("StudyAura 🧠")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(subject)
                                .font(.subheadline)
                                .foregroundColor(.accentPurple)
                        }
                        Spacer()
                        Text(timeString)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(timeRemaining < 60 ? .awayRed : .white)
                    }
                    .padding()

                    // TRACKING + SOUND ROW
                    HStack {
                        Button {
                            showSoundPicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: selectedSound == nil ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.caption)
                                Text(selectedSound == nil ? "Ambient Sound" : selectedSound!.name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundColor(selectedSound == nil ? .white.opacity(0.4) : .accentBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(10)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Circle()
                                .fill(isRunning ? Color.focusGreen : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(isRunning ? "Tracking" : "Paused")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 6)

                    // CAMERA
                    CameraPreview(session: analyzer.captureSession)
                        .frame(height: 280)
                        .cornerRadius(20)
                        .padding(.horizontal)

                    // ALERT BANNER
                    if showAlert {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text(alertMessage)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.25))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer()

                    // EMOTION CARD
                    HStack(spacing: 16) {
                        Text(analyzer.currentEmotion.emoji)
                            .font(.system(size: 44))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(analyzer.currentEmotion.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(analyzer.currentEmotion.message)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(analyzer.currentEmotion.swiftColor.opacity(0.15))
                    .cornerRadius(18)
                    .padding(.horizontal)

                    // LIVE TIMELINE
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live Timeline")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 3) {
                                ForEach(Array(timeline.enumerated()), id: \.offset) { _, emotion in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(emotion.swiftColor)
                                        .frame(width: 18, height: 28)
                                }
                            }
                        }
                    }
                    .padding()

                    // END BUTTON
                    Button {
                        endSession()
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("End Session")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.awayRed)
                        .cornerRadius(18)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showAlert)
        .sheet(isPresented: $showSoundPicker) {
            AmbientSoundPicker(selected: $selectedSound) { sound in
                playSound(sound)
            }
        }
        .onAppear {
            // Prepare haptics upfront so they fire instantly
            notificationGenerator.prepare()
            impactGenerator.prepare()
            analyzer.start()
            startSession()
        }
        .onDisappear {
            analyzer.stop()
            timer?.invalidate()
            audioPlayer?.stop()
        }
        .onChange(of: analyzer.currentEmotion) { emotion in
            handleEmotionChange(emotion)
        }
    }

    private func startSession() {
        isRunning = true
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                recordDataPoint()
                timeline.append(analyzer.currentEmotion)
                if alertCooldown > 0 { alertCooldown -= 1 }
            } else {
                endSession()
            }
        }
    }

    private func handleEmotionChange(_ emotion: EmotionState) {
        guard alertCooldown == 0 else { return }
        switch emotion {
        case .drowsy:
            triggerAlert(message: "😴 You look drowsy! Splash water on your face!")
            // Fire haptic 3 times for drowsy
            notificationGenerator.notificationOccurred(.warning)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                notificationGenerator.notificationOccurred(.warning)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                notificationGenerator.notificationOccurred(.warning)
            }
            alertCooldown = 15
        case .away:
            triggerAlert(message: "👻 Come back! You've left the frame!")
            impactGenerator.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                impactGenerator.impactOccurred(intensity: 1.0)
            }
            alertCooldown = 8
        case .focused:
            withAnimation { showAlert = false }
        }
    }

    private func triggerAlert(message: String) {
        alertMessage = message
        withAnimation { showAlert = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation { showAlert = false }
        }
    }

    private func playSound(_ sound: AmbientSound?) {
        audioPlayer?.stop()
        audioPlayer = nil
        selectedSound = sound
        guard let sound = sound else { return }
        guard let url = Bundle.main.url(forResource: sound.filename, withExtension: "mp3") else {
            print("⚠️ Sound file not found: \(sound.filename).mp3")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
        } catch {
            print("Audio error: \(error)")
        }
    }

    private func endSession() {
        timer?.invalidate()
        isRunning = false
        analyzer.stop()
        audioPlayer?.stop()
        let elapsed = Date().timeIntervalSince(startTime)
        let s = SessionSummary(totalDuration: elapsed, dataPoints: dataPoints, subject: subject)
        if let id = taskId {
            store.recordSession(id: id, summary: s)
        }
        summary = s
        showSummary = true
    }

    private func recordDataPoint() {
        let point = EmotionDataPoint(
            timestamp: Date(),
            emotion: analyzer.currentEmotion,
            smileScore: analyzer.smileScore,
            attentionScore: analyzer.attentionScore,
            secondsFromStart: Double((duration * 60) - timeRemaining)
        )
        dataPoints.append(point)
    }
}

// MARK: - Ambient Sound
enum AmbientSound: String, CaseIterable, Identifiable {
    case rain = "Rain 🌧️"
    case ocean = "Ocean Waves 🌊"
    case forest = "Forest Birds 🌲"
    case brownnoise = "Brown Noise 🟤"
    case cafe = "Cafe ☕"

    var id: String { rawValue }
    var name: String { rawValue }

    var filename: String {
        switch self {
        case .rain: return "rain"
        case .ocean: return "ocean"
        case .forest: return "forest"
        case .brownnoise: return "brownnoise"
        case .cafe: return "cafe"
        }
    }

    var description: String {
        switch self {
        case .rain: return "Calming rain for deep focus"
        case .ocean: return "Ocean waves to relax your mind"
        case .forest: return "Birds chirping in nature"
        case .brownnoise: return "Deep rumble for concentration"
        case .cafe: return "Coffee shop background chatter"
        }
    }

    var icon: String {
        switch self {
        case .rain: return "🌧️"
        case .ocean: return "🌊"
        case .forest: return "🌲"
        case .brownnoise: return "🟤"
        case .cafe: return "☕"
        }
    }
}

// MARK: - Sound Picker
struct AmbientSoundPicker: View {
    @Binding var selected: AmbientSound?
    let onSelect: (AmbientSound?) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("🎵 Ambient Sounds")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                    .padding(.top, 32)

                Text("Pick a sound to play during your session")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 4)

                ForEach(AmbientSound.allCases) { sound in
                    Button {
                        selected = sound
                        onSelect(sound)
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Text(sound.icon)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sound.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(sound.description)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                            if selected == sound {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.focusGreen)
                                    .font(.title3)
                            }
                        }
                        .padding()
                        .background(selected == sound ? Color.focusGreen.opacity(0.12) : Color.white.opacity(0.06))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                }

                Button {
                    selected = nil
                    onSelect(nil)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "speaker.slash.fill")
                        Text("Turn Off Sound")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.awayRed)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.awayRed.opacity(0.08))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Timetable Session
struct TimetableSessionView: View {
    let entries: [TimetableEntry]
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) var dismiss

    @State private var currentIndex = 0
    @State private var allSummaries: [SessionSummary] = []
    @State private var showFinalSummary = false

    var body: some View {
        if showFinalSummary {
            SummaryView(summaries: allSummaries) { dismiss() }
                .environmentObject(store)
        } else if currentIndex < entries.count {
            let entry = entries[currentIndex]
            LiveSessionView(subject: entry.subject, duration: entry.duration)
                .environmentObject(store)
                .onDisappear {
                    if currentIndex < entries.count - 1 {
                        currentIndex += 1
                    } else {
                        showFinalSummary = true
                    }
                }
        }
    }
}
