import SwiftUI

struct TodoSetupView: View {
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) var dismiss

    @State private var subject = ""
    @State private var duration = 30

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Add Study Task")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                    .padding(.top, 32)

                VStack(spacing: 16) {
                    TextField("Subject (e.g. Mathematics)", text: $subject)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration: \(duration) minutes")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        Slider(value: Binding(get: { Double(duration) }, set: { duration = Int($0) }), in: 5...120, step: 5)
                            .accentColor(.accentPurple)
                    }
                }
                .padding()
                .glassCard()
                .padding(.horizontal)

                Button {
                    guard !subject.isEmpty else { return }
                    store.addTask(subject: subject, duration: duration)
                    dismiss()
                } label: {
                    Text("Add Task")
                        .font(.headline).bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Group {
                                if subject.isEmpty {
                                    Color.gray
                                } else {
                                    LinearGradient(colors: [.accentPurple, .accentBlue], startPoint: .leading, endPoint: .trailing)
                                }
                            }
                        )
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
                .disabled(subject.isEmpty)

                Spacer()
            }
        }
    }
}
