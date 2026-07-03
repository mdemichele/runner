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
    @Published var locationAuthorized: Bool = false

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
        history = store.load()
    }

    // MARK: - Run control

    func start() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        startDate = Date()
        pausedElapsed = 0
        distanceMeters = 0
        lastLocation = nil
        state = .active
        startTimer()
    }

    func pause() {
        pausedElapsed = elapsed
        timer?.invalidate()
        locationManager.stopUpdatingLocation()
        state = .paused
    }

    func resume() {
        startDate = Date()
        locationManager.startUpdatingLocation()
        state = .active
        startTimer()
    }

    func stop() {
        timer?.invalidate()
        locationManager.stopUpdatingLocation()
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
            guard let self, let start = self.startDate else { return }
            self.elapsed = self.pausedElapsed + Date().timeIntervalSince(start)
        }
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
}

// MARK: - CLLocationManagerDelegate

extension RunManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        locationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, state == .active else { return }
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
