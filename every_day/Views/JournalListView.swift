//
//  JournalListView.swift
//  every_day
//
//  Journal home screen supporting Dream, Mood, and General entry types.
//  Shows a daily prompt card, entry type filter, and filtered entry list.
//

import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    /// nil means "All". Selecting a type filters the list.
    @State private var selectedFilter: JournalEntryType? = nil

    @State private var vm = JournalViewModel()

    // Sheet management — separate bools to avoid cascading sheet conflicts
    @State private var showTypeSelector   = false
    @State private var showDreamEditor    = false
    @State private var showMoodEditor     = false
    @State private var showGeneralEditor  = false

    /// Pre-filled prompt text forwarded from the daily card.
    @State private var dreamPromptText:   String? = nil
    @State private var moodPromptText:    String? = nil
    @State private var generalPromptText: String? = nil

    @State private var entryToDelete: JournalEntry?
    @State private var showDeleteAlert = false

    // MARK: - Derived

    private var filteredEntries: [JournalEntry] {
        guard let type = selectedFilter else { return vm.paginatedEntries }
        return vm.paginatedEntries.filter { $0.entryType == type.rawValue }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                CelestialBackground()

                List {
                    // ── Daily prompt card ──────────────────────────────────
                    Section {
                        DailyReflectionCard { promptText, entryType in
                            openEditorFromPrompt(promptText, type: entryType)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    // ── Entry type filter ──────────────────────────────────
                    Section {
                        entryTypeFilter
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    // ── Empty state ────────────────────────────────────────
                    if filteredEntries.isEmpty {
                        Section {
                            emptyState
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }

                    // ── Journal entries ────────────────────────────────────
                    ForEach(filteredEntries) { entry in
                        NavigationLink(destination: JournalDetailView(entry: entry)) {
                            JournalRowView(entry: entry)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Color.orbitGold.opacity(0.12))
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            entryToDelete   = filteredEntries[index]
                            showDeleteAlert = true
                        }
                    }

                    // ── Load more sentinel ────────────────────────────────
                    if vm.hasMoreEntries && selectedFilter == nil {
                        Section {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onAppear {
                                    vm.loadMore(from: modelContext)
                                }
                        }
                    }

                    // Bottom padding for FAB
                    Section {
                        Color.clear.frame(height: 70)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                // ── Floating action button ─────────────────────────────────
                fab
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if vm.paginatedEntries.isEmpty {
                    vm.loadInitialEntries(from: modelContext)
                }
            }
        }
        // Type selector bottom sheet
        .sheet(isPresented: $showTypeSelector) {
            EntryTypeSelectorSheet { selectedType in
                showTypeSelector = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    openNewEditor(for: selectedType, promptText: nil)
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.orbitBackground)
        }
        // Dream editor sheet
        .sheet(isPresented: $showDreamEditor, onDismiss: {
            dreamPromptText = nil
            vm.loadInitialEntries(from: modelContext)
        }) {
            JournalEditorView(entry: nil, initialTitle: dreamPromptText)
        }
        // Mood editor sheet
        .sheet(isPresented: $showMoodEditor, onDismiss: {
            moodPromptText = nil
            vm.loadInitialEntries(from: modelContext)
        }) {
            MoodCheckInEditorView(entry: nil, initialPrompt: moodPromptText)
        }
        // General editor sheet
        .sheet(isPresented: $showGeneralEditor, onDismiss: {
            generalPromptText = nil
            vm.loadInitialEntries(from: modelContext)
        }) {
            GeneralEntryEditorView(entry: nil, initialPrompt: generalPromptText)
        }
        // Delete confirmation
        .alert("Delete Entry", isPresented: $showDeleteAlert, presenting: entryToDelete) { entry in
            Button("Delete", role: .destructive) {
                vm.deleteEntry(entry, in: modelContext)
                vm.loadInitialEntries(from: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This entry will be permanently deleted.")
        }
    }

    // MARK: - Entry Type Filter

    private var entryTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", icon: nil, type: nil)
                ForEach(JournalEntryType.allCases, id: \.rawValue) { type in
                    filterChip(label: type.label, icon: type.icon, type: type)
                }
            }
        }
    }

    private func filterChip(label: String, icon: String?, type: JournalEntryType?) -> some View {
        let isSelected = selectedFilter == type
        let chipColor  = type?.color ?? Color.orbitGold

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                selectedFilter = type
            }
        } label: {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2.weight(.semibold))
                }
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? chipColor.opacity(0.30) : Color.white.opacity(0.07))
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? chipColor.opacity(0.60) : Color.white.opacity(0.15),
                                    lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) filter")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter?.icon ?? "book.closed.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.orbitGold.opacity(0.30))
                .accessibilityHidden(true)

            Text(emptyStateTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))

            Text(emptyStateSubtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .dream:   return "No dreams recorded yet"
        case .mood:    return "No mood check-ins yet"
        case .general: return "No entries yet"
        case .none:    return "No journal entries yet"
        }
    }

    private var emptyStateSubtitle: String {
        switch selectedFilter {
        case .dream:   return "Tap a prompt above or + to capture your first dream."
        case .mood:    return "Tap + to start tracking how you feel."
        case .general: return "Tap + to write freely about anything."
        case .none:    return "Tap a prompt above or + to create your first entry."
        }
    }

    // MARK: - Floating Action Button

    private var fab: some View {
        Button {
            showTypeSelector = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orbitGold.opacity(0.9), Color.orbitGold.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.orbitGold.opacity(0.40), radius: 10, y: 4)

                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.orbitBackground)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New journal entry")
        .accessibilityHint("Choose an entry type to start writing")
    }

    // MARK: - Navigation Helpers

    private func openEditorFromPrompt(_ text: String, type: JournalEntryType) {
        switch type {
        case .dream:
            dreamPromptText = text
            showDreamEditor = true
        case .mood:
            moodPromptText = text
            showMoodEditor = true
        case .general:
            generalPromptText = text
            showGeneralEditor = true
        }
    }

    private func openNewEditor(for type: JournalEntryType, promptText: String?) {
        switch type {
        case .dream:
            dreamPromptText = promptText
            showDreamEditor = true
        case .mood:
            moodPromptText = promptText
            showMoodEditor = true
        case .general:
            generalPromptText = promptText
            showGeneralEditor = true
        }
    }
}

