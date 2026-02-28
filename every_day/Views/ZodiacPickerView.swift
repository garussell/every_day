//
//  ZodiacPickerView.swift
//  every_day
//

import SwiftUI

/// Full-screen sheet shown on first launch so the user can pick their star sign.
struct ZodiacPickerView: View {
    @Binding var selectedSign: ZodiacSign
    let onDismiss: () -> Void

    @State private var appeared = false

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]

    var body: some View {
        ZStack {
            Color.orbitBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                header
                zodiacGrid
                confirmButton
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(dampingFraction: 0.75).delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 8) {
            Text("✨ Choose Your Sign")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -20)
                .animation(.easeOut(duration: 0.5), value: appeared)

            Text("Your daily horoscope will be tailored to you.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
        }
        .padding(.top, 20)
    }

    private var zodiacGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ZodiacSign.allCases) { sign in
                zodiacCell(sign)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
    }

    private func zodiacCell(_ sign: ZodiacSign) -> some View {
        let isSelected = selectedSign == sign

        return Button {
            withAnimation(.spring(dampingFraction: 0.7)) {
                selectedSign = sign
            }
        } label: {
            VStack(spacing: 4) {
                Text(sign.glyph)
                    .font(.system(size: 28))
                Text(sign.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .black : .white)
                Text(sign.dateRange)
                    .font(.system(size: 8))
                    .foregroundStyle(isSelected ? .black.opacity(0.6) : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.orbitGold : Color.orbitCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.orbitGold : Color.orbitGold.opacity(0.2),
                                    lineWidth: 1)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1)
        }
    }

    private var confirmButton: some View {
        Button {
            onDismiss()
        } label: {
            Text("Continue as \(selectedSign.glyph) \(selectedSign.displayName)")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orbitGold)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
    }
}
