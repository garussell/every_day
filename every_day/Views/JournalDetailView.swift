//
//  JournalDetailView.swift
//  every_day
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

                    // ── Date header ────────────────────────────────────────
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

                    // ── Dream Clarity section ─────────────────────────────
                    if let clarityLabel = entry.dreamClarityLabel,
                       let claritySymbol = entry.dreamClaritySymbol {
                        dreamClaritySection(label: clarityLabel, symbol: claritySymbol)
                    }

                    // ── Mood section ───────────────────────────────────────
                    if entry.hasMoodSelection, let quadrant = entry.quadrantEnum {
                        moodSection(quadrant: quadrant)
                    }

                    // ── Dream body ──────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Dream")
                        Text(entry.body)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.88))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
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
                Button { showingEditor = true } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color.orbitGold)
                }
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.8))
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            JournalEditorView(entry: entry)
        }
        .alert("Delete Dream", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                vm.deleteEntry(entry, in: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This dream entry will be permanently deleted.")
        }
    }

    // MARK: - Dream Clarity section

    private func dreamClaritySection(label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Dream Clarity")

            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(entry.dreamClarityColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)

                    // Clarity dots
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { level in
                            Circle()
                                .fill(level <= (entry.dreamClarity ?? 0)
                                    ? entry.dreamClarityColor
                                    : Color.white.opacity(0.15))
                                .frame(width: 8, height: 8)
                        }
                    }
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

    // MARK: - Mood section

    private func moodSection(quadrant: MoodQuadrant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Mood")

            // Pill: icon + word + quadrant name
            HStack(spacing: 12) {
                // Quadrant color indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(quadrant.color)
                    .frame(width: 6, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: quadrant.sfSymbol)
                            .font(.subheadline)
                            .foregroundStyle(quadrant.color)

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
                    }
                }

                Spacer()

                // Mini quadrant position indicator
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

    /// Tiny 40×40 four-quadrant grid showing where the pin was placed.
    private func moodPositionDot(quadrant: MoodQuadrant) -> some View {
        let size: CGFloat = 44
        return ZStack {
            // Mini quadrant grid
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

            // Pin dot
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
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.orbitGold.opacity(0.8))
            .textCase(.uppercase)
            .kerning(0.5)
    }
}