// MARK: - JournalRowView

private struct JournalRowView: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: 10) {
            // Entry type color bar
            let typeColor = entry.entryTypeEnum.color
            RoundedRectangle(cornerRadius: 2)
                .fill(entry.hasMoodSelection ? entry.quadrantColor : typeColor)
                .frame(width: 4)
                .padding(.vertical, 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    // Entry type icon
                    Image(systemName: entry.entryTypeEnum.icon)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(typeColor.opacity(0.85))
                        .accessibilityHidden(true)

                    // Date chip
                    Text(entry.shortDate)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.orbitGold.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.orbitGold.opacity(0.12)))

                    // Dream clarity indicator
                    if entry.entryTypeEnum == .dream, let symbol = entry.dreamClaritySymbol {
                        Image(systemName: symbol)
                            .font(.caption2)
                            .foregroundStyle(entry.dreamClarityColor)
                            .accessibilityLabel("Clarity: \(entry.dreamClarityLabel ?? "")")
                    }

                    // Energy level for mood entries
                    if entry.entryTypeEnum == .mood, let energy = entry.energyLevel {
                        HStack(spacing: 2) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 8))
                            Text("\(energy)")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(JournalEntryType.mood.color.opacity(0.85))
                    }

                    Spacer()

                    // Mood word + quadrant icon
                    if let word = entry.moodWord, let quadrant = entry.quadrantEnum {
                        HStack(spacing: 4) {
                            Image(systemName: quadrant.sfSymbol)
                                .font(.caption2)
                                .foregroundStyle(quadrant.color)
                                .accessibilityHidden(true)
                            Text(word)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }

                // Title or body preview
                Text(entry.displayTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Body preview when title is present
                if !entry.title.isEmpty {
                    Text(entry.body)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(2)
                }

                // Context tags for mood entries
                if entry.entryTypeEnum == .mood, !entry.contextTagsArray.isEmpty {
                    Text(entry.contextTagsArray.prefix(3).joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(JournalEntryType.mood.color.opacity(0.70))
                        .lineLimit(1)
                }

                // General tags
                if entry.entryTypeEnum == .general, !entry.generalTagsArray.isEmpty {
                    Text(entry.generalTagsArray.prefix(3).joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(JournalEntryType.general.color.opacity(0.70))
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - EntryTypeSelectorSheet

private struct EntryTypeSelectorSheet: View {
    let onSelect: (JournalEntryType) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("What would you like to journal?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.top, 24)
                .padding(.bottom, 8)

            ForEach(JournalEntryType.allCases, id: \.rawValue) { type in
                entryTypeRow(type)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func entryTypeRow(_ type: JournalEntryType) -> some View {
        Button {
            onSelect(type)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: type.icon)
                        .font(.title3)
                        .foregroundStyle(type.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(type.label + " Journal")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(entryTypeDescription(type))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.50))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.25))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(type.color.opacity(0.22), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create \(type.label) journal entry")
        .accessibilityHint(entryTypeDescription(type))
    }

    private func entryTypeDescription(_ type: JournalEntryType) -> String {
        switch type {
        case .dream:   return "Capture your dreams before they fade"
        case .mood:    return "How are you feeling right now?"
        case .general: return "Write freely about anything"
        }
    }
}
