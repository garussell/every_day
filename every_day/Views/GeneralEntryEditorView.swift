//
//  GeneralEntryEditorView.swift
//  every_day
//
//  Free-form journal entry with optional mood meter and tags.
//

import SwiftUI
import SwiftData

struct GeneralEntryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    /// Pass nil to create a new entry, or an existing entry to edit it.
    let entry: JournalEntry?
    /// Optional prompt text shown as inspiration at the top.
    var initialPrompt: String? = nil

    // MARK: - Draft State

    @State private var title: String          = ""
    @State private var entryBody: String      = ""
    @State private var entryDate: Date        = .now
    @State private var tags: String           = ""

    // Optional mood meter
    @State private var showMoodMeter          = false
    @State private var moodX: Double          = 0.5
    @State private var moodY: Double          = 0.5
    @State private var hasMoodSelection: Bool = false

    @State private var showDiscardAlert       = false

    @State private var vm = JournalViewModel()

    // MARK: - Computed

    private var isEditing: Bool { entry != nil }
    private var canSave:   Bool { !entryBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var hasChanges: Bool {
        if let e = entry {
            return title != e.title || entryBody != e.body ||
                   hasMoodSelection != e.hasMoodSelection
        }
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               !entryBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                CelestialBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {

                        // ── Daily general prompt banner ──────────────────────
                        let promptText = initialPrompt ?? GeneralPromptLibrary.todaysPrompt()
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "pencil.tip")
                                .font(.caption)
                                .foregroundStyle(JournalEntryType.general.color)
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
                                .fill(JournalEntryType.general.color.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(JournalEntryType.general.color.opacity(0.30), lineWidth: 1)
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
                            .tint(JournalEntryType.general.color)
                        }

                        // ── Title (optional) ─────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Title (optional)")
                            TextField("Give this entry a title...", text: $title)
                                .font(.body)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(fieldBackground)
                        }

                        // ── Body text ────────────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Entry")
                            ZStack(alignment: .topLeading) {
                                if entryBody.isEmpty {
                                    Text("Write freely...")
                                        .font(.body)
                                        .foregroundStyle(.white.opacity(0.35))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                }
                                TextEditor(text: $entryBody)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 150)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                            }
                            .background(fieldBackground)
                        }

                        // ── Optional mood meter ────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showMoodMeter.toggle()
                                    if !showMoodMeter { hasMoodSelection = false }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: showMoodMeter ? "minus.circle" : "plus.circle")
                                        .font(.subheadline)
                                    Text(showMoodMeter ? "Remove Mood" : "Add Mood (optional)")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(.white.opacity(0.55))
                            }
                            .buttonStyle(.plain)

                            if showMoodMeter {
                                MoodMeterView(
                                    moodX: $moodX,
                                    moodY: $moodY,
                                    hasSelection: $hasMoodSelection
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                            }
                        }

                        // ── Tags (optional) ──────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Tags (optional)")
                            TextField("gratitude, work, ideas...", text: $tags)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
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
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
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
                        .foregroundStyle(canSave ? JournalEntryType.general.color : JournalEntryType.general.color.opacity(0.35))
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

    // MARK: - Helpers

    private func loadEntry() {
        guard let e = entry else {
            if let prompt = initialPrompt {
                _ = prompt // prompt is shown in the banner, not pre-filled
            }
            return
        }
        title            = e.title
        entryBody        = e.body
        entryDate        = e.createdAt
        moodX            = e.moodX
        moodY            = e.moodY
        hasMoodSelection = e.hasMoodSelection
        tags             = e.generalTags ?? ""
        if e.hasMoodSelection { showMoodMeter = true }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody  = entryBody.trimmingCharacters(in: .whitespacesAndNewlines)
        let quadrant     = hasMoodSelection ? MoodMeter.quadrant(x: moodX, y: moodY).rawValue : nil
        let word         = hasMoodSelection ? MoodMeter.nearestWord(x: moodX, y: moodY)?.word : nil
        let trimmedTags  = tags.trimmingCharacters(in: .whitespacesAndNewlines)
        let tagsValue    = trimmedTags.isEmpty ? nil : trimmedTags

        if let existing = entry {
            vm.updateEntry(
                existing,
                title:        trimmedTitle,
                body:         trimmedBody,
                moodX:        moodX,
                moodY:        moodY,
                moodQuadrant: quadrant,
                moodWord:     word,
                dreamClarity: nil,
                entryType:    "general",
                energyLevel:  nil,
                contextTags:  nil,
                generalTags:  tagsValue,
                in: modelContext
            )
        } else {
            vm.createEntry(
                title:        trimmedTitle,
                body:         trimmedBody,
                moodX:        moodX,
                moodY:        moodY,
                moodQuadrant: quadrant,
                moodWord:     word,
                dreamClarity: nil,
                entryType:    "general",
                energyLevel:  nil,
                contextTags:  nil,
                generalTags:  tagsValue,
                date:         entryDate,
                in:           modelContext
            )
        }
        dismiss()
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(JournalEntryType.general.color.opacity(0.20), lineWidth: 1)
            )
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(JournalEntryType.general.color.opacity(0.9))
            .textCase(.uppercase)
            .kerning(0.5)
    }
}
