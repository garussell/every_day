//
//  BirthChartDetailView.swift
//  every_day
//
//  Full natal chart detail view showing all planetary positions, house cusps,
//  element color coding, and retrograde indicators.
//
//  Presented as:
//  • A sheet (from DashboardView) — caller wraps in NavigationStack, passes isSheet: true
//  • A NavigationLink destination (from SettingsView) — no wrapper needed
//

import SwiftUI

struct BirthChartDetailView: View {

    let chart: BirthChart
    var isSheet: Bool = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CelestialBackground()

            ScrollView {
                VStack(spacing: 16) {
                    headerSection

                    bigThreeSection

                    if let planets = chart.planets, !planets.isEmpty {
                        personalPlanetsSection(planets)
                        socialPlanetsSection(planets)
                        outerPlanetsSection(planets)
                    }

                    if let houses = chart.houses, !houses.isEmpty {
                        housesSection(houses)
                    }

                    if chart.planets == nil {
                        recalculatePrompt
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Birth Chart")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .toolbar {
            if isSheet {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.orbitGold)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.orbitGold)
                Text("Natal Chart")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
            if let date = chart.birthDate, let place = chart.birthPlace, !place.isEmpty {
                Text("\(birthDateString(date)) • \(place)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - The Big Three

    private var bigThreeSection: some View {
        sectionCard(title: "The Big Three") {
            if let planets = chart.planets, !planets.isEmpty {
                // From full chart data
                if let sun = planets.first(where: { $0.id == "sun" }) {
                    planetRow(sun)
                }
                divider
                if let moon = planets.first(where: { $0.id == "moon" }) {
                    planetRow(moon)
                }
                if let rising = chart.risingSign {
                    divider
                    risingRow(rising)
                }
            } else {
                // Fallback for legacy charts (sun/moon/rising only)
                basicRow(symbol: "☉", color: Color.orbitGold,
                         name: "Sun", sign: chart.sunSign,
                         desc: "Core identity and ego")
                divider
                basicRow(symbol: "☽", color: .white.opacity(0.85),
                         name: "Moon", sign: chart.moonSign,
                         desc: "Emotions and inner self")
                if let rising = chart.risingSign {
                    divider
                    risingRow(rising)
                }
            }
        }
    }

    // MARK: - Personal Planets

    private func personalPlanetsSection(_ planets: [PlanetData]) -> some View {
        let personal = filteredPlanets(planets, ids: ["mercury", "venus", "mars"])
        guard !personal.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            sectionCard(title: "Personal Planets") {
                ForEach(Array(personal.enumerated()), id: \.offset) { i, planet in
                    if i > 0 { divider }
                    planetRow(planet)
                }
            }
        )
    }

    // MARK: - Social Planets

    private func socialPlanetsSection(_ planets: [PlanetData]) -> some View {
        let social = filteredPlanets(planets, ids: ["jupiter", "saturn"])
        guard !social.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            sectionCard(title: "Social Planets") {
                ForEach(Array(social.enumerated()), id: \.offset) { i, planet in
                    if i > 0 { divider }
                    planetRow(planet)
                }
            }
        )
    }

    // MARK: - Outer Planets

    private func outerPlanetsSection(_ planets: [PlanetData]) -> some View {
        let nodeIds = ["mean_node", "true_node", "north_node"]
        let outerIds = ["uranus", "neptune", "pluto"] + nodeIds
        let outer = filteredPlanets(planets, ids: outerIds)
        guard !outer.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            sectionCard(title: "Outer Planets") {
                ForEach(Array(outer.enumerated()), id: \.offset) { i, planet in
                    if i > 0 { divider }
                    planetRow(planet)
                }
            }
        )
    }

    // MARK: - Houses

    private func housesSection(_ houses: [HouseCusp]) -> some View {
        let sorted = houses.sorted { $0.house < $1.house }
        return sectionCard(title: "House Cusps") {
            ForEach(Array(sorted.enumerated()), id: \.offset) { i, cusp in
                if i > 0 { divider }
                houseRow(cusp)
            }
        }
    }

    // MARK: - Recalculate Prompt

    private var recalculatePrompt: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.clockwise.circle")
                .foregroundStyle(Color.orbitGold.opacity(0.6))
            VStack(alignment: .leading, spacing: 2) {
                Text("Full chart data unavailable")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                Text("Recalculate your birth chart in Settings to see all planetary positions.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orbitGold.opacity(0.12), lineWidth: 1))
        )
    }

    // MARK: - Planet Row

    private func planetRow(_ planet: PlanetData) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Planet symbol
            Text(planetSymbol(planet.id))
                .font(.system(size: 20))
                .foregroundStyle(planetSymbolColor(planet.id))
                .frame(width: 28, alignment: .center)

            // Name + sign + description
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(planet.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("in")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                    Text(planet.signId.capitalized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(elementColor(planet.signId))
                    if planet.retrograde {
                        Text("℞")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(red: 0.9, green: 0.4, blue: 0.35))
                    }
                }
                Text(planetDescription(planet.id))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer(minLength: 4)

            // House badge
            if planet.house > 0 {
                Text("H\(planet.house)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.white.opacity(0.08)))
            }
        }
        .padding(.vertical, 7)
    }

    // MARK: - Rising Row (special — no house, no planet data)

