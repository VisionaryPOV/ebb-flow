import CoreLocation
import Foundation

enum LocationServiceError: Error, LocalizedError, Equatable {
    case denied
    case restricted
    case unavailable

    var errorDescription: String? {
        switch self {
        case .denied:
            "Location access is off. Enable it in Settings to find nearby tide stations."
        case .restricted:
            "Location access is restricted on this device."
        case .unavailable:
            "Current location is unavailable. Try again in a moment."
        }
    }
}

@MainActor
protocol LocationProviding: AnyObject {
    func currentCoordinate() async throws -> CLLocationCoordinate2D
}

@MainActor
@Observable
final class LocationService: NSObject, LocationProviding {
    private let manager: CLLocationManager
    private var delegateProxy: LocationManagerDelegateProxy!
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        super.init()
        let proxy = LocationManagerDelegateProxy(owner: self)
        delegateProxy = proxy
        manager.delegate = proxy
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    fileprivate func setContinuation(_ continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?) {
        self.continuation = continuation
    }

    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        case .authorizedWhenInUse, .authorizedAlways:
            return try await requestLocation()
        case .denied:
            throw LocationServiceError.denied
        case .restricted:
            throw LocationServiceError.restricted
        @unknown default:
            throw LocationServiceError.unavailable
        }
    }

    private func requestLocation() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    fileprivate func finish(with result: Result<CLLocationCoordinate2D, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }

    fileprivate func handleAuthorizationChange(status: CLAuthorizationStatus) {
        guard continuation != nil else { return }
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied:
            finish(with: .failure(LocationServiceError.denied))
        case .restricted:
            finish(with: .failure(LocationServiceError.restricted))
        case .notDetermined:
            break
        @unknown default:
            finish(with: .failure(LocationServiceError.unavailable))
        }
    }

    fileprivate func handleLocationUpdate(_ coordinates: [CLLocationCoordinate2D]) {
        guard let coordinate = coordinates.last else {
            finish(with: .failure(LocationServiceError.unavailable))
            return
        }
        finish(with: .success(coordinate))
    }

    fileprivate func handleLocationFailure() {
        finish(with: .failure(LocationServiceError.unavailable))
    }
}

private final class LocationManagerDelegateProxy: NSObject, CLLocationManagerDelegate {
    private weak var owner: LocationService?

    init(owner: LocationService) {
        self.owner = owner
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak owner] in
            owner?.handleAuthorizationChange(status: status)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinates = locations.map(\.coordinate)
        Task { @MainActor [weak owner] in
            owner?.handleLocationUpdate(coordinates)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak owner] in
            owner?.handleLocationFailure()
        }
    }
}

@MainActor
final class MockLocationService: LocationProviding {
    var coordinate: CLLocationCoordinate2D
    var error: Error?

    init(coordinate: CLLocationCoordinate2D, error: Error? = nil) {
        self.coordinate = coordinate
        self.error = error
    }

    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        if let error { throw error }
        return coordinate
    }
}