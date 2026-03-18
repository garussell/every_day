//
//  JournalDetailView.swift
//  every_day
//
//  Read-only display for all three journal entry types.
//  Routes the edit action to the correct editor view based on entryType.
//

import SwiftUI
import SwiftData

struct JournalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry

    @State private var showingEditor   = false
    @State private var showDeleteAlert = false
    @State private var vm = JournalViewModel()

    var body: some View {
        ZStack {
            CelestialBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Entry type badge + Date header ─────────────────────
                    HStack(spacing: 8) {
                        // Entry type chip
                        HStack(spacing: 4) {
                            Image(systemName: entry.entryTypeEnum.icon)
                                .font(.caption2.weight(.semibold))
                                .accessibilityHidden(true)
                            Text(entry.entryTypeEnum.label)
                                .font(.caption2.weight(.bold))
                                .kerning(0.5)
                        }
                        .foregroundStyle(entry.entryTypeEnum.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(entry.entryTypeEnum.color.opacity(0.15))
                                .overlay(Capsule().stroke(entry.entryTypeEnum.color.opacity(0.35), lineWidth: 1))
                        )

                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.createdAt.formatted(date: .long, time: .omitted))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.orbitGold.opacity(0.8))
                            .textCase(.uppercase)
                            .kerning(0.5)
                        Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    // ── Title ──────────────────────────────────────────────
                    if !entry.title.isEmpty {
                        Text(entry.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    }

                    // ── Dream Clarity (dream entries only) ─────────────────
                    if entry.entryTypeEnum == .dream,
                       let clarityLabel = entry.dreamClarityLabel,
                       let claritySymbol = entry.dreamClaritySymbol {
                        dreamClaritySection(label: clarityLabel, symbol: claritySymbol)
                    }

                    // ── Mood section (any type that recorded mood) ──────────
                    if entry.hasMoodSelection, let quadrant = entry.quadrantEnum {
                        moodSection(quadrant: quadrant)
                    }

                    // ── Energy level (mood entries) ────────────────────────
                    if entry.entryTypeEnum == .mood, let energy = entry.energyLevel {
                        energySection(energy: energy)
                    }

                    // ── Context tags (mood entries) ────────────────────────
                    if entry.entryTypeEnum == .mood, !entry.contextTagsArray.isEmpty {
                        tagsSection(tags: entry.contextTagsArray, color: JournalEntryType.mood.color, label: "Context")
                    }

                    // ── General tags (general entries) ──────────────────────
                    if entry.entryTypeEnum == .general, !entry.generalTagsArray.isEmpty {
                        tagsSection(tags: entry.generalTagsArray, color: JournalEntryType.general.color, label: "Tags")
                    }

                    // ── Body text ───────────────────────────────────────────
                    if !entry.body.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel(bodyLabel)
                            Text(entry.body)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.88))
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // ── Edited timestamp ───────────────────────────────────
                    if entry.createdAt != entry.editedAt {
                        Text("Edited \(entry.editedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: entry.shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.orbitGold)
                }
                .accessibilityLabel("Share entry")
                Button { showingEditor = true } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color.orbitGold)
                }
                .accessibilityLabel("Edit entry")
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.8))
                }
                .accessibilityLabel("Delete entry")
            }
        }
        // Route to correct editor based on entry type
        .sheet(isPresented: $showingEditor) {
            switch entry.entryTypeEnum {
            case .dream:   JournalEditorView(entry: entry)
            case .mood:    MoodCheckInEditorView(entry: entry)
            case .general: GeneralEntryEditorView(entry: entry)
            }
        }
        .alert(deleteAlertTitle, isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                vm.deleteEntry(entry, in: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deleteAlertMessage)
        }
    }

    // MARK: - Labels

    private var bodyLabel: String {
        switch entry.entryTypeEnum {
        case .dream:   return "Dream"
        case .mood:    return "Note"
        case .general: return "Entry"
        }
    }

    private var deleteAlertTitle: String {
        switch entry.entryTypeEnum {
        case .dream:   return "Delete Dream"
        case .mood:    return "Delete Check-in"
        case .general: return "Delete Entry"
        }
    }

    private var deleteAlertMessage: String {
        switch entry.entryTypeEnum {
        case .dream:   return "This dream entry will be permanently deleted."
        case .mood:    return "This mood check-in will be permanently deleted."
        case .general: return "This journal entry will be permanently deleted."
        }
    }

    // MARK: - Dream Clarity Section

    private func dreamClaritySection(label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Dream Clarity")

            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(entry.dreamClarityColor)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { level in
                            Circle()
                                .fill(level <= (entry.dreamClarity ?? 0)
                                      ? entry.dreamClarityColor
                                      : Color.white.opacity(0.15))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .accessibilityHidden(true)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(entry.dreamClarityColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(entry.dreamClarityColor.opacity(0.25), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Mood Section

    private func moodSection(quadrant: MoodQuadrant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Mood")

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(quadrant.color)
                    .frame(width: 6, height: 40)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: quadrant.sfSymbol)
                            .font(.subheadline)
                            .foregroundStyle(quadrant.color)
                            .accessibilityHidden(true)

                        Text(entry.moodWord ?? quadrant.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 6) {
                        Text(quadrant.title)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))

                        Text("·")
                            .foregroundStyle(.white.opacity(0.3))

                        Text(entry.moodStars)
                            .font(.caption)
                            .foregroundStyle(quadrant.color)
                            .accessibilityLabel("Mood score \(quadrant.moodScore) of 5")
                    }
                }

                Spacer()

                moodPositionDot(quadrant: quadrant)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(quadrant.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(quadrant.color.opacity(0.25), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Energy Section

    private func energySection(energy: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Energy Level")

            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    ForEach(1...5, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(level <= energy
                                  ? EnergyLevel.color(for: energy)
                                  : Color.white.opacity(0.12))
                            .frame(width: 28, height: 14)
                    }
                }
                .accessibilityHidden(true)

                Text(EnergyLevel.label(for: energy))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.65))

                Spacer()

                Text("\(energy)/5")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.40))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(JournalEntryType.mood.color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(JournalEntryType.mood.color.opacity(0.20), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Tags Section

    private func tagsSection(tags: [String], color: Color, label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(label)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(color.opacity(0.14))
                                .overlay(Capsule().stroke(color.opacity(0.30), lineWidth: 1))
                        )
                }
            }
        }
    }

    // MARK: - Mini Mood Position Dot

    private func moodPositionDot(quadrant: MoodQuadrant) -> some View {
        let size: CGFloat = 44
        return ZStack {
            HStack(spacing: 1) {
                VStack(spacing: 1) {
                    MoodQuadrant.red.color.opacity(0.7)
                    MoodQuadrant.blue.color.opacity(0.7)
                }
                VStack(spacing: 1) {
                    MoodQuadrant.yellow.color.opacity(0.7)
                    MoodQuadrant.green.color.opacity(0.7)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(width: size, height: size)

            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .shadow(color: quadrant.color, radius: 4)
                .offset(
                    x: (entry.moodX - 0.5) * size,
                    y: (0.5 - entry.moodY) * size
                )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.orbitGold.opacity(0.8))
            .textCase(.uppercase)
            .kerning(0.5)
    }

}
