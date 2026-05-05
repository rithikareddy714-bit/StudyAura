import SwiftUI

struct TimetableView: View {
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) var dismiss

    @State private var subject = ""
    @State private var duration = 45
    @State private var showSession = false

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("📅 Timetable")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 24)

                VStack(spacing: 12) {
                    TextField("Subject name", text: $subject)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)

                    HStack {
                        Text("Duration: \(duration) min")
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Stepper("", value: $duration, in: 10...120, step: 5).labelsHidden()
                    }

                    Button {
                        guard !subject.isEmpty else { return }
                        store.addTimetableEntry(subject: subject, duration: duration)
                        subject = ""
                        duration = 45
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Subject")
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(subject.isEmpty ? Color.gray : Color.accentBlue)
                        .cornerRadius(14)
                    }
                    .disabled(subject.isEmpty)
                }
                .padding()
                .glassCard()
                .padding(.horizontal)

                if store.timetable.isEmpty {
                    Text("Add subjects to build your timetable")
                        .foregroundColor(.white.opacity(0.4))
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(store.timetable.enumerated()), id: \.element.id) { i, entry in
                                HStack {
                                    Text("\(i+1).")
                                        .foregroundColor(.white.opacity(0.4))
                                        .frame(width: 24)
                                    VStack(alignment: .leading) {
                                        Text(entry.subject).foregroundColor(.white).font(.headline)
                                        Text("\(entry.duration) min").foregroundColor(.white.opacity(0.5)).font(.caption)
                                    }
                                    Spacer()
                                    Button { store.removeTimetableEntry(id: entry.id) } label: {
                                        Image(systemName: "minus.circle.fill").foregroundColor(.awayRed)
                                    }
                                }
                                .padding()
                                .glassCard()
                            }
                        }
                        .padding(.horizontal)
                    }

                    let total = store.timetable.reduce(0) { $0 + $1.duration }
                    Text("Total: \(total) min")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.subheadline)

                    Button {
                        showSession = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Full Session")
                        }
                        .font(.headline).bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [.focusGreen, .accentBlue], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showSession) {
            TimetableSessionView(entries: store.timetable).environmentObject(store)
        }
    }
}
