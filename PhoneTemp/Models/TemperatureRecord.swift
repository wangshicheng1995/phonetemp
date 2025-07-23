//
//  TemperatureRecord.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/22.
//

import Foundation
import SwiftData
import UIKit

// MARK: - 温度记录数据模型
@Model
final class TemperatureRecord {
    var timestamp: Date
    private var thermalStateRawValue: String  // 使用字符串存储枚举的原始值
    var deviceName: String
    
    // 计算属性，用于获取和设置 ThermalState
    var thermalState: ThermalState {
        get {
            // 将存储的字符串转换回枚举
            switch thermalStateRawValue {
            case "正常":
                return .normal
            case "轻微发热":
                return .fair
            case "中度发热":
                return .serious
            case "严重发热":
                return .critical
            default:
                return .normal  // 默认值
            }
        }
        set {
            // 将枚举转换为字符串存储
            thermalStateRawValue = newValue.rawValue
        }
    }
    
    // MARK: - 初始化器
    init(timestamp: Date = Date(), thermalState: ThermalState, deviceName: String? = nil) {
        self.timestamp = timestamp
        self.thermalStateRawValue = thermalState.rawValue  // 存储枚举的原始值
        self.deviceName = deviceName ?? UIDevice.current.name
    }
    
    // MARK: - 便利初始化器（用于 Preview 和测试）
    convenience init(thermalState: ThermalState) {
        self.init(timestamp: Date(), thermalState: thermalState, deviceName: UIDevice.current.name)
    }
}

// MARK: - 温度记录扩展方法
extension TemperatureRecord {
    /// 内部数值映射（仅用于图表绘制和排序，不对外暴露）
    internal var internalValue: Double {
        switch thermalState {
        case .normal: return 2.0
        case .fair: return 4.0
        case .serious: return 7.0
        case .critical: return 9.0
        }
    }
    
    /// 获取状态描述（主要显示方式）
    var stateDescription: String {
        return thermalState.rawValue
    }
    
    /// 获取简化的状态描述
    var simpleStateDescription: String {
        switch thermalState {
        case .normal: return "正常"
        case .fair: return "轻微"
        case .serious: return "中度"
        case .critical: return "严重"
        }
    }
    
    /// 获取详细的状态描述
    var detailedStateDescription: String {
        switch thermalState {
        case .normal: return "设备运行正常"
        case .fair: return "设备略微发热"
        case .serious: return "设备明显发热"
        case .critical: return "设备严重发热"
        }
    }
    
    /// 兼容性属性：保持与原有代码的兼容
    @available(*, deprecated, message: "请使用 stateDescription 替代")
    var heatLevel: Double {
        return internalValue
    }
    
    @available(*, deprecated, message: "请使用 stateDescription 替代")
    var heatLevelDescription: String {
        return stateDescription
    }
    
    @available(*, deprecated, message: "请使用 stateDescription 替代")
    var temperatureValue: Double {
        return internalValue
    }
    
    /// 获取温度记录对应的颜色
    var color: String {
        switch thermalState {
        case .normal: return "green"
        case .fair: return "yellow"
        case .serious: return "orange"
        case .critical: return "red"
        }
    }
    
    /// 格式化时间戳为可读字符串
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
    /// 格式化日期为可读字符串
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: timestamp)
    }
}

// MARK: - 温度统计数据模型
struct TemperatureStats {
    let totalRecords: Int
    let normalCount: Int
    let fairCount: Int
    let seriousCount: Int
    let criticalCount: Int
    let mostCommonState: ThermalState  // 改名：最常见状态
    let peakState: ThermalState
    let longestNormalPeriod: TimeInterval
    
    init(records: [TemperatureRecord]) {
        self.totalRecords = records.count
        self.normalCount = records.filter { $0.thermalState == .normal }.count
        self.fairCount = records.filter { $0.thermalState == .fair }.count
        self.seriousCount = records.filter { $0.thermalState == .serious }.count
        self.criticalCount = records.filter { $0.thermalState == .critical }.count
        
        // 找出最常见的状态
        let states: [(ThermalState, Int)] = [
            (.normal, normalCount),
            (.fair, fairCount),
            (.serious, seriousCount),
            (.critical, criticalCount)
        ]
        self.mostCommonState = states.max(by: { $0.1 < $1.1 })?.0 ?? .normal
        
        // 找出峰值状态
        if criticalCount > 0 {
            self.peakState = .critical
        } else if seriousCount > 0 {
            self.peakState = .serious
        } else if fairCount > 0 {
            self.peakState = .fair
        } else {
            self.peakState = .normal
        }
        
        // 计算最长正常温度持续时间
        self.longestNormalPeriod = Self.calculateLongestNormalPeriod(records)
    }
    
