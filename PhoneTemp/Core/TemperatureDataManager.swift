//
//  TemperatureDataManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/22.
//


//
//  TemperatureDataManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/22.
//

import Foundation
import SwiftData

// MARK: - 温度数据管理器（单例）
@MainActor
class TemperatureDataManager: ObservableObject {
    static let shared = TemperatureDataManager()
    
    private(set) var modelContainer: ModelContainer?
    private(set) var modelContext: ModelContext?
    
    private init() {
        setupModelContainer()
    }
    
    // MARK: - 设置数据容器
    private func setupModelContainer() {
        do {
            let schema = Schema([
                Item.self,
                TemperatureRecord.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            self.modelContainer = container
            self.modelContext = container.mainContext
            
            print("TemperatureDataManager: ModelContainer setup successfully")
        } catch {
            print("TemperatureDataManager: Failed to setup ModelContainer: \(error.localizedDescription)")
            
            // 降级到内存数据库
            setupFallbackContainer()
        }
    }
    
    // MARK: - 降级数据容器
    private func setupFallbackContainer() {
        do {
            let schema = Schema([
                Item.self,
                TemperatureRecord.self
            ])
            let fallbackConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            let fallbackContainer = try ModelContainer(
                for: schema,
                configurations: [fallbackConfiguration]
            )
            
            self.modelContainer = fallbackContainer
            self.modelContext = fallbackContainer.mainContext
            
            print("TemperatureDataManager: Using in-memory ModelContainer as fallback")
        } catch {
            print("TemperatureDataManager: Failed to create fallback ModelContainer: \(error.localizedDescription)")
            
            // 最后的降级方案 - 使用最简单的内存容器
            createMinimalContainer()
        }
    }
    
    // MARK: - 最小化容器（最后的降级方案）
    private func createMinimalContainer() {
        do {
            let schema = Schema([TemperatureRecord.self])
            let minimalConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            let minimalContainer = try ModelContainer(
                for: schema,
                configurations: [minimalConfiguration]
            )
            
            self.modelContainer = minimalContainer
            self.modelContext = minimalContainer.mainContext
            
            print("TemperatureDataManager: Using minimal in-memory container")
        } catch {
            print("TemperatureDataManager: Critical error - failed to create any container: \(error.localizedDescription)")
            self.modelContainer = nil
            self.modelContext = nil
        }
    }
    
    // MARK: - 获取上下文
    func getModelContext() -> ModelContext? {
        return modelContext
    }
    
    // MARK: - 检查是否可用
    func isAvailable() -> Bool {
        return modelContext != nil
    }
    
    // MARK: - 数据库健康检查
    func performHealthCheck() {
        guard let context = modelContext else {
            print("TemperatureDataManager: ModelContext is nil")
            return
        }
        
        do {
            // 尝试创建一个简单的查询来测试数据库连接
            var descriptor = FetchDescriptor<TemperatureRecord>()
            descriptor.fetchLimit = 1
            
            let testRecords = try context.fetch(descriptor)
            print("TemperatureDataManager: Health check passed - found \(testRecords.count) test records")
            
            // 检查数据库状态
            checkDatabaseIntegrity()
            
        } catch {
            print("TemperatureDataManager: Health check failed: \(error.localizedDescription)")
            handleHealthCheckFailure(error)
        }
    }
    
    // MARK: - 检查数据库完整性
    private func checkDatabaseIntegrity() {
        guard let context = modelContext else { return }
        
        do {
            // 获取总记录数
            let totalDescriptor = FetchDescriptor<TemperatureRecord>()
            let totalRecords = try context.fetch(totalDescriptor)
            
            // 检查是否有无效数据
            let invalidRecords = totalRecords.filter { record in
                // 检查时间戳是否合理
                let now = Date()
                let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
                return record.timestamp < oneYearAgo || record.timestamp > now
            }
            
            if !invalidRecords.isEmpty {
                print("TemperatureDataManager: Found \(invalidRecords.count) invalid records")
                cleanupInvalidRecords(invalidRecords, context: context)
            }
            
            print("TemperatureDataManager: Database integrity check completed - \(totalRecords.count) total records")
            
        } catch {
            print("TemperatureDataManager: Integrity check failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 清理无效记录
    private func cleanupInvalidRecords(_ invalidRecords: [TemperatureRecord], context: ModelContext) {
        do {
            for record in invalidRecords {
                context.delete(record)
            }
            try context.save()
            print("TemperatureDataManager: Cleaned up \(invalidRecords.count) invalid records")
        } catch {
            print("TemperatureDataManager: Failed to cleanup invalid records: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 处理健康检查失败
    private func handleHealthCheckFailure(_ error: Error) {
        print("TemperatureDataManager: Attempting to recover from health check failure...")
        
        // 尝试重新初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setupModelContainer()
            
            // 再次检查
            if self.isAvailable() {
                print("TemperatureDataManager: Recovery successful")
            } else {
                print("TemperatureDataManager: Recovery failed - operating in degraded mode")
            }
        }
    }
    
    // MARK: - 强制重新初始化
    func forceReinitialize() {
        print("TemperatureDataManager: Force reinitializing...")
        
        // 清理当前状态
        modelContext = nil
        modelContainer = nil
        
        // 重新设置
        setupModelContainer()
        
        // 执行健康检查
        performHealthCheck()
    }
    
    // MARK: - 获取数据库统计信息
    func getDatabaseStats() -> (totalRecords: Int, todayRecords: Int, isHealthy: Bool) {
        guard let context = modelContext else {
            return (0, 0, false)
        }
        
        do {
            // 总记录数
            let totalDescriptor = FetchDescriptor<TemperatureRecord>()
            let totalRecords = try context.fetch(totalDescriptor)
            
            // 今日记录数
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            
            let todayPredicate = #Predicate<TemperatureRecord> { record in
                record.timestamp >= startOfDay && record.timestamp < endOfDay
            }
            
            let todayDescriptor = FetchDescriptor<TemperatureRecord>(predicate: todayPredicate)
            let todayRecords = try context.fetch(todayDescriptor)
            
            return (totalRecords.count, todayRecords.count, true)
            
        } catch {
            print("TemperatureDataManager: Failed to get database stats: \(error.localizedDescription)")
            return (0, 0, false)
        }
    }
}
