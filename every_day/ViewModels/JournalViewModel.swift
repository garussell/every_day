//
//  JournalViewModel.swift
//  every_day
//
//  Handles all journal CRUD operations.
//  ModelContext is passed as a parameter so the ViewModel can be
//  unit-tested with an in-memory container without a SwiftUI environment.
//

import Foundation
import SwiftData

@Observable
final class JournalViewModel {

    // MARK: - State
    var error: String?

    /// Paginated entries currently loaded for display.
    var paginatedEntries: [JournalEntry] = []

    /// Whether more entries may exist beyond what's loaded.
    var hasMoreEntries = true

    /// Number of entries to load per page.
    static let pageSize = 50

    /// Current offset for the next page load.
    private var currentOffset = 0

    // MARK: - Fetch

    /// Returns all entries sorted most-recent first.
    func fetchEntries(
        from context: ModelContext,
        limit: Int? = nil,
        offset: Int = 0
    ) -> [JournalEntry] {
        var descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
            descriptor.fetchOffset = offset
        }
        do {
            return try context.fetch(descriptor)
        } catch {
            self.error = "Failed to load journal entries."
            return []
        }
    }

    /// Loads the initial page of entries, resetting pagination state.
    func loadInitialEntries(from context: ModelContext) {
        currentOffset = 0
        let page = fetchEntries(from: context, limit: Self.pageSize, offset: 0)
        paginatedEntries = page
        hasMoreEntries = page.count >= Self.pageSize
        currentOffset = page.count
    }

    /// Loads the next page and appends to the existing entries.
    func loadMore(from context: ModelContext) {
        guard hasMoreEntries else { return }
        let page = fetchEntries(from: context, limit: Self.pageSize, offset: currentOffset)
        paginatedEntries.append(contentsOf: page)
        hasMoreEntries = page.count >= Self.pageSize
        currentOffset += page.count
    }

    // MARK: - Create

    @discardableResult
    func createEntry(
        title: String,
        body: String,
        moodX: Double = 0.5,
        moodY: Double = 0.5,
        moodQuadrant: String? = nil,
        moodWord: String? = nil,
        dreamClarity: Int? = nil,
        entryType: String = "dream",
        energyLevel: Int? = nil,
        contextTags: String? = nil,
        generalTags: String? = nil,
        date: Date = .now,
        in context: ModelContext
    ) -> JournalEntry {
        let entry = JournalEntry(
            title: title,
            body: body,
            moodX: moodX,
            moodY: moodY,
            moodQuadrant: moodQuadrant,
            moodWord: moodWord,
            dreamClarity: dreamClarity,
            entryType: entryType,
            energyLevel: energyLevel,
            contextTags: contextTags,
            generalTags: generalTags,
            date: date
        )
        context.insert(entry)
        save(context)
        return entry
    }

    // MARK: - Update

    func updateEntry(
        _ entry: JournalEntry,
        title: String,
        body: String,
        moodX: Double,
        moodY: Double,
        moodQuadrant: String?,
        moodWord: String?,
        dreamClarity: Int?,
        entryType: String = "dream",
        energyLevel: Int? = nil,
        contextTags: String? = nil,
        generalTags: String? = nil,
        in context: ModelContext
    ) {
        entry.title        = title
        entry.body         = body
        entry.moodX        = moodX
        entry.moodY        = moodY
        entry.moodQuadrant = moodQuadrant
        entry.moodWord     = moodWord
        entry.dreamClarity = dreamClarity
        entry.entryType    = entryType
        entry.energyLevel  = energyLevel
        entry.contextTags  = contextTags
        entry.generalTags  = generalTags
        entry.editedAt     = .now
        save(context)
    }

    // MARK: - Delete

    func deleteEntry(_ entry: JournalEntry, in context: ModelContext) {
        context.delete(entry)
        save(context)
    }

    // MARK: - Mood Score Helper

    /// Pure helper — convenient for unit tests without a model instance.
    static func moodScore(for quadrant: MoodQuadrant?) -> Int {
        MoodMeter.moodScore(for: quadrant)
    }

    // MARK: - Private

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
        }
    }
}
