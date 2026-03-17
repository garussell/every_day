//
//  SettingsViewModel.swift
//  every_day
//
//  Central store for all user-configurable settings.
//  Uses a private backing-var pattern (same as DashboardViewModel.selectedSign)
//  so @Observable correctly tracks every change and persists to UserDefaults.
//

import Foundation
import UserNotifications

@Observable final class SettingsViewModel {

    // MARK: - Profile

    private var _displayName: String =
        UserDefaults.standard.string(forKey: "displayName") ?? ""

    var displayName: String {
        get { _displayName }
        set { _displayName = newValue; UserDefaults.standard.set(newValue, forKey: "displayName") }
    }

    // MARK: - Birth Chart

    private var _birthDate: Date = {
        (UserDefaults.standard.object(forKey: "birthDate") as? Date)
            ?? Calendar.current.date(byAdding: .year, value: -25, to: .now)!
    }()

    var birthDate: Date {
        get { _birthDate }
        set { _birthDate = newValue; UserDefaults.standard.set(newValue, forKey: "birthDate") }
    }

    private var _birthHour: Int = UserDefaults.standard.integer(forKey: "birthHour")
    var birthHour: Int {
        get { _birthHour }
        set { _birthHour = newValue; UserDefaults.standard.set(newValue, forKey: "birthHour") }
    }

    private var _birthMinute: Int = UserDefaults.standard.integer(forKey: "birthMinute")
    var birthMinute: Int {
        get { _birthMinute }
        set { _birthMinute = newValue; UserDefaults.standard.set(newValue, forKey: "birthMinute") }
    }

    private var _birthTimeKnown: Bool = UserDefaults.standard.bool(forKey: "birthTimeKnown")
    var birthTimeKnown: Bool {
        get { _birthTimeKnown }
        set { _birthTimeKnown = newValue; UserDefaults.standard.set(newValue, forKey: "birthTimeKnown") }
    }

    private var _birthPlace: String =
        UserDefaults.standard.string(forKey: "birthPlace") ?? ""

    var birthPlace: String {
        get { _birthPlace }
        set { _birthPlace = newValue; UserDefaults.standard.set(newValue, forKey: "birthPlace") }
    }

    /// Cached birth chart result (persisted as JSON in UserDefaults)
    private var _birthChart: BirthChart? = {
        guard let data = UserDefaults.standard.data(forKey: "birthChart") else { return nil }
        return try? JSONDecoder().decode(BirthChart.self, from: data)
    }()

    var birthChart: BirthChart? {
        get { _birthChart }
        set {
            _birthChart = newValue
            if let chart = newValue, let data = try? JSONEncoder().encode(chart) {
                UserDefaults.standard.set(data, forKey: "birthChart")
            } else {
                UserDefaults.standard.removeObject(forKey: "birthChart")
            }
        }
    }

    /// Whether birth chart has been calculated
    var hasBirthChart: Bool { _birthChart != nil }

    /// Loading state for birth chart calculation
    var isCalculatingBirthChart = false

    /// Error message from last calculation attempt
    var birthChartError: String?

    /// Calculates the birth chart using FreeAstroAPI
    func calculateBirthChart() async {
        guard !birthPlace.isEmpty else {
            birthChartError = "Please enter your birth city."
            return
        }

        isCalculatingBirthChart = true
        birthChartError = nil

        let service = BirthChartService()
        let components = Calendar.current.dateComponents([.day, .month, .year], from: birthDate)

        do {
            let chart = try await service.calculateBirthChart(
                day: components.day ?? 1,
                month: components.month ?? 1,
                year: components.year ?? 2000,
                hour: birthTimeKnown ? birthHour : nil,
                minute: birthTimeKnown ? birthMinute : nil,
                city: birthPlace
            )
            birthChart = chart
        } catch let error as BirthChartError {
            birthChartError = error.errorDescription
        } catch {
            birthChartError = "An unexpected error occurred."
        }

        isCalculatingBirthChart = false
    }

    /// Clears the saved birth chart
    func clearBirthChart() {
        birthChart = nil
    }

    // MARK: - Notifications

    private var _reflectionReminderEnabled: Bool =
        UserDefaults.standard.bool(forKey: "reflectionReminderEnabled")

    var reflectionReminderEnabled: Bool {
        get { _reflectionReminderEnabled }
        set {
            _reflectionReminderEnabled = newValue
            UserDefaults.standard.set(newValue, forKey: "reflectionReminderEnabled")
            if newValue { scheduleReflectionNotification() }
            else { cancelNotification(id: "dailyReflection") }
        }
    }

    private var _reflectionReminderTime: Date = {
        (UserDefaults.standard.object(forKey: "reflectionReminderTime") as? Date)
            ?? Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
    }()

