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
    @Environment(\.scenePhase)   private var scenePhase
    @State private var vm             = MeditationViewModel()
    @State private var showJournal    = false
    @State private var isPulsing      = false
    @State private var customMinutes  = 20
    @State private var useCustom      = false
    @State private var holdTimer: Timer?
    @State private var isHolding      = false

    // Setup screen state
    @State private var breatheIn      = false
    @State private var buttonPulse    = false
    @State private var intention      = ""

    // Sync default duration and bell sound from Settings without restarting the VM
    @AppStorage("defaultMeditationDuration") private var defaultDuration = 600
    @AppStorage("meditation_bell_sound")     private var defaultBellSound = BellSound.bell.rawValue

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
                // Recover any session that was interrupted by an app kill/crash.
                vm.recoverOrphanedSession(in: modelContext)
                vm.loadStats(from: modelContext)
                // Apply defaults from Settings if not mid-session
                if !vm.isRunning {
                    if defaultDuration > 0 { vm.selectedDuration = defaultDuration }
                    if let sound = BellSound(rawValue: defaultBellSound) {
                        vm.selectedBellSound = sound
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    vm.reconcileAfterBackground(in: modelContext)
                }
            }
            .onChange(of: defaultDuration) { _, newVal in
                if !vm.isRunning, newVal > 0 { vm.selectedDuration = newVal }
            }
            .onChange(of: defaultBellSound) { _, newVal in
                if !vm.isRunning, let sound = BellSound(rawValue: newVal) {
                    vm.selectedBellSound = sound
                }
            }
            .sheet(isPresented: $showJournal) {
                JournalEditorView(entry: nil, initialTitle: "Post-Meditation Reflection")
            }
        }
    }

    // MARK: - Setup Screen

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 36) {

                // ── Stats row (refined frosted glass) ────────────────────
                HStack(spacing: 0) {
                    setupStatPill(label: "Sessions",  value: "\(vm.totalSessions)")
                    setupStatDivider
                    setupStatPill(label: "Minutes",   value: "\(vm.totalMinutes)")
                    setupStatDivider
                    setupStatPill(label: "Streak",    value: "\(vm.currentStreak)")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 32)

                // ── Breathing orb ────────────────────────────────────────
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.orbitGold.opacity(0.08),
                                    Color.orbitGold.opacity(0.02),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(breatheIn ? 1.12 : 0.92)

                    // Inner orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.orbitGold.opacity(0.18),
                                    Color.orbitGold.opacity(0.06),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(breatheIn ? 1.08 : 0.95)

                    // Duration display
                    VStack(spacing: 4) {
                        Text("\(vm.selectedDuration / 60)")
                            .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                        Text("minutes")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.40))
                            .kerning(1)
                            .textCase(.uppercase)
                    }
                }
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 4.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        breatheIn = true
                    }
                }

                // ── Duration cards ───────────────────────────────────────
                VStack(spacing: 12) {
                    sectionLabel("Duration")

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(MeditationDuration.allCases) { preset in
                            durationCard(
                                label: preset.label,
                                isSelected: !useCustom && vm.selectedDuration == preset.rawValue
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    useCustom           = false
                                    vm.selectedDuration = preset.rawValue
                                }
                            }
                        }
                        durationCard(
                            label: useCustom ? "\(customMinutes) min" : "Custom",
                            isSelected: useCustom
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                useCustom           = true
                                vm.selectedDuration = customMinutes * 60
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    if useCustom {
                        HStack {
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
                        .padding(.horizontal, 24)
                    }
                }

                // ── Sound selector (icon buttons) ────────────────────────
                VStack(spacing: 12) {
                    sectionLabel("Sound")

                    HStack(spacing: 16) {
                        ForEach(BellSound.allCases) { sound in
                            soundIconButton(
                                sound: sound,
                                isSelected: vm.selectedBellSound == sound
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // ── Intention field ──────────────────────────────────────
                VStack(spacing: 8) {
                    TextField("Set an intention (optional)", text: $intention)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .tint(Color.orbitGold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                                )
                        )
                        .onChange(of: intention) { _, newVal in
                            if newVal.count > 60 {
                                intention = String(newVal.prefix(60))
                            }
                        }
                }
                .padding(.horizontal, 24)

                // ── Begin Session button (pulsing) ───────────────────────
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
                    .shadow(
                        color: Color.orbitGold.opacity(buttonPulse ? 0.45 : 0.20),
                        radius: buttonPulse ? 16 : 8,
                        y: 6
                    )
                    .scaleEffect(buttonPulse ? 1.015 : 1.0)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 2.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        buttonPulse = true
                    }
                }

                Spacer(minLength: 48)
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Timer Screen

    private var timerView: some View {
        VStack(spacing: 32) {

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

            // ── Time adjustment ────────────────────────────────────────────
            HStack(spacing: 10) {
                timeAdjustButton(delta: -300, label: "−5m")
                timeAdjustButton(delta: -60,  label: "−1m")
                timeAdjustButton(delta: +60,  label: "+1m")
                timeAdjustButton(delta: +300, label: "+5m")
            }

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
        .onDisappear {
            holdTimer?.invalidate()
            holdTimer = nil
            isHolding = false
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

    /// A tap-and-hold time adjustment button.
    /// Single tap applies delta once; holding repeats at 0.2 s intervals.
    private func timeAdjustButton(delta: Int, label: String) -> some View {
        Text(label)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 54, height: 34)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isHolding else { return }
                        isHolding = true
                        vm.adjustTime(by: delta)
                        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                            vm.adjustTime(by: delta)
                        }
                        RunLoop.main.add(holdTimer!, forMode: .common)
                    }
                    .onEnded { _ in
                        isHolding = false
                        holdTimer?.invalidate()
                        holdTimer = nil
                    }
            )
    }

    // MARK: - Setup Helpers

    private var setupStatDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 0.5, height: 28)
    }

    private func setupStatPill(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .textCase(.uppercase)
                .kerning(0.3)
        }
        .frame(maxWidth: .infinity)
    }

    private func durationCard(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.70))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Color.orbitGold : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isSelected ? Color.orbitGold.opacity(0.6) : Color.white.opacity(0.08),
                                    lineWidth: isSelected ? 1.5 : 0.5
                                )
                        )
                )
                .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private func soundIconButton(sound: BellSound, isSelected: Bool) -> some View {
        Button {
            vm.selectBellSound(sound)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.orbitGold.opacity(0.15) : Color.white.opacity(0.04))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.orbitGold : Color.white.opacity(0.08),
                                    lineWidth: isSelected ? 1.5 : 0.5
                                )
                        )

                    Image(systemName: sound.sfSymbol)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? Color.orbitGold : .white.opacity(0.50))
                }

                if isSelected {
                    Text(sound.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.orbitGold.opacity(0.85))
                        .kerning(0.2)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

}
