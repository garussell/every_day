//
//  DailyReflectionCard.swift
//  every_day
//
//  Displays today's reflection prompt at the top of the Journal list.
//  One prompt per day, changes at midnight, can be favorited and shared.
//

import SwiftUI

struct DailyReflectionCard: View {

    @State private var vm       = ReflectionViewModel()
    @State private var appeared = false
    @State private var showFavorites = false

    @AppStorage("defaultPromptCategory") private var defaultCategory = "all"

    /// Called when the user taps "Reflect" — passes the prompt text as the
    /// pre-filled title for a new journal entry.
    var onReflect: (String) -> Void

    var body: some View {
        OrbitCard(delay: 0, appeared: appeared) {
            VStack(alignment: .leading, spacing: 14) {

                // ── Header row ────────────────────────────────────────────
                HStack(spacing: 6) {
                    Image(systemName: vm.todaysPrompt.category.sfSymbol)
                        .font(.caption2)
                        .foregroundStyle(vm.todaysPrompt.category.color)

                    Text(vm.todaysPrompt.category.rawValue.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(vm.todaysPrompt.category.color)
                        .kerning(0.8)

                    Text("· Today's Prompt")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.38))

                    Spacer()

                    // Favorite
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

                    // Share
                    ShareLink(item: vm.todaysPrompt.text) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white.opacity(0.38))
                            .font(.subheadline)
                    }
                }

                // ── Prompt text ───────────────────────────────────────────
                Text(vm.todaysPrompt.text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.90))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)

                // ── Action row ────────────────────────────────────────────
                HStack {
                    Button {
                        onReflect(vm.todaysPrompt.text)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil.and.list.clipboard")
                                .font(.subheadline)
                            Text("Reflect")
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

                    // Favorites list link
                    if !vm.favoritePrompts.isEmpty {
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
                onReflect(text)
            })
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
                        Text("Tap ♡ on a prompt to save it here.")
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
                                Label("Reflect", systemImage: "pencil.and.list.clipboard")
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
            .navigationTitle("Saved Prompts")
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
