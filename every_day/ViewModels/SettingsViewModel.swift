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

    // MARK: - Keychain accounts for birth data

    private enum BirthKeys {
        static let date       = "birth_date"
        static let hour       = "birth_hour"
        static let minute     = "birth_minute"
        static let timeKnown  = "birth_time_known"
        static let place      = "birth_place"
        static let chart      = "birth_chart"
    }

    // MARK: - One-time migration from UserDefaults → Keychain

    /// Migrates birth data from UserDefaults to Keychain exactly once.
    /// Guarded by a `didMigrateBirthDataToKeychain` flag in UserDefaults.
    static func migrateBirthDataToKeychainIfNeeded() {
        let flag = "didMigrateBirthDataToKeychain"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }

        let defaults = UserDefaults.standard

        // birthDate (Date → ISO-8601 string)
        if let date = defaults.object(forKey: "birthDate") as? Date {
            let encoded = String(date.timeIntervalSince1970)
            KeychainHelper.save(encoded, for: BirthKeys.date)
            defaults.removeObject(forKey: "birthDate")
        }

        // birthHour (Int → string)
        if defaults.object(forKey: "birthHour") != nil {
            KeychainHelper.save(String(defaults.integer(forKey: "birthHour")), for: BirthKeys.hour)
            defaults.removeObject(forKey: "birthHour")
        }

        // birthMinute (Int → string)
        if defaults.object(forKey: "birthMinute") != nil {
            KeychainHelper.save(String(defaults.integer(forKey: "birthMinute")), for: BirthKeys.minute)
            defaults.removeObject(forKey: "birthMinute")
        }

        // birthTimeKnown (Bool → string)
        if defaults.object(forKey: "birthTimeKnown") != nil {
            KeychainHelper.save(defaults.bool(forKey: "birthTimeKnown") ? "1" : "0", for: BirthKeys.timeKnown)
            defaults.removeObject(forKey: "birthTimeKnown")
        }

        // birthPlace (String)
        if let place = defaults.string(forKey: "birthPlace"), !place.isEmpty {
            KeychainHelper.save(place, for: BirthKeys.place)
            defaults.removeObject(forKey: "birthPlace")
        }

        // birthChart (Data → Keychain raw data)
        if let chartData = defaults.data(forKey: "birthChart") {
            KeychainHelper.saveData(chartData, for: BirthKeys.chart)
            defaults.removeObject(forKey: "birthChart")
        }

        defaults.set(true, forKey: flag)
    }

    // MARK: - Profile

    private var _displayName: String =
        UserDefaults.standard.string(forKey: "displayName") ?? ""

    var displayName: String {
        get { _displayName }
        set { _displayName = newValue; UserDefaults.standard.set(newValue, forKey: "displayName") }
    }

    // MARK: - Birth Chart (Keychain-backed)

    private var _birthDate: Date = {
        if let raw = KeychainHelper.load(for: BirthKeys.date),
           let ti = TimeInterval(raw) {
            return Date(timeIntervalSince1970: ti)
        }
        return Calendar.current.date(byAdding: .year, value: -25, to: .now)!
    }()

    var birthDate: Date {
        get { _birthDate }
        set {
            _birthDate = newValue
            KeychainHelper.save(String(newValue.timeIntervalSince1970), for: BirthKeys.date)
        }
    }

    private var _birthHour: Int = {
        if let raw = KeychainHelper.load(for: BirthKeys.hour), let val = Int(raw) { return val }
        return 0
    }()

    var birthHour: Int {
        get { _birthHour }
        set { _birthHour = newValue; KeychainHelper.save(String(newValue), for: BirthKeys.hour) }
    }

    private var _birthMinute: Int = {
        if let raw = KeychainHelper.load(for: BirthKeys.minute), let val = Int(raw) { return val }
        return 0
    }()

    var birthMinute: Int {
        get { _birthMinute }
        set { _birthMinute = newValue; KeychainHelper.save(String(newValue), for: BirthKeys.minute) }
    }

    private var _birthTimeKnown: Bool = {
        KeychainHelper.load(for: BirthKeys.timeKnown) == "1"
    }()

    var birthTimeKnown: Bool {
        get { _birthTimeKnown }
        set { _birthTimeKnown = newValue; KeychainHelper.save(newValue ? "1" : "0", for: BirthKeys.timeKnown) }
    }

    private var _birthPlace: String = {
        KeychainHelper.load(for: BirthKeys.place) ?? ""
    }()

    var birthPlace: String {
        get { _birthPlace }
        set { _birthPlace = newValue; KeychainHelper.save(newValue, for: BirthKeys.place) }
    }

    /// Cached birth chart result (persisted as JSON in Keychain)
    private var _birthChart: BirthChart? = {
        guard let data = KeychainHelper.loadData(for: BirthKeys.chart) else { return nil }
        return try? JSONDecoder().decode(BirthChart.self, from: data)
    }()

    var birthChart: BirthChart? {
        get { _birthChart }
        set {
            _birthChart = newValue
            if let chart = newValue, let data = try? JSONEncoder().encode(chart) {
                KeychainHelper.saveData(data, for: BirthKeys.chart)
            } else {
                KeychainHelper.delete(for: BirthKeys.chart)
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

    // MARK: - Appearance

    private var _appearanceMode: String =
        UserDefaults.standard.string(forKey: "appearanceMode") ?? "dark"

    var appearanceMode: String {
        get { _appearanceMode }
        set { _appearanceMode = newValue; UserDefaults.standard.set(newValue, forKey: "appearanceMode") }
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
