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

// MARK: - 温度记录管理器
@MainActor
class TemperatureRecorder: ObservableObject {
    @Published var todayRecords: [TemperatureRecord] = []
    @Published var todayStats: TemperatureStats = TemperatureStats(records: [])
    
    private var modelContext: ModelContext?
    private var recordingTimer: Timer?
    private let recordingInterval: TimeInterval = 300 // 5分钟记录一次
    private var lastRecordedState: ThermalState?
    
    init() {
        setupModelContext()
        startRecording()
        loadTodayRecords()
        setupNotifications()
    }
    
    deinit {
        // 只保留线程安全的清理操作
        NotificationCenter.default.removeObserver(self)
        print("TemperatureRecorder: Deinitialized")
    }
    
    // MARK: - 手动清理方法
    func invalidate() {
        // 这个方法继承 @MainActor 属性，在主线程上安全调用
        stopRecording()
        print("TemperatureRecorder: Invalidation complete")
    }
    
    // MARK: - 数据库设置
    private func setupModelContext() {
        do {
            let schema = Schema([TemperatureRecord.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContext = container.mainContext
            print("TemperatureRecorder: ModelContext setup successfully")
        } catch {
            print("TemperatureRecorder: Failed to setup ModelContext: \(error.localizedDescription)")
            setupFallbackContext()
        }
    }
    
    // MARK: - 降级数据库设置
    private func setupFallbackContext() {
        do {
            let schema = Schema([TemperatureRecord.self])
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let fallbackContainer = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            self.modelContext = fallbackContainer.mainContext
            print("TemperatureRecorder: Using in-memory ModelContext as fallback")
        } catch {
            print("TemperatureRecorder: Failed to create fallback ModelContext: \(error.localizedDescription)")
            self.modelContext = nil
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
    
    // MARK: - 应用生命周期处理 (nonisolated)
    @objc nonisolated private func handleAppDidEnterBackground() {
        Task { @MainActor in
            self.stopRecording()
            print("TemperatureRecorder: Recording paused (background)")
        }
    }
    
    @objc nonisolated private func handleAppWillEnterForeground() {
        Task { @MainActor in
            self.startRecording()
            self.loadTodayRecords()
            print("TemperatureRecorder: Recording resumed (foreground)")
        }
    }
    
    // MARK: - 开始记录
    func startRecording() {
        stopRecording() // 先停止现有的定时器
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: recordingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.recordCurrentTemperature()
            }
        }
        
        // 立即记录一次
        Task {
            await recordCurrentTemperature()
        }
        
        print("TemperatureRecorder: Recording started")
    }
    
    // MARK: - 停止记录
    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        print("TemperatureRecorder: Recording stopped")
    }
    
    // MARK: - 记录当前温度
    private func recordCurrentTemperature() async {
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
    
    // MARK: - 手动记录温度（状态变化时调用）
    func recordTemperatureChange(newState: ThermalState) {
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
    
    // MARK: - 保存记录
    private func saveRecord(_ record: TemperatureRecord) {
        guard let context = modelContext else {
            print("TemperatureRecorder: No ModelContext available")
            return
        }
        
        context.insert(record)
        
        do {
            try context.save()
            loadTodayRecords()
            print("TemperatureRecorder: Record saved successfully")
        } catch {
            print("TemperatureRecorder: Failed to save temperature record: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 加载今日记录
    func loadTodayRecords() {
        guard let context = modelContext else {
            print("TemperatureRecorder: No ModelContext available for loading")
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let predicate = #Predicate<TemperatureRecord> { record in
            record.timestamp >= startOfDay && record.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<TemperatureRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp)]
        )
        
        do {
            let records = try context.fetch(descriptor)
            self.todayRecords = records
            self.todayStats = TemperatureStats(records: records)
            print("TemperatureRecorder: Loaded \(records.count) today records")
        } catch {
            print("TemperatureRecorder: Failed to load today records: \(error.localizedDescription)")
            self.todayRecords = []
            self.todayStats = TemperatureStats(records: [])
        }
    }
    
    // MARK: - 获取指定日期的记录
    func getRecords(for date: Date) -> [TemperatureRecord] {
        guard let context = modelContext else {
            print("TemperatureRecorder: No ModelContext available for date query")
            return []
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let predicate = #Predicate<TemperatureRecord> { record in
            record.timestamp >= startOfDay && record.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<TemperatureRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("TemperatureRecorder: Failed to load records for date: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - 获取指定时间范围的记录
    func getRecords(from startDate: Date, to endDate: Date) -> [TemperatureRecord] {
        guard let context = modelContext else {
            print("TemperatureRecorder: No ModelContext available for range query")
            return []
        }
        
        let predicate = #Predicate<TemperatureRecord> { record in
            record.timestamp >= startDate && record.timestamp <= endDate
        }
        
        let descriptor = FetchDescriptor<TemperatureRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("TemperatureRecorder: Failed to load records for range: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - 获取最近的记录
    func getRecentRecords(limit: Int = 10) -> [TemperatureRecord] {
        guard let context = modelContext else {
            print("TemperatureRecorder: No ModelContext available for recent records")
            return []
        }
        
        var descriptor = FetchDescriptor<TemperatureRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("TemperatureRecorder: Failed to load recent records: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - 获取总记录数
    func getTotalRecordCount() -> Int {
        guard let context = modelContext else {
            print("TemperatureRecorder: No ModelContext available for count query")
            return 0
        }
        
        let descriptor = FetchDescriptor<TemperatureRecord>()
        
        do {
            let records = try context.fetch(descriptor)
            return records.count
        } catch {
            print("TemperatureRecorder: Failed to get total record count: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - 删除指定记录
    func deleteRecord(_ record: TemperatureRecord) {
        guard let context = modelContext else {
            print("TemperatureRecorder: No ModelContext available for deletion")
            return
        }
        
        context.delete(record)
        
        do {
            try context.save()
            loadTodayRecords()
            print("TemperatureRecorder: Record deleted successfully")
        } catch {
            print("TemperatureRecorder: Failed to delete record: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 清除旧记录（保留最近7天）
    func cleanOldRecords() {
        guard let context = modelContext else {
            print("TemperatureRecorder: No ModelContext available for cleanup")
            return
        }
        
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let predicate = #Predicate<TemperatureRecord> { record in
            record.timestamp < sevenDaysAgo
        }
        
        let descriptor = FetchDescriptor<TemperatureRecord>(predicate: predicate)
        
        do {
            let oldRecords = try context.fetch(descriptor)
            for record in oldRecords {
                context.delete(record)
            }
            try context.save()
            print("TemperatureRecorder: Cleaned \(oldRecords.count) old records")
        } catch {
            print("TemperatureRecorder: Failed to clean old records: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 清除所有记录
    func clearAllRecords() {
        guard let context = modelContext else {
            print("TemperatureRecorder: No ModelContext available for clearing")
            return
        }
        
        let descriptor = FetchDescriptor<TemperatureRecord>()
        
        do {
            let allRecords = try context.fetch(descriptor)
            for record in allRecords {
                context.delete(record)
            }
            try context.save()
            
            todayRecords = []
            todayStats = TemperatureStats(records: [])
            
            print("TemperatureRecorder: Cleared all \(allRecords.count) records")
        } catch {
            print("TemperatureRecorder: Failed to clear all records: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 导出记录数据
    func exportRecordsAsJSON() -> String? {
        let allRecords = getRecords(from: Date.distantPast, to: Date())
        
        let exportData = allRecords.map { record in
            [
                "timestamp": ISO8601DateFormatter().string(from: record.timestamp),
                "thermalState": record.thermalState.rawValue,
                "temperatureValue": record.temperatureValue,
                "deviceName": record.deviceName
            ]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("TemperatureRecorder: Failed to export records as JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 获取温度统计信息
    func getTemperatureStats(for date: Date) -> TemperatureStats {
        let records = getRecords(for: date)
        return TemperatureStats(records: records)
    }
    
    // MARK: - 获取周统计信息
    func getWeeklyStats() -> TemperatureStats {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let records = getRecords(from: weekAgo, to: Date())
        return TemperatureStats(records: records)
    }
    
    // MARK: - 获取月统计信息
    func getMonthlyStats() -> TemperatureStats {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let records = getRecords(from: monthAgo, to: Date())
        return TemperatureStats(records: records)
    }
    
    // MARK: - 检查今日是否有记录
    func hasTodayRecords() -> Bool {
        return !todayRecords.isEmpty
    }
    
    // MARK: - 获取今日最后一次记录时间
    func getLastRecordTime() -> Date? {
        return todayRecords.last?.timestamp
    }
    
    // MARK: - 强制刷新数据
    func refresh() {
        loadTodayRecords()
    }
    
    // MARK: - 数据验证
    private func validateRecord(_ record: TemperatureRecord) -> Bool {
        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        return record.timestamp >= oneYearAgo && record.timestamp <= now
    }
    
    // MARK: - 内存管理
    func performMaintenanceTasks() {
        Task { @MainActor in
            cleanOldRecords()
            loadTodayRecords()
            print("TemperatureRecorder: Maintenance tasks completed")
        }
    }
}
