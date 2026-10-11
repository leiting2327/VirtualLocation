import SwiftUI
import MapKit

/// 主界面：地图 + 起终点 + 速度控制 + 模拟开关
struct ContentView: View {

    // MARK: 状态

    @StateObject private var real = RealLocationManager()
    @StateObject private var simulator: LocationSimulator

    @State private var startInput: String = "39.9042, 116.4074"
    @State private var endInput: String = "39.9163, 116.3972"
    @State private var speedKmph: Double = 30

    @State private var start: CLLocationCoordinate2D = .init(latitude: 39.9042, longitude: 116.4074)
    @State private var end: CLLocationCoordinate2D = .init(latitude: 39.9163, longitude: 116.3972)

    @State private var region = MKCoordinateRegion(
        center: .init(latitude: 39.9100, longitude: 116.4022),
        span: .init(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var errorMessage: String?
    @State private var showRealLocation = false

    init() {
        _simulator = StateObject(wrappedValue: LocationSimulator(
            start: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            end: CLLocationCoordinate2D(latitude: 39.9163, longitude: 116.3972),
            speedMps: 30 / 3.6
        ))
    }

    // MARK: 预设地点

    private let presets: [(name: String, coord: CLLocationCoordinate2D)] = [
        ("北京·天安门", .init(latitude: 39.9042, longitude: 116.4074)),
        ("上海·外滩", .init(latitude: 31.2397, longitude: 121.4903)),
        ("广州·珠江新城", .init(latitude: 23.1192, longitude: 113.3238)),
        ("深圳·市民中心", .init(latitude: 22.5431, longitude: 114.0579)),
        ("成都·天府广场", .init(latitude: 30.6573, longitude: 104.0660)),
        ("杭州·西湖", .init(latitude: 30.2590, longitude: 120.1499)),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mapView
                controlPanel
            }
            .navigationTitle("位置模拟")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(showRealLocation ? "隐藏真实位置" : "显示真实位置") {
                        showRealLocation.toggle()
                        if showRealLocation {
                            real.requestIfNeeded()
                        }
                    }
                    .font(.caption)
                }
            }
        }
    }

    // MARK: 地图

    private var mapView: some View {
        Map(coordinateRegion: $region,
            showsUserLocation: false,
            annotationItems: annotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                pinView(kind: item.kind)
            }
        }
        .overlay(alignment: .topLeading) {
            if simulator.isRunning, let c = simulator.current {
                VStack(alignment: .leading, spacing: 2) {
                    Text("模拟坐标")
                        .font(.caption2).foregroundStyle(.secondary)
                    Text(c.shortDescription)
                        .font(.caption).monospacedDigit()
                    Text("行驶 \(Int(simulator.traveledMeters)) m · 进度 \(Int(simulator.progress * 100))%")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var annotations: [MapPin] {
        var list: [MapPin] = []
        list.append(.init(id: "start", kind: .start, coordinate: start))
        list.append(.init(id: "end", kind: .end, coordinate: end))
        if showRealLocation, let r = real.lastLocation {
            list.append(.init(id: "real", kind: .real, coordinate: r))
        }
        return list
    }

    @ViewBuilder
    private func pinView(kind: MapPin.Kind) -> some View {
        Circle()
            .fill(kind.color)
            .frame(width: 16, height: 16)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(radius: 2)
    }

    // MARK: 控制面板

    private var controlPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                coordinateSection(title: "起点", text: $startInput, coord: $start, tag: "start")
                coordinateSection(title: "终点", text: $endInput, coord: $end, tag: "end")

                presetRow

                speedSection

                errorSection

                startButton
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func coordinateSection(title: String,
                                   text: Binding<String>,
                                   coord: Binding<CLLocationCoordinate2D>,
                                   tag: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            HStack {
                TextField("纬度, 经度", text: text)
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                Button("应用") {
                    applyCoordinate(text.wrappedValue, to: coord, tag: tag)
                }
                .buttonStyle(.bordered)
                .disabled(simulator.isRunning)
            }
        }
    }

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("快捷地点")
                .font(.subheadline.weight(.semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.name) { p in
                        Button(p.name) {
                            end = p.coord
                            centerOn(end)
                        }
                        .buttonStyle(.bordered)
                        .disabled(simulator.isRunning)
                    }
                }
            }
        }
    }

    private var speedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("模拟速度")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(String(format: "%.0f km/h", speedKmph))
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: $speedKmph, in: 5...120, step: 5)
                .disabled(simulator.isRunning)
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .foregroundStyle(.red)
                .padding(.vertical, 4)
        }
    }

    private var startButton: some View {
        Button {
            toggleSimulation()
        } label: {
            Text(simulator.isRunning ? "停止模拟" : "开始模拟")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(simulator.isRunning ? .red : .blue)
    }

    // MARK: 逻辑

    private func applyCoordinate(_ raw: String, to binding: Binding<CLLocationCoordinate2D>, tag: String) {
        guard let c = Self.parseCoordinate(raw) else {
            errorMessage = "坐标格式无效，请使用「纬度, 经度」，例如 39.9042, 116.4074"
            return
        }
        binding.wrappedValue = c
        errorMessage = nil
        if tag == "start" {
            centerOn(c)
        }
    }

    private static func parseCoordinate(_ raw: String) -> CLLocationCoordinate2D? {
        let parts = raw
            .replacingOccurrences(of: "，", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1]),
              (-90...90).contains(lat),
              (-180...180).contains(lon) else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func centerOn(_ coord: CLLocationCoordinate2D) {
        withAnimation {
            region.center = coord
        }
    }

    private func toggleSimulation() {
        if simulator.isRunning {
            simulator.stop()
            return
        }
        simulator.configure(start: start, end: end, speedMps: speedKmph / 3.6)
        simulator.onLocation = { coord in
            withAnimation { region.center = coord }
        }
        simulator.start()
        centerOn(start)
    }
}

// MARK: - 标注模型

private struct MapPin: Identifiable {
    enum Kind {
        case start, end, real

        var color: Color {
            switch self {
            case .start: return .green
            case .end: return .red
            case .real: return .blue
            }
        }
    }

    let id: String
    let kind: Kind
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    ContentView()
}
