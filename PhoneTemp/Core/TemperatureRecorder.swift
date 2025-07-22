//
//  TemperatureRecorder.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/22.
//

import Foundation
import SwiftData
import Combine
import UIKit

// MARK: - 简化的温度记录管理器
@MainActor
class TemperatureRecorder: ObservableObject {
    @Published var todayRecords: [TemperatureRecord] = []
    @Published var todayStats: TemperatureStats = TemperatureStats(records: [])
    
    private var recordingTimer: Timer?
    private let recordingInterval: TimeInterval = 300 // 5分钟记录一次
    private var lastRecordedState: ThermalState?
    private var isPreviewMode: Bool = false
    
    // 使用内存存储来避免文件系统问题
    private var memoryRecords: [TemperatureRecord] = []
    
    // MARK: - 初始化方法
    init(previewMode: Bool = false) {
        self.isPreviewMode = previewMode
        
        if !previewMode {
            // 正常模式：使用内存存储 + 简单的本地持久化
            loadFromUserDefaults()
            setupNotifications()
            startRecording()
        } else {
            // Preview 模式：使用模拟数据
            setupPreviewData()
        }
        
        print("TemperatureRecorder: Initialized in \(previewMode ? "preview" : "normal") mode")
    }
    
    deinit {
        // deinit 是非隔离的，需要安全地清理资源
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // 对于 NotificationCenter，移除观察者是线程安全的
        NotificationCenter.default.removeObserver(self)
        
        // 不能直接调用 @MainActor 方法，所以只打印日志
        print("TemperatureRecorder: Deinitialized")
    }
    
    // MARK: - Preview 模式数据设置
    private func setupPreviewData() {
        let now = Date()
        let calendar = Calendar.current
        
        todayRecords = [
            TemperatureRecord(
                timestamp: calendar.date(byAdding: .hour, value: -6, to: now) ?? now,
                thermalState: .normal
            ),
            TemperatureRecord(
                timestamp: calendar.date(byAdding: .hour, value: -4, to: now) ?? now,
                thermalState: .fair
            ),
            TemperatureRecord(
                timestamp: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
                thermalState: .serious
            ),
            TemperatureRecord(
                timestamp: now,
                thermalState: .normal
            )
        ]
        
        memoryRecords = todayRecords
        todayStats = TemperatureStats(records: todayRecords)
    }
    
    // MARK: - 手动清理方法
    func invalidate() {
        if !isPreviewMode {
            stopRecording()
            saveToUserDefaults() // 保存当前数据
        }
        print("TemperatureRecorder: Invalidation complete")
    }
    
    // MARK: - 使用 UserDefaults 作为简单持久化
    private func saveToUserDefaults() {
        guard !isPreviewMode else { return }
        
        let encoder = JSONEncoder()
        do {
            // 只保存最近100条记录以避免数据过大
            let recentRecords = Array(memoryRecords.suffix(100))
            let recordsData = try encoder.encode(recentRecords.map { record in
                SimpleRecord(
                    timestamp: record.timestamp,
                    thermalStateRaw: record.thermalState.rawValue,
                    deviceName: record.deviceName
                )
            })
            UserDefaults.standard.set(recordsData, forKey: "TemperatureRecords")
            print("TemperatureRecorder: Saved \(recentRecords.count) records to UserDefaults")
        } catch {
            print("TemperatureRecorder: Failed to save to UserDefaults: \(error.localizedDescription)")
        }
    }
    
    private func loadFromUserDefaults() {
        guard !isPreviewMode else { return }
        
        guard let recordsData = UserDefaults.standard.data(forKey: "TemperatureRecords") else {
            print("TemperatureRecorder: No existing records in UserDefaults")
            loadTodayRecords()
            return
        }
        
        let decoder = JSONDecoder()
        do {
            let simpleRecords = try decoder.decode([SimpleRecord].self, from: recordsData)
            memoryRecords = simpleRecords.compactMap { simpleRecord in
                guard let thermalState = ThermalState.fromRawValue(simpleRecord.thermalStateRaw) else {
                    return nil
                }
                return TemperatureRecord(
                    timestamp: simpleRecord.timestamp,
                    thermalState: thermalState,
                    deviceName: simpleRecord.deviceName
                )
            }
            loadTodayRecords()
            print("TemperatureRecorder: Loaded \(memoryRecords.count) records from UserDefaults")
        } catch {
            print("TemperatureRecorder: Failed to load from UserDefaults: \(error.localizedDescription)")
            loadTodayRecords()
        }
    }
    
