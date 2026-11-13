import Foundation
import CoreLocation
import Combine

enum RunState {
    case idle, active, paused
}

class RunManager: NSObject, ObservableObject {
    @Published var state: RunState = .idle
    @Published var elapsed: TimeInterval = 0
    @Published var distanceMeters: Double = 0
    @Published var history: [Run] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private var timer: Timer?
    private var startDate: Date?
    private var pausedElapsed: TimeInterval = 0
    private var lastLocation: CLLocation?

    private let locationManager = CLLocationManager()
    private let store = RunStore()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = false
        history = store.load()
    }

    // MARK: - Run control

    var locationDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func start() {
        locationManager.requestWhenInUseAuthorization()
        startLocationUpdates()
        startDate = Date()
        pausedElapsed = 0
        distanceMeters = 0
        lastLocation = nil
        state = .active
        startTimer()
    }

    func pause() {
        updateElapsed()
        pausedElapsed = elapsed
        timer?.invalidate()
        stopLocationUpdates()
        state = .paused
    }

    func resume() {
        startDate = Date()
        // Don't count distance covered while paused
        lastLocation = nil
        startLocationUpdates()
        state = .active
        startTimer()
    }

    func stop() {
        if state == .active { updateElapsed() }
        timer?.invalidate()
        stopLocationUpdates()
        let run = Run(duration: elapsed, distanceMeters: distanceMeters)
        history.insert(run, at: 0)
        store.save(history)
        elapsed = 0
        distanceMeters = 0
        pausedElapsed = 0
        lastLocation = nil
        state = .idle
    }

    func deleteRuns(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        store.save(history)
    }

    // MARK: - Private

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateElapsed()
        }
    }

    private func updateElapsed() {
        guard let start = startDate else { return }
        elapsed = pausedElapsed + Date().timeIntervalSince(start)
    }

    // Keep tracking while the screen is locked (requires the "location" background mode)
    private func startLocationUpdates() {
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.startUpdatingLocation()
    }

    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
    }

    var formattedElapsed: String {
        let h = Int(elapsed) / 3600
        let m = (Int(elapsed) % 3600) / 60
        let s = Int(elapsed) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    var formattedDistance: String {
        String(format: "%.2f mi", distanceMeters / 1609.344)
    }

    var formattedPace: String {
        let miles = distanceMeters / 1609.344
        guard miles > 0 else { return "--:--" }
        let secondsPerMile = elapsed / miles
        let m = Int(secondsPerMile) / 60
        let s = Int(secondsPerMile) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - CLLocationManagerDelegate

extension RunManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard state == .active else { return }
        // Skip cached and low-accuracy fixes, which otherwise inflate distance
        guard let location = locations.last(where: {
            $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy <= 30
                && abs($0.timestamp.timeIntervalSinceNow) < 10
        }) else { return }
        if let last = lastLocation {
            let delta = location.distance(from: last)
            if delta > 0 { distanceMeters += delta }
        }
        lastLocation = location
    }
}

// MARK: - RunStore

private class RunStore {
    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("runs.json")
    }

    func load() -> [Run] {
        guard let data = try? Data(contentsOf: fileURL),
              let runs = try? JSONDecoder().decode([Run].self, from: data) else { return [] }
        return runs
    }

    func save(_ runs: [Run]) {
        guard let data = try? JSONEncoder().encode(runs) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
