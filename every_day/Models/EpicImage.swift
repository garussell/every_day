//
//  EpicImage.swift
//  every_day
//

import Foundation

struct EpicImage: Identifiable, Hashable {
    let identifier: String
    let caption: String?
    let imageName: String
    let date: Date
    let centroidCoordinates: EpicCoordinatePair?
    let satellitePosition: EpicSatellitePosition?

    var id: String { identifier }

    var imageURL: URL? {
        let components = archiveDateComponents
        let urlString = String(
            format: "https://epic.gsfc.nasa.gov/archive/natural/%04d/%02d/%02d/png/%@.png",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            imageName
        )
        return URL(string: urlString)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    var shortCaption: String? {
        guard let caption = caption?.trimmingCharacters(in: .whitespacesAndNewlines),
              !caption.isEmpty else {
            return nil
        }
        return caption
    }

    private var archiveDateComponents: DateComponents {
        Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
    }
}

struct EpicCoordinatePair: Decodable, Hashable {
    let lat: Double?
    let lon: Double?
}

struct EpicSatellitePosition: Decodable, Hashable {
    let x: Double?
    let y: Double?
    let z: Double?
}

struct EpicImageResponse: Decodable {
    let identifier: String
    let caption: String?
    let image: String
    let date: String
    let centroidCoordinates: EpicCoordinatePair?
    let satellitePosition: EpicSatellitePosition?

    enum CodingKeys: String, CodingKey {
        case identifier
        case caption
        case image
        case date
        case centroidCoordinates = "centroid_coordinates"
        case satellitePosition = "dscovr_j2000_position"
    }
}

extension EpicImage {
    init?(response: EpicImageResponse) {
        guard let date = Self.epicDateFormatter.date(from: response.date) else {
            return nil
        }

        self.init(
            identifier: response.identifier,
            caption: response.caption,
            imageName: response.image,
            date: date,
            centroidCoordinates: response.centroidCoordinates,
            satellitePosition: response.satellitePosition
        )
    }

    private static let epicDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
