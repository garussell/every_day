//
//  MeditationTimerView.swift
//  every_day
//
//  Meditation timer with circular progress ring, session history via SwiftData,
//  streak tracking, bell tones at start/end, and post-session journal entry.
//

import SwiftUI
import SwiftData

struct MeditationTimerView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var vm             = MeditationViewModel()
    @State private var showJournal    = false
    @State private var isPulsing      = false
    @State private var customMinutes  = 20
    @State private var useCustom      = false

    var body: some View {
        NavigationStack {
            ZStack {
                CelestialBackground()

                if vm.isCompleted {
                    completionView
                } else if vm.isRunning {
                    timerView
                } else {
                    setupView
                }
            }
            .navigationTitle("Meditate")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                vm.loadStats(from: modelContext)
            }
            .sheet(isPresented: $showJournal) {
                JournalEditorView(entry: nil, initialTitle: "Post-Meditation Reflection")
            }
        }
    }

    // MARK: - Setup Screen

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 28) {

                // ── Stats row ─────────────────────────────────────────────
                HStack(spacing: 0) {
                    statPill(label: "Sessions",  value: "\(vm.totalSessions)")
                    Divider()
                        .frame(height: 36)
                        .overlay(Color.white.opacity(0.12))
                    statPill(label: "Minutes",   value: "\(vm.totalMinutes)")
                    Divider()
                        .frame(height: 36)
                        .overlay(Color.white.opacity(0.12))
                    statPill(label: "Day Streak", value: "\(vm.currentStreak)")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.orbitGold.opacity(0.15), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)

                // ── Duration picker ────────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("Duration")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(MeditationDuration.allCases) { preset in
                                durationPill(
                                    label: preset.label,
                                    isSelected: !useCustom && vm.selectedDuration == preset.rawValue
                                ) {
                                    useCustom           = false
                                    vm.selectedDuration = preset.rawValue
                                }
                            }
                            // Custom pill
                            durationPill(
                                label: useCustom ? "\(customMinutes) min" : "Custom",
                                isSelected: useCustom
                            ) {
                                useCustom           = true
                                vm.selectedDuration = customMinutes * 60
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if useCustom {
                        HStack {
                            Text("Custom:")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.55))
                            Stepper(
                                "\(customMinutes) minutes",
                                value: $customMinutes,
                                in: 1...120
                            )
                            .tint(Color.orbitGold)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .onChange(of: customMinutes) { _, v in
                                vm.selectedDuration = v * 60
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // ── Start button ───────────────────────────────────────────
                Button {
                    vm.start(in: modelContext)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("Begin Session")
                            .fontWeight(.semibold)
                    }
                    .font(.title3)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.orbitGold, Color.orbitGold.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.orbitGold.opacity(0.35), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Timer Screen

    private var timerView: some View {
        VStack(spacing: 48) {

            // ── Circular progress ring ─────────────────────────────────────
            ZStack {
                // Outer pulse glow
                Circle()
                    .fill(Color.orbitGold.opacity(0.06))
                    .frame(width: 300, height: 300)
                    .scaleEffect(isPulsing ? 1.10 : 1.0)
                    .animation(
                        isPulsing
                            ? .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
                            : .easeOut(duration: 0.4),
                        value: isPulsing
                    )

                // Track ring
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 18)
                    .frame(width: 250, height: 250)

                // Progress arc
                Circle()
                    .trim(from: 0, to: vm.progress)
                    .stroke(
                        AngularGradient(
                            colors: [Color.orbitGold.opacity(0.6), Color.orbitGold],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: vm.progress)

                // Time + state label
                VStack(spacing: 8) {
                    Text(vm.formattedTimeRemaining)
                        .font(.system(size: 54, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    if vm.isPaused {
                        Text("PAUSED")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.orbitGold.opacity(0.8))
                            .kerning(2)
                    } else {
                        Text(vm.selectedDurationLabel)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.38))
                            .kerning(0.5)
                    }
                }
            }
            .onChange(of: vm.isRunning) { _, running in
                isPulsing = running && !vm.isPaused
            }
            .onChange(of: vm.isPaused) { _, paused in
                isPulsing = vm.isRunning && !paused
            }
            .onAppear { isPulsing = true }
            .onDisappear { isPulsing = false }

            // ── Controls ───────────────────────────────────────────────────
            HStack(spacing: 24) {
                // Stop
                Button {
                    isPulsing = false
                    vm.stop(in: modelContext)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)

                // Pause / Resume
                Button {
                    if vm.isPaused {
                        vm.resume()
                        isPulsing = true
                    } else {
                        vm.pause()
                        isPulsing = false
                    }
                } label: {
                    Image(systemName: vm.isPaused ? "play.fill" : "pause.fill")
                        .font(.title)
                        .foregroundStyle(.black)
                        .frame(width: 72, height: 72)
                        .background(
                            Circle()
                                .fill(Color.orbitGold)
                                .shadow(color: Color.orbitGold.opacity(0.45), radius: 12)
                        )
                }
                .buttonStyle(.plain)

                // Spacer to balance the stop button on the left
                Color.clear
                    .frame(width: 60, height: 60)
            }
        }
    }

    // MARK: - Completion Screen

    private var completionView: some View {
        VStack(spacing: 32) {
            // Celebration icon
            ZStack {
                Circle()
                    .fill(Color.orbitGold.opacity(0.12))
                    .frame(width: 130, height: 130)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.orbitGold)
            }

            VStack(spacing: 8) {
                Text("Session Complete")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Well done. Take a moment to arrive.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }

            // Session stats
            HStack(spacing: 0) {
                statPill(label: "Duration",  value: "\(vm.selectedDuration / 60) min")
                Divider()
                    .frame(height: 36)
                    .overlay(Color.white.opacity(0.12))
                statPill(label: "Sessions",  value: "\(vm.totalSessions)")
                Divider()
                    .frame(height: 36)
                    .overlay(Color.white.opacity(0.12))
                statPill(label: "Day Streak", value: "\(vm.currentStreak)")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.orbitGold.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)

            // Actions
            VStack(spacing: 14) {
                Button {
                    showJournal = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "book.and.wrench.fill")
                        Text("Journal Your Experience")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.orbitGold, Color.orbitGold.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.orbitGold.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                Button {
                    vm.dismissCompletion()
                } label: {
                    Text("Done")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 40)
    }

    // MARK: - Reusable Subviews

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.orbitGold.opacity(0.8))
            .textCase(.uppercase)
            .kerning(0.5)
            .padding(.horizontal, 20)
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private func durationPill(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.75))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.orbitGold : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

}
