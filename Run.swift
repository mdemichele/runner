import Foundation

struct Run: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval  // seconds
    let distanceMeters: Double

    init(id: UUID = UUID(), date: Date = Date(), duration: TimeInterval, distanceMeters: Double) {
        self.id = id
        self.date = date
        self.duration = duration
        self.distanceMeters = distanceMeters
    }

    var distanceMiles: Double { distanceMeters / 1609.344 }

    var formattedDuration: String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        let s = Int(duration) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    var formattedDistance: String {
        String(format: "%.2f mi", distanceMiles)
    }

    var formattedPace: String {
        guard distanceMiles > 0 else { return "--:--" }
        let secondsPerMile = duration / distanceMiles
        let m = Int(secondsPerMile) / 60
        let s = Int(secondsPerMile) % 60
        return String(format: "%d:%02d /mi", m, s)
    }
}