    private static func calculateLongestNormalPeriod(_ records: [TemperatureRecord]) -> TimeInterval {
        let sortedRecords = records.sorted { $0.timestamp < $1.timestamp }
        var maxPeriod: TimeInterval = 0
        var currentPeriodStart: Date?
        
        for record in sortedRecords {
            if record.thermalState == .normal {
                if currentPeriodStart == nil {
                    currentPeriodStart = record.timestamp
                }
            } else {
                if let start = currentPeriodStart {
                    let period = record.timestamp.timeIntervalSince(start)
                    maxPeriod = max(maxPeriod, period)
                    currentPeriodStart = nil
                }
            }
        }
        
        // 检查最后一个正常期间
        if let start = currentPeriodStart {
            let period = Date().timeIntervalSince(start)
            maxPeriod = max(maxPeriod, period)
        }
        
        return maxPeriod
    }
}

// MARK: - 便利扩展
extension TemperatureStats {
    /// 兼容性属性：保持与原有代码的兼容
    @available(*, deprecated, message: "请使用 mostCommonState 替代")
    var averageHeatLevel: Double {
        let totalInternalValue = [
            Double(normalCount) * 2.0,
            Double(fairCount) * 4.0,
            Double(seriousCount) * 7.0,
            Double(criticalCount) * 9.0
        ].reduce(0, +)
        return totalRecords > 0 ? totalInternalValue / Double(totalRecords) : 0.0
    }
    
    @available(*, deprecated, message: "请使用 mostCommonState 替代")
    var averageValue: Double {
        return averageHeatLevel
    }
    
    /// 获取正常状态的百分比
    var normalPercentage: Double {
        guard totalRecords > 0 else { return 0 }
        return Double(normalCount) / Double(totalRecords) * 100
    }
    
    /// 获取发热状态的百分比
    var heatingPercentage: Double {
        guard totalRecords > 0 else { return 0 }
        let heatingCount = fairCount + seriousCount + criticalCount
        return Double(heatingCount) / Double(totalRecords) * 100
    }
    
    /// 获取状态范围描述
    var stateRange: String {
        let allStates = [
            (normalCount > 0 ? ThermalState.normal : nil),
            (fairCount > 0 ? ThermalState.fair : nil),
            (seriousCount > 0 ? ThermalState.serious : nil),
            (criticalCount > 0 ? ThermalState.critical : nil)
        ].compactMap { $0 }
        
        guard !allStates.isEmpty else { return "无记录" }
        
        if allStates.count == 1 {
            return allStates.first!.rawValue
        } else {
            let minState = allStates.min { $0.internalValue < $1.internalValue }!
            let maxState = allStates.max { $0.internalValue < $1.internalValue }!
            return "\(minState.rawValue) - \(maxState.rawValue)"
        }
    }
    
    /// 格式化最常见状态
    var formattedMostCommonState: String {
        return mostCommonState.rawValue
    }
    
    /// 兼容性属性
    @available(*, deprecated, message: "请使用 formattedMostCommonState 替代")
    var formattedAverageHeatLevel: String {
        return formattedMostCommonState
    }
    
    @available(*, deprecated, message: "请使用 formattedMostCommonState 替代")
    var formattedAverageHeatLevelShort: String {
        return formattedMostCommonState
    }
    
    @available(*, deprecated, message: "请使用 formattedMostCommonState 替代")
    var formattedAverageValue: String {
        return formattedMostCommonState
    }
    
    /// 格式化最长正常持续时间
    var formattedLongestNormalPeriod: String {
        let hours = Int(longestNormalPeriod / 3600)
        let minutes = Int((longestNormalPeriod.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "\(minutes)分钟"
        } else {
            return "少于1分钟"
        }
    }
}

// MARK: - ThermalState 内部值扩展
extension ThermalState {
    /// 内部数值（仅用于排序和图表，不对外暴露）
    internal var internalValue: Double {
        switch self {
        case .normal: return 2.0
        case .fair: return 4.0
        case .serious: return 7.0
        case .critical: return 9.0
        }
    }
}
