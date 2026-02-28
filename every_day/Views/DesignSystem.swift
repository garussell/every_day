//
//  DesignSystem.swift
//  every_day
//
//  Shared colors, gradients, and the OrbitCard container used throughout DailyOrbit.
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    /// Deep navy → purple celestial background
    static let orbitBackground = Color(red: 0.04, green: 0.04, blue: 0.16)

    /// Semi-transparent card fill
    static let orbitCard = Color(red: 0.11, green: 0.09, blue: 0.28)

    /// Gold accent for titles, icons, highlights
    static let orbitGold = Color(red: 0.98, green: 0.82, blue: 0.35)

    /// Silver/blue-white tone for moon elements
    static let moonSilver = Color(red: 0.82, green: 0.84, blue: 0.96)
}

// MARK: - Background Gradient

struct CelestialBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.04, blue: 0.18),
                Color(red: 0.10, green: 0.03, blue: 0.26),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - OrbitCard

/// Reusable card container with gold border, shadow, and slide-in animation.
struct OrbitCard<Content: View>: View {
    let delay: Double
    let appeared: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.orbitCard)
                    .shadow(color: .black.opacity(0.45), radius: 16, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        LinearGradient(
                            colors: [Color.orbitGold.opacity(0.5), Color.orbitGold.opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 36)
            .animation(.spring(dampingFraction: 0.78).delay(delay), value: appeared)
    }
}
