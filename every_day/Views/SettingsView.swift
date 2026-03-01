//
//  SettingsView.swift
//  every_day
//
//  Full settings screen. Presented as a sheet from DashboardView.
//  Sections: Profile, Notifications, Meditation, Journal, Data & Privacy, About.
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @Query(sort: \JournalEntry.createdAt, order: .reverse)
    private var entries: [JournalEntry]

    var settingsVM:  SettingsViewModel
    var dashboardVM: DashboardViewModel

    // MARK: - @AppStorage (read by multiple views; source of truth in UserDefaults)

    @AppStorage("defaultMeditationDuration") private var defaultDuration  = 600
    @AppStorage("meditation_bell_sound")     private var defaultBellSound  = BellSound.bell.rawValue
    @AppStorage("showMoodMeter")             private var showMoodMeter     = true

    // MARK: - Local UI state

    @State private var showClearHoroscopeAlert  = false
    @State private var showClearMeditationAlert = false
    @State private var showClearJournalAlert    = false
    @State private var deleteConfirmText        = ""
    @State private var showPermissionAlert      = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                CelestialBackground()

                Form {
                    profileSection
                    notificationsSection
                    meditationSection
                    journalSection
                    dataPrivacySection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .tint(Color.orbitGold)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.orbitGold)
                        .fontWeight(.semibold)
                }
            }
            .alert("Enable Notifications", isPresented: $showPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Notifications are disabled. Go to Settings → Notifications → Daily Orbit to enable them.")
            }
            .onChange(of: settingsVM.notificationPermissionDenied) { _, denied in
                if denied {
                    showPermissionAlert = true
                    settingsVM.notificationPermissionDenied = false
                }
            }
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section {
            // Display name
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(Color.orbitGold)
                    .frame(width: 24)
                TextField("Your name (optional)", text: Binding(
                    get: { settingsVM.displayName },
                    set: { settingsVM.displayName = $0 }
                ))
                .foregroundStyle(.white)
                .submitLabel(.done)
            }

            // Zodiac sign (pushes to sub-list)
            NavigationLink {
                zodiacSignPicker
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.orbitGold)
                        .frame(width: 24)
                    Text("Zodiac Sign")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(dashboardVM.selectedSign.glyph) \(dashboardVM.selectedSign.displayName)")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        } header: {
            sectionHeader("Profile")
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - Zodiac Sign Picker (sub-page)

    private var zodiacSignPicker: some View {
        ZStack {
            CelestialBackground()
            List {
                ForEach(ZodiacSign.allCases) { sign in
                    Button {
                        dashboardVM.changeSign(sign)
                    } label: {
                        HStack(spacing: 14) {
                            Text(sign.glyph)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sign.displayName)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                Text(sign.dateRange)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            Spacer()
                            if dashboardVM.selectedSign == sign {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.orbitGold)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(rowBackground)
                    .listRowSeparatorTint(Color.orbitGold.opacity(0.12))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Zodiac Sign")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            // Daily reflection toggle
            Toggle(isOn: Binding(
                get: { settingsVM.reflectionReminderEnabled },
                set: { enabled in
                    if enabled { settingsVM.enableReflectionReminder() }
                    else       { settingsVM.reflectionReminderEnabled = false }
                }
            )) {
                Label("Daily Reflection Reminder", systemImage: "book.fill")
                    .foregroundStyle(.white)
            }

            if settingsVM.reflectionReminderEnabled {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { settingsVM.reflectionReminderTime },
                        set: { settingsVM.reflectionReminderTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .colorScheme(.dark)
                .foregroundStyle(.white)
            }

            // Meditation toggle
            Toggle(isOn: Binding(
                get: { settingsVM.meditationReminderEnabled },
                set: { enabled in
                    if enabled { settingsVM.enableMeditationReminder() }
                    else       { settingsVM.meditationReminderEnabled = false }
                }
            )) {
                Label("Meditation Reminder", systemImage: "figure.mind.and.body")
                    .foregroundStyle(.white)
            }

            if settingsVM.meditationReminderEnabled {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { settingsVM.meditationReminderTime },
                        set: { settingsVM.meditationReminderTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .colorScheme(.dark)
                .foregroundStyle(.white)
            }
        } header: {
            sectionHeader("Notifications")
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - Meditation

    private var meditationSection: some View {
        Section {
            Picker(selection: $defaultDuration) {
                ForEach(MeditationDuration.allCases) { d in
                    Text(d.label).tag(d.rawValue)
                }
            } label: {
                Label("Default Duration", systemImage: "timer")
                    .foregroundStyle(.white)
            }

            Picker(selection: $defaultBellSound) {
                ForEach(BellSound.allCases) { s in
                    Label(s.label, systemImage: s.sfSymbol).tag(s.rawValue)
                }
            } label: {
                Label("Default Bell Sound", systemImage: "bell.fill")
                    .foregroundStyle(.white)
            }
            .onChange(of: defaultBellSound) { _, newVal in
                BellSound(rawValue: newVal)?.preview()
            }

            Toggle(isOn: Binding(
                get: { settingsVM.showStreakOnHome },
                set: { settingsVM.showStreakOnHome = $0 }
            )) {
                Label("Show Streak on Home Screen", systemImage: "flame.fill")
                    .foregroundStyle(.white)
            }
        } header: {
            sectionHeader("Meditation")
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - Journal

    private var journalSection: some View {
        Section {
            Picker(selection: Binding(
                get: { settingsVM.defaultPromptCategory },
                set: { settingsVM.defaultPromptCategory = $0 }
            )) {
                Text("All").tag("all")
                ForEach(ReflectionCategory.allCases, id: \.rawValue) { cat in
                    Label(cat.rawValue, systemImage: cat.sfSymbol).tag(cat.rawValue)
                }
            } label: {
                Label("Daily Prompt Category", systemImage: "lightbulb.fill")
                    .foregroundStyle(.white)
            }

            Toggle(isOn: $showMoodMeter) {
                Label("Show Mood Meter in Entries", systemImage: "face.smiling.fill")
                    .foregroundStyle(.white)
            }
        } header: {
            sectionHeader("Journal")
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - Data & Privacy

    private var dataPrivacySection: some View {
        Section {
            // Clear horoscope cache
            Button {
                showClearHoroscopeAlert = true
            } label: {
                Label("Clear Horoscope Cache", systemImage: "sparkles.slash")
                    .foregroundStyle(.white)
            }
            .alert("Clear Horoscope Cache?", isPresented: $showClearHoroscopeAlert) {
                Button("Clear", role: .destructive) {
                    HoroscopeCache.clearAllCaches()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All signs will be fetched fresh on next load.")
            }

            // Clear meditation history
            Button {
                showClearMeditationAlert = true
            } label: {
                Label("Clear Meditation History", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
            .alert("Clear Meditation History?", isPresented: $showClearMeditationAlert) {
                Button("Clear", role: .destructive) { clearMeditationHistory() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All meditation session records will be permanently deleted.")
            }

            // Clear all journal entries
            Button {
                deleteConfirmText = ""
                showClearJournalAlert = true
            } label: {
                Label("Clear All Journal Entries", systemImage: "trash.fill")
                    .foregroundStyle(.red)
            }
            .alert("Delete All Journal Entries?", isPresented: $showClearJournalAlert) {
                TextField("Type DELETE to confirm", text: $deleteConfirmText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                Button("Delete All", role: .destructive) {
                    if deleteConfirmText.trimmingCharacters(in: .whitespacesAndNewlines) == "DELETE" {
                        deleteAllJournalEntries()
                    }
                }
                Button("Cancel", role: .cancel) { deleteConfirmText = "" }
            } message: {
                Text("Type DELETE to permanently remove all journal entries. This cannot be undone.")
            }

            // Export journal entries
            if !entries.isEmpty {
                ShareLink(item: journalExportText) {
                    Label("Export Journal Entries", systemImage: "square.and.arrow.up")
                        .foregroundStyle(.white)
                }
            }
        } header: {
            sectionHeader("Data & Privacy")
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            LabeledContent("App") {
                Text("Daily Orbit")
                    .foregroundStyle(.white.opacity(0.55))
            }
            LabeledContent("Version") {
                Text(appVersion)
                    .foregroundStyle(.white.opacity(0.55))
            }
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(Color.orbitGold)
                    .font(.title3)
                Text("Your daily guide through celestial rhythms — weather, moon phases, horoscopes, journaling, and meditation, all in one place.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
            // TODO: Replace with your App Store URL once the app is published.
            // Format: itms-apps://apps.apple.com/app/idXXXXXXXXXX
            Link(destination: URL(string: "https://apps.apple.com")!) {
                Label("Rate Daily Orbit", systemImage: "star.fill")
                    .foregroundStyle(Color.orbitGold)
            }
        } header: {
            sectionHeader("About")
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - Helpers

    private var rowBackground: some View {
        Color.white.opacity(0.05)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.orbitGold.opacity(0.8))
            .textCase(.uppercase)
            .kerning(0.5)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var journalExportText: String {
        guard !entries.isEmpty else { return "" }
        return entries.map { entry in
            var lines = ["Date: \(entry.createdAt.formatted(date: .long, time: .shortened))"]
            if !entry.title.isEmpty { lines.append("Title: \(entry.title)") }
            if let word = entry.moodWord, let q = entry.quadrantEnum {
                lines.append("Mood: \(word) · \(q.title)")
            }
            lines.append("")
            lines.append(entry.body)
            return lines.joined(separator: "\n")
        }
        .joined(separator: "\n\n---\n\n")
    }

    private func clearMeditationHistory() {
        let descriptor = FetchDescriptor<MeditationSession>()
        if let sessions = try? modelContext.fetch(descriptor) {
            sessions.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }
    }

    private func deleteAllJournalEntries() {
        entries.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}
