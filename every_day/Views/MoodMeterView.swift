//
//  MoodMeterView.swift
//  every_day
//
//  Interactive 2-D Mood Meter based on Marc Brackett's work from the
//  Yale Center for Emotional Intelligence.
//
//  Coordinate convention (conceptual space):
//    moodX  0.0 = far left / Unpleasant  →  1.0 = far right / Pleasant
//    moodY  0.0 = bottom   / Low Energy  →  1.0 = top       / High Energy
//
//  Screen mapping inside the square grid of side `size`:
//    screenX = moodX × size
//    screenY = (1 − moodY) × size   ← Y is inverted in UIKit/SwiftUI

import SwiftUI

struct MoodMeterView: View {

    @Binding var moodX: Double
    @Binding var moodY: Double
    @Binding var hasSelection: Bool

    @State private var isDragging = false

    // MARK: - Computed

    private var currentQuadrant: MoodQuadrant { MoodMeter.quadrant(x: moodX, y: moodY) }
    private var nearestWord: MoodWord?         { MoodMeter.nearestWord(x: moodX, y: moodY) }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 6) {
            axisCaption("HIGH ENERGY", icon: "arrow.up")

            HStack(spacing: 6) {
                verticalAxisLabel("UNPLEASANT")

                // ── The square grid ───────────────────────────────────────
                GeometryReader { geo in
                    let size = geo.size.width
                    ZStack(alignment: .topLeading) {
                        quadrantBackgrounds(size: size)
                        centerDividers(size: size)
                        quadrantCornerLabels(size: size)
                        wordLabels(size: size)
                        if hasSelection { pin(size: size) }
                        gestureLayer(size: size)
                    }
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .aspectRatio(1, contentMode: .fit)

                verticalAxisLabel("PLEASANT")
            }

            axisCaption("LOW ENERGY", icon: "arrow.down")

            // ── Emotion indicator ────────────────────────────────────────
            emotionIndicator
        }
    }

    // MARK: - Quadrant backgrounds

    private func quadrantBackgrounds(size: CGFloat) -> some View {
        let half = size / 2
        return ZStack(alignment: .topLeading) {
            // Top-left: Red (unpleasant, high energy)
            LinearGradient(
                colors: [MoodQuadrant.red.color, MoodQuadrant.red.color.opacity(0.55)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(width: half, height: half)
            .position(x: half / 2, y: half / 2)

            // Top-right: Yellow (pleasant, high energy)
            LinearGradient(
                colors: [MoodQuadrant.yellow.color, MoodQuadrant.yellow.color.opacity(0.55)],
                startPoint: .topTrailing, endPoint: .bottomLeading
            )
            .frame(width: half, height: half)
            .position(x: half + half / 2, y: half / 2)

            // Bottom-left: Blue (unpleasant, low energy)
            LinearGradient(
                colors: [MoodQuadrant.blue.color, MoodQuadrant.blue.color.opacity(0.55)],
                startPoint: .bottomLeading, endPoint: .topTrailing
            )
            .frame(width: half, height: half)
            .position(x: half / 2, y: half + half / 2)

            // Bottom-right: Green (pleasant, low energy)
            LinearGradient(
                colors: [MoodQuadrant.green.color, MoodQuadrant.green.color.opacity(0.55)],
                startPoint: .bottomTrailing, endPoint: .topLeading
            )
            .frame(width: half, height: half)
            .position(x: half + half / 2, y: half + half / 2)
        }
    }

    // MARK: - Center dividers

    private func centerDividers(size: CGFloat) -> some View {
        ZStack {
            // Horizontal
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: size, height: 1)
                .position(x: size / 2, y: size / 2)
            // Vertical
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 1, height: size)
                .position(x: size / 2, y: size / 2)
        }
    }

    // MARK: - Quadrant corner labels

    private func quadrantCornerLabels(size: CGFloat) -> some View {
        let pad: CGFloat = 8
        return ZStack {
            cornerLabel("Red", quadrant: .red)
                .position(x: pad * 3.5, y: pad * 1.5)
            cornerLabel("Yellow", quadrant: .yellow)
                .position(x: size - pad * 4, y: pad * 1.5)
            cornerLabel("Blue", quadrant: .blue)
                .position(x: pad * 3, y: size - pad * 1.5)
            cornerLabel("Green", quadrant: .green)
                .position(x: size - pad * 4, y: size - pad * 1.5)
        }
    }

    private func cornerLabel(_ text: String, quadrant: MoodQuadrant) -> some View {
        Text(text.uppercased())
            .font(.system(size: 7, weight: .bold))
            .foregroundStyle(.white.opacity(0.55))
            .kerning(0.5)
    }

    // MARK: - Word labels

    private func wordLabels(size: CGFloat) -> some View {
        let nearest = nearestWord
        return ForEach(MoodMeter.words) { word in
            let isNearest = hasSelection && nearest?.id == word.id
            Text(word.word)
                .font(.system(size: isNearest ? 9.5 : 7.5,
                               weight: isNearest ? .semibold : .regular))
                .foregroundStyle(isNearest ? Color.white : Color.white.opacity(0.45))
                .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                .fixedSize()
                .position(
                    x: word.x * size,
                    y: (1.0 - word.y) * size
                )
                .animation(.easeInOut(duration: 0.15), value: isNearest)
        }
    }

    // MARK: - Pin

    private func pin(size: CGFloat) -> some View {
        let pinSize: CGFloat = isDragging ? 24 : 20
        return ZStack {
            // Glow halo
            Circle()
                .fill(currentQuadrant.color.opacity(0.45))
                .frame(width: pinSize + 14, height: pinSize + 14)
                .blur(radius: 6)

            // White pin dot
            Circle()
                .fill(Color.white)
                .frame(width: pinSize, height: pinSize)
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                .overlay(
                    Circle().stroke(Color.black.opacity(0.15), lineWidth: 1)
                )
        }
        .position(
            x: moodX * size,
            y: (1.0 - moodY) * size
        )
        .animation(.spring(duration: 0.2, bounce: 0.3), value: moodX)
        .animation(.spring(duration: 0.2, bounce: 0.3), value: moodY)
        .animation(.easeInOut(duration: 0.1), value: isDragging)
    }

    // MARK: - Gesture layer

    private func gestureLayer(size: CGFloat) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = (value.location.x / size).clamped(to: 0...1)
                        let y = 1.0 - (value.location.y / size).clamped(to: 0...1)
                        moodX = x
                        moodY = y
                        if !hasSelection { hasSelection = true }
                        isDragging = true
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }

    // MARK: - Emotion indicator

    private var emotionIndicator: some View {
        Group {
            if hasSelection, let word = nearestWord {
                HStack(spacing: 10) {
                    Image(systemName: currentQuadrant.sfSymbol)
                        .font(.subheadline)
                        .foregroundStyle(currentQuadrant.color)

                    Text(word.word)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("·")
                        .foregroundStyle(.white.opacity(0.35))

                    Text(currentQuadrant.title)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer()

                    Text(String(repeating: "★", count: currentQuadrant.moodScore) +
                         String(repeating: "☆", count: 5 - currentQuadrant.moodScore))
                        .font(.caption)
                        .foregroundStyle(currentQuadrant.color)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(currentQuadrant.color.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(currentQuadrant.color.opacity(0.3), lineWidth: 1)
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: word.word)
            } else {
                HStack {
                    Image(systemName: "hand.tap")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.35))
                    Text("Tap or drag to place your mood")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Axis labels

    private func axisCaption(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .semibold))
            Text(text)
                .font(.system(size: 9, weight: .semibold))
                .kerning(0.8)
        }
        .foregroundStyle(.white.opacity(0.45))
        .textCase(.uppercase)
    }

    private func verticalAxisLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(.white.opacity(0.45))
            .kerning(0.8)
            .rotationEffect(.degrees(-90))
            .fixedSize()
            .frame(width: 14)
    }
}

// MARK: - Comparable clamping helper

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