    var reflectionReminderTime: Date {
        get { _reflectionReminderTime }
        set {
            _reflectionReminderTime = newValue
            UserDefaults.standard.set(newValue, forKey: "reflectionReminderTime")
            if reflectionReminderEnabled { scheduleReflectionNotification() }
        }
    }

    private var _meditationReminderEnabled: Bool =
        UserDefaults.standard.bool(forKey: "meditationReminderEnabled")

    var meditationReminderEnabled: Bool {
        get { _meditationReminderEnabled }
        set {
            _meditationReminderEnabled = newValue
            UserDefaults.standard.set(newValue, forKey: "meditationReminderEnabled")
            if newValue { scheduleMeditationNotification() }
            else { cancelNotification(id: "meditationReminder") }
        }
    }

    private var _meditationReminderTime: Date = {
        (UserDefaults.standard.object(forKey: "meditationReminderTime") as? Date)
            ?? Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now)!
    }()

    var meditationReminderTime: Date {
        get { _meditationReminderTime }
        set {
            _meditationReminderTime = newValue
            UserDefaults.standard.set(newValue, forKey: "meditationReminderTime")
            if meditationReminderEnabled { scheduleMeditationNotification() }
        }
    }

    // MARK: - Meditation

    private var _showStreakOnHome: Bool = {
        UserDefaults.standard.object(forKey: "showStreakOnHome") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "showStreakOnHome")
    }()

    var showStreakOnHome: Bool {
        get { _showStreakOnHome }
        set { _showStreakOnHome = newValue; UserDefaults.standard.set(newValue, forKey: "showStreakOnHome") }
    }

    // MARK: - Journal

    private var _defaultPromptCategory: String =
        UserDefaults.standard.string(forKey: "defaultPromptCategory") ?? "all"

    var defaultPromptCategory: String {
        get { _defaultPromptCategory }
        set { _defaultPromptCategory = newValue; UserDefaults.standard.set(newValue, forKey: "defaultPromptCategory") }
    }

    // MARK: - Permission state (drives alert in SettingsView)

    var notificationPermissionDenied = false

    // MARK: - Enable helpers (check / request permission before turning on)

    /// Optimistically turns on the reflection reminder, then checks permission.
    /// Reverts if the user has denied notifications.
    func enableReflectionReminder() {
        enableReminder(
            enabledKeyPath: \._reflectionReminderEnabled,
            defaultsKey: "reflectionReminderEnabled",
            schedule: { self.scheduleNotification(id: "dailyReflection", body: "Your daily reflection is ready ✨", time: self.reflectionReminderTime) }
        )
    }

    /// Optimistically turns on the meditation reminder, then checks permission.
    func enableMeditationReminder() {
        enableReminder(
            enabledKeyPath: \._meditationReminderEnabled,
            defaultsKey: "meditationReminderEnabled",
            schedule: { self.scheduleNotification(id: "meditationReminder", body: "Time for your daily meditation 🧘", time: self.meditationReminderTime) }
        )
    }

    /// Shared logic for optimistically enabling a reminder with permission checks.
    private func enableReminder(
        enabledKeyPath: ReferenceWritableKeyPath<SettingsViewModel, Bool>,
        defaultsKey: String,
        schedule: @escaping () -> Void
    ) {
        self[keyPath: enabledKeyPath] = true
        UserDefaults.standard.set(true, forKey: defaultsKey)

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    schedule()
                case .notDetermined:
                    UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                            Task { @MainActor [weak self] in
                                guard let self else { return }
                                if granted {
                                    schedule()
                                } else {
                                    self[keyPath: enabledKeyPath] = false
                                    UserDefaults.standard.set(false, forKey: defaultsKey)
                                    self.notificationPermissionDenied = true
                                }
                            }
                        }
                default:
                    self[keyPath: enabledKeyPath] = false
                    UserDefaults.standard.set(false, forKey: defaultsKey)
                    self.notificationPermissionDenied = true
                }
            }
        }
    }

    // MARK: - Private scheduling

    func scheduleReflectionNotification() {
        scheduleNotification(id: "dailyReflection", body: "Your daily reflection is ready ✨", time: reflectionReminderTime)
    }

    func scheduleMeditationNotification() {
        scheduleNotification(id: "meditationReminder", body: "Time for your daily meditation 🧘", time: meditationReminderTime)
    }

    private func scheduleNotification(id: String, body: String, time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content   = UNMutableNotificationContent()
        content.title = "Daily Orbit"
        content.body  = body
        content.sound = .default

        var comps     = Calendar.current.dateComponents([.hour, .minute], from: time)
        comps.second  = 0
        let trigger   = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request   = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
