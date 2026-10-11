# 位置模拟 (VirtualLocation)

一个面向 **iOS 开发调试** 的定位模拟工具。开发者可在 App 内沿「起点 → 终点」设置一条模拟移动轨迹，实时观察坐标、行驶距离与进度；并支持通过 **Xcode GPX 方案模拟** 让整台模拟器/设备使用自定义定位。

> ⚠️ 用途说明
> 本项目定位为**开发与测试工具**，用于验证定位相关功能（地图、轨迹、地理围栏、距离计算等）。**不可用于**伪造考勤、规避应用地理限制、游戏作弊或任何违规行为。系统级「欺骗其他 App」的定位改写属于受控能力，需配合 Xcode 模拟或越狱设备，本项目不提供该能力，也请勿将本工具用于非法用途。

---

## 功能特性

- 🗺️ SwiftUI + MapKit 地图，实时绘制模拟轨迹
- 📍 自定义起点/终点坐标（支持「纬度, 经度」输入）
- ⚡ 可调模拟速度（5–120 km/h）
- 🎯 内置多城市快捷地点
- 📏 实时显示行驶距离与进度
- 📡 可选显示设备真实位置用于对比
- 🧪 附带 GPX 路线，支持 Xcode 设备级位置模拟

## 目录结构

```
Apple-Virtual-Location/
├── project.yml              # XcodeGen 工程描述（CI 与本地通用）
├── VirtualLocation/         # App 源码
│   ├── VirtualLocationApp.swift
│   ├── ContentView.swift    # 主界面
│   ├── LocationSimulator.swift   # 位置模拟引擎
│   ├── RealLocationManager.swift # 真实定位（对比用）
│   ├── Info.plist
│   └── Assets.xcassets/
├── Support/
│   └── simulator_location.gpx
└── .github/workflows/build.yml   # GitHub Actions 持续构建
```

## 本地构建（Xcode）

需要 **Xcode 14+**（Swift 5 / iOS 16 target）。推荐使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成工程：

```bash
# 1) 安装 XcodeGen（若未安装）
brew install xcodegen

# 2) 生成 .xcodeproj
xcodegen generate

# 3) 打开并运行（选择模拟器）
open VirtualLocation.xcodeproj
```

也可以手动在 Xcode 中新建工程，将 `VirtualLocation/` 下的源码加入 Target，并复制 `Info.plist` 与 `Assets.xcassets`。

### 设备级位置模拟（Xcode GPX）

1. `Product → Scheme → Edit Scheme…`
2. 选择 `Run → Options → Core Location`
3. 勾选 **Allow Location Simulation**，`Default Location` 选择 `Support/simulator_location.gpx`
4. 运行后，模拟器/设备将按 GPX 中的路线输出定位

## 持续构建（GitHub Actions）

仓库已配置 `.github/workflows/build.yml`，push 到 `main` 或创建 PR 时会：

1. 在 macOS 虚拟机上安装 XcodeGen
2. 生成 Xcode 工程
3. 用 `xcodebuild` 对 iOS 模拟器 SDK 编译验证
4. 上传 `.app` 构建产物

## 模拟算法说明

`LocationSimulator` 按固定时间片（0.5s）推进，每片前进 `速度 × 时间片` 米，并在起终点直线间插值坐标，直至到达终点。适合演示，如需真实路网轨迹可在此基座上接入路线规划 SDK。

## 许可

MIT License. 使用前请遵守当地法律法规与苹果开发者协议。
