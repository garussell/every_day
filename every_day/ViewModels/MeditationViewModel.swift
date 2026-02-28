//
//  MeditationViewModel.swift
//  every_day
//

import SwiftUI
import SwiftData
import AudioToolbox

@Observable final class MeditationViewModel {

    // MARK: - Setup State

    var selectedDuration: Int = MeditationDuration.ten.rawValue

    // MARK: - Timer State

    var timeRemaining: Int = MeditationDuration.ten.rawValue
    var isRunning: Bool    = false
    var isPaused: Bool     = false
    var isCompleted: Bool  = false

    // MARK: - Stats (loaded from SwiftData)

    var currentStreak: Int = 0
    var totalSessions: Int = 0
    var totalMinutes: Int  = 0

    // MARK: - Private

    private var timer: Timer?

    // MARK: - Computed

    var progress: Double {
        guard selectedDuration > 0 else { return 0 }
        return Double(selectedDuration - timeRemaining) / Double(selectedDuration)
    }

    var formattedTimeRemaining: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    var selectedDurationLabel: String {
        let m = selectedDuration / 60
        let s = selectedDuration % 60
        return s == 0 ? "\(m) min" : "\(m)m \(s)s"
    }

    // MARK: - Timer Control

    func start(in context: ModelContext) {
        timeRemaining = selectedDuration
        isCompleted   = false
        isRunning     = true
        isPaused      = false
        playBell()
        scheduleTimer(in: context)
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }

    func stop(in context: ModelContext) {
        let elapsed = selectedDuration - timeRemaining
        cancelTimer()
        isRunning     = false
        isPaused      = false
        isCompleted   = false
        timeRemaining = selectedDuration
        if elapsed >= 30 {
            persist(durationSeconds: elapsed, completed: false, in: context)
        }
    }

    func dismissCompletion() {
        isCompleted   = false
        isRunning     = false
        timeRemaining = selectedDuration
    }

    // MARK: - Stats

    func loadStats(from context: ModelContext) {
        let descriptor = FetchDescriptor<MeditationSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let sessions = try? context.fetch(descriptor) else { return }
        totalSessions = sessions.count
        totalMinutes  = sessions.reduce(0) { $0 + $1.durationSeconds } / 60
        currentStreak = calculateStreak(from: sessions)
    }

    // MARK: - Private Helpers

    private func scheduleTimer(in context: ModelContext) {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, self.isRunning, !self.isPaused else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.complete(in: context)
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func complete(in context: ModelContext) {
        cancelTimer()
        isRunning   = false
        isCompleted = true
        playBell()
        persist(durationSeconds: selectedDuration, completed: true, in: context)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func persist(durationSeconds: Int, completed: Bool, in context: ModelContext) {
        let session = MeditationSession(
            durationSeconds: durationSeconds,
            completedFully:  completed
        )
        context.insert(session)
        try? context.save()
        loadStats(from: context)
    }

    private func calculateStreak(from sessions: [MeditationSession]) -> Int {
        let calendar    = Calendar.current
        var streak      = 0
        var checkDate   = calendar.startOfDay(for: .now)
        let sessionDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        while sessionDays.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    // MARK: - Bell

    /// Plays system sound 1013 — a short bell tone.
    /// No audio files required; uses iOS built-in system sounds.
    private func playBell() {
        AudioServicesPlaySystemSound(1013)
    }
}
