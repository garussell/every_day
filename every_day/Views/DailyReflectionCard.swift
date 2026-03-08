//
//  DailyReflectionCard.swift
//  every_day
//
//  Displays today's daily prompt at the top of the Journal list.
//  Includes a segmented category selector (Dream / Mood / General)
//  that persists to UserDefaults and drives prompt rotation + Reflect routing.
//

import SwiftUI

struct DailyReflectionCard: View {

    @State private var vm       = ReflectionViewModel()
    @State private var appeared = false
    @State private var showFavorites = false

    @AppStorage("defaultPromptCategory") private var defaultCategory = "all"

    /// Persisted prompt category selection — independent of the list filter.
    @AppStorage("journalPromptCategory") private var savedCategory = "dream"

    /// Called when the user taps "Reflect" — provides prompt text and its entry type.
    var onReflect: (String, JournalEntryType) -> Void

    // MARK: - Derived

    private var promptType: JournalEntryType {
        JournalEntryType(rawValue: savedCategory) ?? .dream
    }

    private var dailyPrompt: JournalDailyPrompt {
        vm.dailyPrompt(for: promptType)
    }

    // MARK: - Body

    var body: some View {
        OrbitCard(delay: 0, appeared: appeared) {
            VStack(alignment: .leading, spacing: 14) {

                // ── Category selector ────────────────────────────────────
                categorySelector

                // ── Header row ───────────────────────────────────────────
                HStack(spacing: 6) {
                    headerIcon
                    headerLabel
                    Text("· Daily Prompt")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.38))

                    Spacer()

                    // Favorite (dream prompts only)
                    if promptType == .dream {
                        Button(action: vm.toggleFavorite) {
                            Image(systemName: vm.isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(
                                    vm.isFavorite
                                        ? Color(red: 0.95, green: 0.40, blue: 0.45)
                                        : .white.opacity(0.38)
                                )
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                    }

                    // Share
                    ShareLink(item: dailyPrompt.text) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white.opacity(0.38))
                            .font(.subheadline)
                    }
                }

                // ── Prompt text ──────────────────────────────────────────
                Text(dailyPrompt.text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.90))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)

                // ── Action row ───────────────────────────────────────────
                HStack {
                    Button {
                        onReflect(dailyPrompt.text, promptType)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: promptType.icon)
                                .font(.subheadline)
                            Text(reflectButtonLabel)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(Color.orbitGold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.orbitGold.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.orbitGold.opacity(0.35), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Favorites list link (dream only)
                    if promptType == .dream, !vm.favoritePrompts.isEmpty {
                        Button {
                            showFavorites = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                Text("\(vm.favoritePrompts.count)")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(Color(red: 0.95, green: 0.40, blue: 0.45).opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .onAppear {
            vm.filterCategory = defaultCategory
            withAnimation(.spring(dampingFraction: 0.78).delay(0.1)) {
                appeared = true
            }
        }
        .onChange(of: defaultCategory) { _, newCat in
            vm.filterCategory = newCat
        }
        .sheet(isPresented: $showFavorites) {
            FavoritePromptsView(vm: vm, onReflect: { text in
                showFavorites = false
                onReflect(text, .dream)
            })
        }
    }

    // MARK: - Category Selector

    private var categorySelector: some View {
        HStack(spacing: 6) {
            ForEach(JournalEntryType.allCases, id: \.rawValue) { type in
                categoryTab(type)
            }
        }
    }

    private func categoryTab(_ type: JournalEntryType) -> some View {
        let isSelected = promptType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                savedCategory = type.rawValue
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: type.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(type.label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.45))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? type.color.opacity(0.30) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? type.color.opacity(0.55) : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header helpers

    @ViewBuilder
    private var headerIcon: some View {
        if promptType == .dream, let dreamPrompt = dailyPrompt.dreamPrompt {
            Image(systemName: dreamPrompt.category.sfSymbol)
                .font(.caption2)
                .foregroundStyle(dreamPrompt.category.color)
        } else {
            Image(systemName: promptType.icon)
                .font(.caption2)
                .foregroundStyle(promptType.color)
        }
    }

    @ViewBuilder
    private var headerLabel: some View {
        if promptType == .dream, let dreamPrompt = dailyPrompt.dreamPrompt {
            Text(dreamPrompt.category.rawValue.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(dreamPrompt.category.color)
                .kerning(0.8)
        } else {
            Text(promptType.label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(promptType.color)
                .kerning(0.8)
        }
    }

    private var reflectButtonLabel: String {
        switch promptType {
        case .dream:   return "Record Dream"
        case .mood:    return "Check In"
        case .general: return "Free Write"
        }
    }
}

// MARK: - FavoritePromptsView

struct FavoritePromptsView: View {
    var vm: ReflectionViewModel
    var onReflect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CelestialBackground()

                if vm.favoritePrompts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.orbitGold.opacity(0.35))
                        Text("No favorites yet")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Tap \u{2661} on a dream prompt to save it here.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.38))
                    }
                } else {
                    List(vm.favoritePrompts) { prompt in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: prompt.category.sfSymbol)
                                    .font(.caption2)
                                    .foregroundStyle(prompt.category.color)
                                Text(prompt.category.rawValue.uppercased())
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(prompt.category.color)
                                    .kerning(0.8)
                            }
                            Text(prompt.text)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.88))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                            Button {
                                onReflect(prompt.text)
                            } label: {
                                Label("Record Dream", systemImage: "moon.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.orbitGold)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Color.orbitGold.opacity(0.12))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Saved Dream Prompts")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.orbitGold)
                }
            }
        }
    }
}
