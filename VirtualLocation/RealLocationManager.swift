import CoreLocation
import Foundation

/// 真实定位管理器（用于对照展示「设备真实位置」）
///
/// 仅在需要时请求一次授权与定位，供界面做对比参考，
/// 避免无谓占用定位权限。
final class RealLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published private(set) var authorized = false
    @Published private(set) var lastLocation: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            authorized = true
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authorized = (status == .authorizedAlways || status == .authorizedWhenInUse)
        if authorized {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last?.coordinate
    }
}