    private func risingRow(_ signName: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text("AC")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.orbitGold.opacity(0.85))
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text("Rising")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("in")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                    Text(signName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(elementColor(signName.lowercased()))
                }
                Text("Outward personality and first impressions")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(.vertical, 7)
    }

    // MARK: - Basic Row (legacy chart fallback)

    private func basicRow(symbol: String, color: Color,
                           name: String, sign: String, desc: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(symbol)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("in")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                    Text(sign)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(elementColor(sign.lowercased()))
                }
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(.vertical, 7)
    }

    // MARK: - House Row

    private func houseRow(_ cusp: HouseCusp) -> some View {
        HStack(spacing: 12) {
            // Roman numeral + special label
            HStack(spacing: 5) {
                Text(romanNumeral(cusp.house))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.orbitGold.opacity(0.7))
                    .frame(width: 28, alignment: .leading)
                if let label = houseSpecialLabel(cusp.house) {
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.orbitGold.opacity(0.55))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orbitGold.opacity(0.1)))
                }
            }

            Spacer()

            // Sign
            Text(cusp.signId.capitalized)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(elementColor(cusp.signId))

            // Degree
            Text(String(format: "%.1f°", cusp.pos))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.orbitGold.opacity(0.8))
                .textCase(.uppercase)
                .kerning(0.5)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orbitGold.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.06))
            .frame(height: 1)
    }

    // MARK: - Helpers

    private func filteredPlanets(_ all: [PlanetData], ids: [String]) -> [PlanetData] {
        ids.compactMap { id in all.first { $0.id == id } }
    }

    private func birthDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f.string(from: date)
    }

    private func romanNumeral(_ n: Int) -> String {
        let map = [1:"I",2:"II",3:"III",4:"IV",5:"V",6:"VI",
                   7:"VII",8:"VIII",9:"IX",10:"X",11:"XI",12:"XII"]
        return map[n] ?? "\(n)"
    }

    private func houseSpecialLabel(_ house: Int) -> String? {
        switch house {
        case 1:  return "ASC"
        case 4:  return "IC"
        case 7:  return "DSC"
        case 10: return "MC"
        default: return nil
        }
    }

    // MARK: - Planet Metadata

    private func planetSymbol(_ id: String) -> String {
        switch id {
        case "sun":                              return "☉"
        case "moon":                             return "☽"
        case "mercury":                          return "☿"
        case "venus":                            return "♀"
        case "mars":                             return "♂"
        case "jupiter":                          return "♃"
        case "saturn":                           return "♄"
        case "uranus":                           return "♅"
        case "neptune":                          return "♆"
        case "pluto":                            return "♇"
        case "mean_node","true_node","north_node": return "☊"
        default:                                 return "✦"
        }
    }

    private func planetSymbolColor(_ id: String) -> Color {
        switch id {
        case "sun":                                return Color.orbitGold
        case "moon":                               return .white.opacity(0.85)
        case "mercury":                            return Color(red: 0.70, green: 0.70, blue: 0.82)
        case "venus":                              return Color(red: 0.92, green: 0.60, blue: 0.68)
        case "mars":                               return Color(red: 0.90, green: 0.40, blue: 0.35)
        case "jupiter":                            return Color(red: 0.82, green: 0.70, blue: 0.50)
        case "saturn":                             return Color(red: 0.66, green: 0.66, blue: 0.76)
        case "uranus":                             return Color(red: 0.40, green: 0.80, blue: 0.90)
        case "neptune":                            return Color(red: 0.40, green: 0.52, blue: 0.92)
        case "pluto":                              return Color(red: 0.76, green: 0.42, blue: 0.82)
        case "mean_node","true_node","north_node": return Color(red: 0.55, green: 0.80, blue: 0.50)
        default:                                   return .white.opacity(0.7)
        }
    }

    private func planetDescription(_ id: String) -> String {
        switch id {
        case "sun":                                return "Core identity and ego"
        case "moon":                               return "Emotions and inner self"
        case "mercury":                            return "Communication and thinking"
        case "venus":                              return "Love, beauty, and values"
        case "mars":                               return "Drive, action, and desire"
        case "jupiter":                            return "Growth, luck, and expansion"
        case "saturn":                             return "Structure, discipline, and karma"
        case "uranus":                             return "Change, rebellion, and innovation"
        case "neptune":                            return "Dreams, intuition, and spirituality"
        case "pluto":                              return "Transformation and power"
        case "mean_node","true_node","north_node": return "Life purpose and destiny"
        default:                                   return ""
        }
    }

    // MARK: - Element Color

    private func elementColor(_ signId: String) -> Color {
        switch signId.lowercased() {
        // Fire
        case "aries", "leo", "sagittarius":
            return Color(red: 0.95, green: 0.65, blue: 0.25)
        // Earth
        case "taurus", "virgo", "capricorn":
            return Color(red: 0.55, green: 0.80, blue: 0.50)
        // Air
        case "gemini", "libra", "aquarius":
            return Color(red: 0.45, green: 0.75, blue: 0.95)
        // Water
        case "cancer", "scorpio", "pisces":
            return Color(red: 0.35, green: 0.68, blue: 0.82)
        default:
            return .white.opacity(0.75)
        }
    }
}