    // MARK: - 通知设置
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - 应用生命周期处理
    @objc private func handleAppDidEnterBackground() {
        if !isPreviewMode {
            stopRecording()
            saveToUserDefaults()
            print("TemperatureRecorder: Recording paused and data saved (background)")
        }
    }
    
    @objc private func handleAppWillEnterForeground() {
        if !isPreviewMode {
            startRecording()
            loadTodayRecords()
            print("TemperatureRecorder: Recording resumed (foreground)")
        }
    }
    
    // MARK: - 开始记录
    func startRecording() {
        guard !isPreviewMode else { return }
        
        stopRecording() // 先停止现有的定时器
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: recordingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordCurrentTemperature()
            }
        }
        
        // 立即记录一次
        recordCurrentTemperature()
        
        print("TemperatureRecorder: Recording started")
    }
    
    // MARK: - 停止记录
    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        print("TemperatureRecorder: Recording stopped")
    }
    
    // MARK: - 记录当前温度
    private func recordCurrentTemperature() {
        guard !isPreviewMode else { return }
        
        let currentState = getCurrentThermalState()
        
        // 如果状态没有变化且时间间隔不够，跳过记录
        if let lastState = lastRecordedState, lastState == currentState {
            if let lastRecord = todayRecords.last,
               Date().timeIntervalSince(lastRecord.timestamp) < recordingInterval {
                return
            }
        }
        
        let record = TemperatureRecord(thermalState: currentState)
        saveRecord(record)
        lastRecordedState = currentState
    }
    
    // MARK: - 手动记录温度
    func recordTemperatureChange(newState: ThermalState) {
        guard !isPreviewMode else { return }
        
        if lastRecordedState != newState {
            let record = TemperatureRecord(thermalState: newState)
            saveRecord(record)
            lastRecordedState = newState
        }
    }
    
    // MARK: - 获取当前热状态
    private func getCurrentThermalState() -> ThermalState {
        let currentThermalState = ProcessInfo.processInfo.thermalState
        
        switch currentThermalState {
        case .nominal:
            return .normal
        case .fair:
            return .fair
        case .serious:
            return .serious
        case .critical:
            return .critical
        @unknown default:
            return .normal
        }
    }
    
    // MARK: - 简化的保存记录
    private func saveRecord(_ record: TemperatureRecord) {
        memoryRecords.append(record)
        
        // 定期保存到 UserDefaults（每10条记录保存一次）
        if memoryRecords.count % 10 == 0 {
            saveToUserDefaults()
        }
        
        loadTodayRecords()
        print("TemperatureRecorder: Record saved to memory")
    }
    
    // MARK: - 加载今日记录
    func loadTodayRecords() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        todayRecords = memoryRecords.filter { record in
            record.timestamp >= startOfDay && record.timestamp < endOfDay
        }.sorted { $0.timestamp < $1.timestamp }
        
        todayStats = TemperatureStats(records: todayRecords)
        print("TemperatureRecorder: Loaded \(todayRecords.count) today records")
    }
    
    // MARK: - 获取指定日期的记录
    func getRecords(for date: Date) -> [TemperatureRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        return memoryRecords.filter { record in
            record.timestamp >= startOfDay && record.timestamp < endOfDay
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    // MARK: - 刷新数据
    func refresh() {
        if !isPreviewMode {
            loadTodayRecords()
        }
    }
    
    // MARK: - 状态检查
    func isReady() -> Bool {
        return true // 简化版本总是准备就绪
    }
    
    // MARK: - Preview 助手方法
    static func previewInstance() -> TemperatureRecorder {
        return TemperatureRecorder(previewMode: true)
    }
    
    // MARK: - 清除所有数据（用于测试）
    func clearAllData() {
        memoryRecords.removeAll()
        todayRecords.removeAll()
        todayStats = TemperatureStats(records: [])
        UserDefaults.standard.removeObject(forKey: "TemperatureRecords")
        print("TemperatureRecorder: All data cleared")
    }
}

// MARK: - 简化的记录结构（用于 JSON 序列化）
private struct SimpleRecord: Codable {
    let timestamp: Date
    let thermalStateRaw: String
    let deviceName: String
}

// MARK: - ThermalState 扩展
extension ThermalState {
    static func fromRawValue(_ rawValue: String) -> ThermalState? {
        switch rawValue {
        case "正常": return .normal
        case "轻微发热": return .fair
        case "中度发热": return .serious
        case "严重发热": return .critical
        default: return nil
        }
    }
}
