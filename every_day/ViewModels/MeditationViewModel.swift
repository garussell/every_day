//
//  MeditationViewModel.swift
//  every_day
//

import SwiftUI
import SwiftData
import UserNotifications

@Observable final class MeditationViewModel {

    // MARK: - Setup State

    var selectedDuration: Int = {
        let saved = UserDefaults.standard.integer(forKey: "defaultMeditationDuration")
        return saved > 0 ? saved : MeditationDuration.ten.rawValue
    }()

    private var _selectedBellSoundRaw: String =
        UserDefaults.standard.string(forKey: "meditation_bell_sound") ?? BellSound.bell.rawValue

    var selectedBellSound: BellSound {
        get { BellSound(rawValue: _selectedBellSoundRaw) ?? .bell }
        set {
            _selectedBellSoundRaw = newValue.rawValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "meditation_bell_sound")
        }
    }

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

    /// Absolute time when the current session should finish (shifts during pauses).
    private var sessionEndDate: Date?
    /// Time when the current pause began; used to shift sessionEndDate on resume.
    private var pauseStartDate: Date?

    // UserDefaults keys used to recover sessions interrupted by an app kill.
    private static let udKeySessionStart    = "inProgressSessionStart"
    private static let udKeySessionDuration = "inProgressSessionDuration"

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
        timeRemaining  = selectedDuration
        isCompleted    = false
        isRunning      = true
        isPaused       = false
        sessionEndDate = Date.now.addingTimeInterval(Double(selectedDuration))
        pauseStartDate = nil
        bookmarkSession()
        playBell()
        scheduleCompletionNotification()
        scheduleTimer(in: context)
    }

    func pause() {
        isPaused       = true
        pauseStartDate = .now
    }

    func resume() {
        // Shift sessionEndDate forward by the duration of this pause so the
        // absolute end time stays accurate.
        if let pauseStart = pauseStartDate {
            let pauseDuration = Date.now.timeIntervalSince(pauseStart)
            sessionEndDate    = sessionEndDate?.addingTimeInterval(pauseDuration)
            pauseStartDate    = nil
            // Reschedule the notification to the new end time.
            cancelCompletionNotification()
            scheduleCompletionNotification()
        }
        isPaused = false
    }

    func stop(in context: ModelContext) {
        let elapsed = selectedDuration - timeRemaining
        cancelTimer()
        cancelCompletionNotification()
        clearSessionBookmark()
        sessionEndDate = nil
        pauseStartDate = nil
        isRunning      = false
        isPaused       = false
        isCompleted    = false
        timeRemaining  = selectedDuration
        if elapsed >= 30 {
            persist(durationSeconds: elapsed, completed: false, in: context)
        }
    }

    func dismissCompletion() {
        isCompleted   = false
        isRunning     = false
        timeRemaining = selectedDuration
    }

    /// Called when the app returns to the foreground while a session is active.
    /// Recalculates timeRemaining from the absolute sessionEndDate.
    /// If the session ended while backgrounded, completes it immediately.
    func reconcileAfterBackground(in context: ModelContext) {
        guard isRunning, !isPaused, let endDate = sessionEndDate else { return }
        let remaining = Int(endDate.timeIntervalSince(.now))
        if remaining <= 0 {
            complete(in: context)
        } else {
            timeRemaining = remaining
        }
    }

    /// Adds or subtracts seconds from the running session.
    /// Both timeRemaining and selectedDuration shift by the same amount so the
    /// elapsed portion (and therefore the ring's position) stays proportional.
    /// Subtracting clamps timeRemaining to a minimum of 60 s (1 minute).
    func adjustTime(by seconds: Int) {
        if seconds > 0 {
            timeRemaining    += seconds
            selectedDuration += seconds
            sessionEndDate    = sessionEndDate?.addingTimeInterval(Double(seconds))
        } else {
            let subtract = -seconds
            let clamped  = max(60, timeRemaining - subtract)
            let actual   = timeRemaining - clamped
            timeRemaining    = clamped
            selectedDuration -= actual
            sessionEndDate    = sessionEndDate?.addingTimeInterval(-Double(actual))
        }
        // Reschedule the notification only when running — if paused, sessionEndDate
        // hasn't been shifted forward for the current pause yet, so we wait until resume().
        if !isPaused {
            cancelCompletionNotification()
            scheduleCompletionNotification()
        }
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

    /// Checks UserDefaults for a session bookmark left by a previous app run
    /// that was killed before stop()/complete() could clear it.
    /// If one exists and the elapsed time is ≥ 30 s, saves a partial session.
    func recoverOrphanedSession(in context: ModelContext) {
        guard
            let startDate = UserDefaults.standard.object(forKey: Self.udKeySessionStart) as? Date,
            UserDefaults.standard.integer(forKey: Self.udKeySessionDuration) > 0
        else { return }

        let savedDuration = UserDefaults.standard.integer(forKey: Self.udKeySessionDuration)
        clearSessionBookmark()

        // Only recover if we're not currently mid-session (e.g. launched fresh).
        guard !isRunning else { return }

        let elapsed    = Int(Date.now.timeIntervalSince(startDate))
        let actualDur  = min(elapsed, savedDuration)
        let didFinish  = elapsed >= savedDuration

        if actualDur >= 30 {
            persist(durationSeconds: actualDur, completed: didFinish, in: context)
        }
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
        cancelCompletionNotification()
        clearSessionBookmark()
        sessionEndDate = nil
        pauseStartDate = nil
        isRunning      = false
        isCompleted    = true
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

    // MARK: - Session Bookmark (for crash/kill recovery)

    private func bookmarkSession() {
        UserDefaults.standard.set(Date.now,           forKey: Self.udKeySessionStart)
        UserDefaults.standard.set(selectedDuration,   forKey: Self.udKeySessionDuration)
    }

    private func clearSessionBookmark() {
        UserDefaults.standard.removeObject(forKey: Self.udKeySessionStart)
        UserDefaults.standard.removeObject(forKey: Self.udKeySessionDuration)
    }

    // MARK: - Completion Notification

    /// Schedules a local notification for when the session timer will reach zero.
    /// The user sees this notification if the session ends while the app is backgrounded.
    private func scheduleCompletionNotification() {
        guard let endDate = sessionEndDate else { return }
        let interval = endDate.timeIntervalSince(.now)
        guard interval > 0 else { return }

        let content       = UNMutableNotificationContent()
        content.title     = "Meditation Complete"
        content.body      = "Your \(selectedDurationLabel) session is complete. Well done."
        content.sound     = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "meditationComplete",
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelCompletionNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["meditationComplete"])
    }

    // MARK: - Bell

    /// Selects a bell sound, persists it, and previews it immediately.
    func selectBellSound(_ sound: BellSound) {
        selectedBellSound = sound
        previewBell(sound)
    }

    /// Plays the currently selected bell at session start/end.
    private func playBell() {
        previewBell(selectedBellSound)
    }

    private func previewBell(_ sound: BellSound) {
        sound.preview()
    }
}
