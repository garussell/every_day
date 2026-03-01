//
//  JournalListView.swift
//  every_day
//

import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse)
    private var entries: [JournalEntry]

    @State private var showingEditor         = false
    @State private var reflectionPromptTitle: String? = nil
    @State private var entryToDelete: JournalEntry?
    @State private var showDeleteAlert       = false
    @State private var vm = JournalViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                CelestialBackground()
                entryList
            }
            .navigationTitle("Dream Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        reflectionPromptTitle = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color.orbitGold)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingEditor, onDismiss: { reflectionPromptTitle = nil }) {
                JournalEditorView(entry: nil, initialTitle: reflectionPromptTitle)
            }
            .alert("Delete Entry", isPresented: $showDeleteAlert, presenting: entryToDelete) { entry in
                Button("Delete", role: .destructive) {
                    vm.deleteEntry(entry, in: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("This entry will be permanently deleted.")
            }
        }
    }

    // MARK: - Subviews

    private var entryList: some View {
        List {
            // ── Daily Reflection Prompt card ──────────────────────────────
            Section {
                DailyReflectionCard { promptText in
                    reflectionPromptTitle = promptText
                    showingEditor = true
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // ── Empty state ───────────────────────────────────────────────
            if entries.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.orbitGold.opacity(0.35))
                        Text("No dreams recorded yet")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Tap a prompt above or \(Image(systemName: "square.and.pencil")) to capture your first dream.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.35))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }

            // ── Journal entries ───────────────────────────────────────────
            ForEach(entries) { entry in
                NavigationLink(destination: JournalDetailView(entry: entry)) {
                    JournalRowView(entry: entry)
                }
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(Color.orbitGold.opacity(0.12))
            }
            .onDelete { indexSet in
                if let index = indexSet.first {
                    entryToDelete   = entries[index]
                    showDeleteAlert = true
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - JournalRowView

private struct JournalRowView: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: 10) {
            // Quadrant color bar
            if let quadrant = entry.quadrantEnum {
                RoundedRectangle(cornerRadius: 2)
                    .fill(quadrant.color)
                    .frame(width: 4)
                    .padding(.vertical, 4)
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    // Date chip
                    Text(entry.shortDate)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.orbitGold.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.orbitGold.opacity(0.12)))

                    // Dream clarity indicator
                    if let symbol = entry.dreamClaritySymbol {
                        HStack(spacing: 3) {
                            Image(systemName: symbol)
                                .font(.caption2)
                                .foregroundStyle(entry.dreamClarityColor)
                        }
                    }

                    Spacer()

                    // Mood word + quadrant icon
                    if let word = entry.moodWord, let quadrant = entry.quadrantEnum {
                        HStack(spacing: 4) {
                            Image(systemName: quadrant.sfSymbol)
                                .font(.caption2)
                                .foregroundStyle(quadrant.color)
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
            }
        }
        .padding(.vertical, 4)
    }
}
