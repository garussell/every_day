//
//  JournalEditorView.swift
//  every_day
//
//  Handles both "create new entry" (entry == nil) and "edit existing" (entry != nil).
//

import SwiftUI
import SwiftData

struct JournalEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Pass nil to create a new entry, or an existing entry to edit it.
    let entry: JournalEntry?
    /// Optional title to pre-fill when creating a new entry (e.g., from a reflection prompt).
    var initialTitle: String? = nil

    // MARK: - Draft State

    @State private var title: String        = ""
    @State private var entryBody: String    = ""
    @State private var entryDate: Date      = .now

    // Mood Meter state
    @State private var moodX: Double        = 0.5
    @State private var moodY: Double        = 0.5
    @State private var hasMoodSelection: Bool = false

    // MARK: - ViewModel

    @State private var vm = JournalViewModel()

    @AppStorage("showMoodMeter") private var showMoodMeter = true
    @State private var showDiscardAlert = false

    // MARK: - Computed

    private var isEditing: Bool { entry != nil }
    private var canSave: Bool   { !entryBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var hasChanges: Bool {
        if let e = entry {
            return title != e.title || entryBody != e.body ||
                   hasMoodSelection != e.hasMoodSelection ||
                   moodX != e.moodX || moodY != e.moodY
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
                    VStack(alignment: .leading, spacing: 20) {

                        // ── Date picker ────────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Date & Time")
                            DatePicker(
                                "",
                                selection: $entryDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .colorScheme(.dark)
                            .tint(Color.orbitGold)
                        }

                        // ── Title field ─────────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Title (optional)")
                            TextField("Give your entry a title…", text: $title)
                                .font(.body)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(fieldBackground)
                        }

                        // ── Journal body ────────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Journal Entry")
                            TextEditor(text: $entryBody)
                                .font(.body)
                                .foregroundStyle(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 90)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 10)
                                .background(fieldBackground)
                        }

                        // ── Mood Meter (hidden when user disables in Settings) ──
                        if showMoodMeter {
                            VStack(alignment: .leading, spacing: 10) {
                                fieldLabel("Mood Meter")
                                MoodMeterView(
                                    moodX: $moodX,
                                    moodY: $moodY,
                                    hasSelection: $hasMoodSelection
                                )
                            }
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

                // ── Scroll fade gradient (Option G) ────────────────────────
                // Signals more content below without any interaction overhead.
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
                        .foregroundStyle(canSave ? Color.orbitGold : Color.orbitGold.opacity(0.35))
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
        if let e = entry {
            title            = e.title
            entryBody        = e.body
            entryDate        = e.createdAt
            moodX            = e.moodX
            moodY            = e.moodY
            hasMoodSelection = e.hasMoodSelection
        } else if let initial = initialTitle {
            title = initial
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody  = entryBody.trimmingCharacters(in: .whitespacesAndNewlines)
        let quadrant     = hasMoodSelection ? MoodMeter.quadrant(x: moodX, y: moodY).rawValue : nil
        let word         = hasMoodSelection ? MoodMeter.nearestWord(x: moodX, y: moodY)?.word : nil

        if let existing = entry {
            vm.updateEntry(
                existing,
                title: trimmedTitle,
                body: trimmedBody,
                moodX: moodX,
                moodY: moodY,
                moodQuadrant: quadrant,
                moodWord: word,
                in: modelContext
            )
        } else {
            vm.createEntry(
                title: trimmedTitle,
                body: trimmedBody,
                moodX: moodX,
                moodY: moodY,
                moodQuadrant: quadrant,
                moodWord: word,
                date: entryDate,
                in: modelContext
            )
        }
        dismiss()
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orbitGold.opacity(0.2), lineWidth: 1)
            )
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.orbitGold.opacity(0.8))
            .textCase(.uppercase)
            .kerning(0.5)
    }
}
