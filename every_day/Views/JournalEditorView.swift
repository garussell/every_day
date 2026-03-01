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

    // Dream Clarity state (1-5, 0 = not set)
    @State private var dreamClarity: Int    = 0

    // MARK: - ViewModel

    @State private var vm = JournalViewModel()

    @AppStorage("showMoodMeter") private var showMoodMeter = true
    @State private var showDiscardAlert = false

    // MARK: - Computed

    private var isEditing: Bool { entry != nil }
    private var canSave: Bool   { !entryBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var hasChanges: Bool {
        if let e = entry {
            let existingClarity = e.dreamClarity ?? 0
            return title != e.title || entryBody != e.body ||
                   hasMoodSelection != e.hasMoodSelection ||
                   moodX != e.moodX || moodY != e.moodY ||
                   dreamClarity != existingClarity
        }
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               !entryBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               dreamClarity > 0
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

                        // ── Dream title ─────────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Dream Title (optional)")
                            TextField("Name this dream...", text: $title)
                                .font(.body)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(fieldBackground)
                        }

                        // ── Dream Clarity ────────────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            fieldLabel("Dream Clarity")
                            DreamClarityPicker(selection: $dreamClarity)
                        }

                        // ── Dream body ────────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Dream Entry")
                            ZStack(alignment: .topLeading) {
                                if entryBody.isEmpty {
                                    Text("Begin writing... let the images come without judgement")
                                        .font(.body)
                                        .foregroundStyle(.white.opacity(0.35))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                }
                                TextEditor(text: $entryBody)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 120)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                            }
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
            .navigationTitle(isEditing ? "Edit Dream" : "New Dream")
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
            dreamClarity     = e.dreamClarity ?? 0
        } else if let initial = initialTitle {
            title = initial
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody  = entryBody.trimmingCharacters(in: .whitespacesAndNewlines)
        let quadrant     = hasMoodSelection ? MoodMeter.quadrant(x: moodX, y: moodY).rawValue : nil
        let word         = hasMoodSelection ? MoodMeter.nearestWord(x: moodX, y: moodY)?.word : nil
        let clarity: Int? = dreamClarity > 0 ? dreamClarity : nil

        if let existing = entry {
            vm.updateEntry(
                existing,
                title: trimmedTitle,
                body: trimmedBody,
                moodX: moodX,
                moodY: moodY,
                moodQuadrant: quadrant,
                moodWord: word,
                dreamClarity: clarity,
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
                dreamClarity: clarity,
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

// MARK: - DreamClarityPicker

/// A 1–5 clarity scale for rating how vividly the dream was remembered.
private struct DreamClarityPicker: View {
    @Binding var selection: Int

    private let levels: [(value: Int, label: String, symbol: String)] = [
        (1, "Barely a feeling", "cloud.fog.fill"),
        (2, "Fragments only", "cloud.fill"),
        (3, "Some scenes", "cloud.moon.fill"),
        (4, "Most of it", "moon.fill"),
        (5, "Vivid and complete", "sparkles"),
    ]

    var body: some View {
        VStack(spacing: 8) {
            // 5 circular buttons in a row
            HStack(spacing: 12) {
                ForEach(levels, id: \.value) { level in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            selection = selection == level.value ? 0 : level.value
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selection == level.value ? clarityColor(level.value) : Color.white.opacity(0.08))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selection == level.value ? clarityColor(level.value) : Color.white.opacity(0.15),
                                            lineWidth: 1.5
                                        )
                                )

                            Image(systemName: level.symbol)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(selection == level.value ? .white : .white.opacity(0.4))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // Label for selected clarity
            if selection > 0, let level = levels.first(where: { $0.value == selection }) {
                Text(level.label)
                    .font(.caption)
                    .foregroundStyle(clarityColor(selection))
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                Text("Tap to rate how clearly you remember this dream")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orbitGold.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func clarityColor(_ value: Int) -> Color {
        switch value {
        case 1: return Color(red: 0.5, green: 0.5, blue: 0.6)
        case 2: return Color(red: 0.55, green: 0.55, blue: 0.7)
        case 3: return Color(red: 0.6, green: 0.6, blue: 0.8)
        case 4: return Color(red: 0.7, green: 0.7, blue: 0.9)
        case 5: return Color(red: 0.85, green: 0.75, blue: 0.95)
        default: return .white.opacity(0.3)
        }
    }
}
