import CoreLocation
import Foundation

/// 位置模拟引擎
///
/// 在「本 App 内部」沿一条起点→终点的直线匀速移动，产出模拟坐标。
/// 这是标准的开发调试演示：让开发者直观地观察定位变化、轨迹与
/// 距离计算是否正确。若需让整台设备（其他 App）都使用模拟定位，
/// 请使用 Xcode 的 GPX 方案模拟（见 README「设备级模拟」）。
final class LocationSimulator: ObservableObject {

    /// 模拟是否进行中
    @Published private(set) var isRunning = false
    /// 当前模拟坐标
    @Published private(set) var current: CLLocationCoordinate2D?
    /// 已行驶距离（米）
    @Published private(set) var traveledMeters: Double = 0

    /// 每次回调最新坐标，供外部（地图/测试）消费
    var onLocation: ((CLLocationCoordinate2D) -> Void)?

    /// 更新频率
    private let updateInterval: TimeInterval = 0.5
    private var timer: Timer?

    private var startCoord = CLLocationCoordinate2D()
    private var endCoord = CLLocationCoordinate2D()
    private var speedMps: Double = 8.33 // 默认 30 km/h
    private var totalDistance: Double = 0

    init(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, speedMps: Double) {
        configure(start: start, end: end, speedMps: speedMps)
    }

    deinit {
        timer?.invalidate()
    }

    /// 在开始前配置路线与速度
    func configure(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, speedMps: Double) {
        guard !isRunning else { return }
        self.startCoord = start
        self.endCoord = end
        self.speedMps = max(speedMps, 0.1)
        self.totalDistance = start.distance(to: end)
        self.traveledMeters = 0
        self.current = start
    }

    /// 整体进度 0...1
    var progress: Double {
        guard totalDistance > 0 else { return 0 }
        return min(traveledMeters / totalDistance, 1)
    }

    /// 是否已到达终点
    var didArrive: Bool { totalDistance > 0 && traveledMeters >= totalDistance }

    func start() {
        guard !isRunning else { return }
        traveledMeters = 0
        current = startCoord
        isRunning = true
        emitCurrent()

        let timer = Timer(timeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.step()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    /// 每 tick 前进 speed × interval 米，并沿直线插值坐标
    private func step() {
        guard isRunning else { return }
        if didArrive {
            stop()
            return
        }
        traveledMeters += speedMps * updateInterval
        emitCurrent()
    }

    private func emitCurrent() {
        let fraction = progress
        let lat = startCoord.latitude + (endCoord.latitude - startCoord.latitude) * fraction
        let lon = startCoord.longitude + (endCoord.longitude - startCoord.longitude) * fraction
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        current = coord
        onLocation?(coord)
    }
}

// MARK: - 坐标工具

extension CLLocationCoordinate2D {
    /// 两点之间的大地距离（米）
    func distance(to other: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }

    /// 近似格式化展示
    var shortDescription: String {
        String(format: "%.5f, %.5f", latitude, longitude)
    }
}
