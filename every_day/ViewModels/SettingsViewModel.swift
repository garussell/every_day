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
        _reflectionReminderEnabled = true
        UserDefaults.standard.set(true, forKey: "reflectionReminderEnabled")

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self.scheduleReflectionNotification()
                case .notDetermined:
                    UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                            Task { @MainActor [weak self] in
                                guard let self else { return }
                                if granted {
                                    self.scheduleReflectionNotification()
                                } else {
                                    self._reflectionReminderEnabled = false
                                    UserDefaults.standard.set(false, forKey: "reflectionReminderEnabled")
                                    self.notificationPermissionDenied = true
                                }
                            }
                        }
                default:
                    self._reflectionReminderEnabled = false
                    UserDefaults.standard.set(false, forKey: "reflectionReminderEnabled")
                    self.notificationPermissionDenied = true
                }
            }
        }
    }

    /// Optimistically turns on the meditation reminder, then checks permission.
    func enableMeditationReminder() {
        _meditationReminderEnabled = true
        UserDefaults.standard.set(true, forKey: "meditationReminderEnabled")

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self.scheduleMeditationNotification()
                case .notDetermined:
                    UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                            Task { @MainActor [weak self] in
                                guard let self else { return }
                                if granted {
                                    self.scheduleMeditationNotification()
                                } else {
                                    self._meditationReminderEnabled = false
                                    UserDefaults.standard.set(false, forKey: "meditationReminderEnabled")
                                    self.notificationPermissionDenied = true
                                }
                            }
                        }
                default:
                    self._meditationReminderEnabled = false
                    UserDefaults.standard.set(false, forKey: "meditationReminderEnabled")
                    self.notificationPermissionDenied = true
                }
            }
        }
    }

    // MARK: - Private scheduling

    private func scheduleReflectionNotification() {
        let center  = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReflection"])

        let content       = UNMutableNotificationContent()
        content.title     = "Daily Orbit"
        content.body      = "Your daily reflection is ready ✨"
        content.sound     = .default

        var comps         = Calendar.current.dateComponents([.hour, .minute], from: reflectionReminderTime)
        comps.second      = 0
        let trigger       = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request       = UNNotificationRequest(identifier: "dailyReflection", content: content, trigger: trigger)
        center.add(request)
    }

    private func scheduleMeditationNotification() {
        let center  = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["meditationReminder"])

        let content       = UNMutableNotificationContent()
        content.title     = "Daily Orbit"
        content.body      = "Time for your daily meditation 🧘"
        content.sound     = .default

        var comps         = Calendar.current.dateComponents([.hour, .minute], from: meditationReminderTime)
        comps.second      = 0
        let trigger       = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request       = UNNotificationRequest(identifier: "meditationReminder", content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
