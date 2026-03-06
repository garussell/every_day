//
//  MoodCheckInEditorView.swift
//  every_day
//
//  Quick mood check-in entry — focused on emotional state.
//  Can create a new mood entry or edit an existing one.
//

import SwiftUI
import SwiftData

struct MoodCheckInEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    /// Pass nil to create a new entry, or an existing entry to edit it.
    let entry: JournalEntry?
    /// Optional prompt text shown as the reflection question.
    var initialPrompt: String? = nil

    // MARK: - Draft State

    @State private var moodX: Double        = 0.5
    @State private var moodY: Double        = 0.5
    @State private var hasMoodSelection     = false
    @State private var energyLevel: Int     = 3
    @State private var selectedTags: Set<String> = []
    @State private var customTagInput       = ""
    @State private var note: String         = ""
    @State private var entryDate: Date      = .now
    @State private var showDiscardAlert     = false

    @State private var vm = JournalViewModel()

    // MARK: - Constants

    private let predefinedTags = [
        "Work", "Family", "Health", "Relationship",
        "Sleep", "Exercise", "Food", "Weather",
        "Social", "Finances", "Creative", "Spiritual",
    ]

    // MARK: - Computed

    private var isEditing: Bool { entry != nil }
    private var canSave:   Bool { hasMoodSelection }

    private var hasChanges: Bool {
        if entry != nil { return true }
        return hasMoodSelection || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                CelestialBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Daily mood prompt ───────────────────────────────
                        let promptText = initialPrompt ?? MoodPromptLibrary.todaysPrompt()
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(JournalEntryType.mood.color)
                                .padding(.top, 2)
                            Text(promptText)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(JournalEntryType.mood.color.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(JournalEntryType.mood.color.opacity(0.30), lineWidth: 1)
                                )
                        )

                        // ── Date picker ──────────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Date & Time")
                            DatePicker(
                                "",
                                selection: $entryDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .colorScheme(.dark)
                            .tint(JournalEntryType.mood.color)
                        }

                        // ── Mood Meter (large, prominent) ──────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            fieldLabel("Mood")
                            MoodMeterView(
                                moodX: $moodX,
                                moodY: $moodY,
                                hasSelection: $hasMoodSelection
                            )
                            .frame(height: 300)
                        }

                        // ── Energy Level ──────────────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            fieldLabel("Energy Level")
                            EnergyLevelPicker(selection: $energyLevel)
                        }

                        // ── Context Tags ──────────────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            fieldLabel("Context")
                            contextTagsGrid
                            customTagRow
                        }

                        // ── Short note ────────────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Note (optional)")
                            ZStack(alignment: .topLeading) {
                                if note.isEmpty {
                                    Text("Anything on your mind?")
                                        .font(.body)
                                        .foregroundStyle(.white.opacity(0.35))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                }
                                TextEditor(text: $note)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 90)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                            }
                            .background(fieldBackground)
                        }

                        // ── Last edited footer ──────────────────────────────
                        if let e = entry, e.createdAt != e.editedAt {
                            Text("Last edited \(e.editedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.35))
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .scrollDismissesKeyboard(.interactively)

                // Scroll fade gradient
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, Color.orbitBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 70)
                }
                .allowsHitTesting(false)
            }
            .navigationTitle(isEditing ? "Edit Check-in" : "Mood Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges { showDiscardAlert = true } else { dismiss() }
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .foregroundStyle(canSave ? JournalEntryType.mood.color : JournalEntryType.mood.color.opacity(0.35))
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadEntry)
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Your unsaved changes will be lost.")
            }
        }
    }

    // MARK: - Context Tags Grid

    private var contextTagsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
            ForEach(predefinedTags, id: \.self) { tag in
                Button {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                } label: {
                    Text(tag)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(selectedTags.contains(tag) ? .white : .white.opacity(0.55))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(selectedTags.contains(tag)
                                      ? JournalEntryType.mood.color.opacity(0.30)
                                      : Color.white.opacity(0.07))
                                .overlay(
                                    Capsule()
                                        .stroke(selectedTags.contains(tag)
                                                ? JournalEntryType.mood.color.opacity(0.55)
                                                : Color.white.opacity(0.15),
                                                lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Custom Tag Row

    private var customTagRow: some View {
        HStack(spacing: 8) {
            TextField("Add custom tag...", text: $customTagInput)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(fieldBackground)
                .submitLabel(.done)
                .onSubmit { addCustomTag() }

            Button(action: addCustomTag) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(JournalEntryType.mood.color)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .opacity(customTagInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.35 : 1)
        }
    }

    // MARK: - Helpers

    private func addCustomTag() {
        let trimmed = customTagInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        selectedTags.insert(trimmed)
        customTagInput = ""
    }

    private func loadEntry() {
        guard let e = entry else { return }
        note             = e.body
        moodX            = e.moodX
        moodY            = e.moodY
        hasMoodSelection = e.hasMoodSelection
        energyLevel      = e.energyLevel ?? 3
        entryDate        = e.createdAt
        if let tags = e.contextTags, !tags.isEmpty {
            selectedTags = Set(
                tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            )
        }
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let quadrant    = hasMoodSelection ? MoodMeter.quadrant(x: moodX, y: moodY).rawValue : nil
        let word        = hasMoodSelection ? MoodMeter.nearestWord(x: moodX, y: moodY)?.word : nil
        let allTags     = selectedTags.sorted().joined(separator: ", ")
        let tagsValue   = allTags.isEmpty ? nil : allTags

        if let existing = entry {
            vm.updateEntry(
                existing,
                title:       "",
                body:        trimmedNote,
                moodX:       moodX,
                moodY:       moodY,
                moodQuadrant: quadrant,
                moodWord:    word,
                dreamClarity: nil,
                entryType:   "mood",
                energyLevel: energyLevel,
                contextTags: tagsValue,
                generalTags: nil,
                in: modelContext
            )
        } else {
            vm.createEntry(
                title:       "",
                body:        trimmedNote,
                moodX:       moodX,
                moodY:       moodY,
                moodQuadrant: quadrant,
                moodWord:    word,
                dreamClarity: nil,
                entryType:   "mood",
                energyLevel: energyLevel,
                contextTags: tagsValue,
                generalTags: nil,
                date:        entryDate,
                in:          modelContext
            )
        }
        dismiss()
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(JournalEntryType.mood.color.opacity(0.20), lineWidth: 1)
            )
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(JournalEntryType.mood.color.opacity(0.9))
            .textCase(.uppercase)
            .kerning(0.5)
    }
}

// MARK: - EnergyLevelPicker

private struct EnergyLevelPicker: View {
    @Binding var selection: Int

    private let levels: [(value: Int, label: String)] = [
        (1, "Exhausted"),
        (2, "Low"),
        (3, "Moderate"),
        (4, "High"),
        (5, "Energized"),
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(levels, id: \.value) { level in
                Button {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                        selection = level.value
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text("\(level.value)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(selection == level.value ? .white : .white.opacity(0.45))
                        Text(level.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(selection == level.value ? .white.opacity(0.85) : .white.opacity(0.35))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selection == level.value
                                  ? energyColor(level.value)
                                  : Color.white.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selection == level.value
                                            ? energyColor(level.value).opacity(0.6)
                                            : Color.white.opacity(0.12),
                                            lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func energyColor(_ value: Int) -> Color {
        switch value {
        case 1: return Color(red: 0.45, green: 0.45, blue: 0.75)  // muted indigo
        case 2: return Color(red: 0.55, green: 0.50, blue: 0.80)
        case 3: return Color(red: 0.75, green: 0.55, blue: 0.75)
        case 4: return Color(red: 0.90, green: 0.55, blue: 0.60)
        case 5: return JournalEntryType.mood.color
        default: return .white.opacity(0.3)
        }
    }
}
