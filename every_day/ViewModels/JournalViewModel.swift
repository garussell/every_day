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

    // MARK: - Fetch

    /// Returns all entries sorted most-recent first.
    func fetchEntries(from context: ModelContext) -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            self.error = "Failed to load journal entries."
            return []
        }
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
        in context: ModelContext
    ) {
        entry.title        = title
        entry.body         = body
        entry.moodX        = moodX
        entry.moodY        = moodY
        entry.moodQuadrant = moodQuadrant
        entry.moodWord     = moodWord
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
