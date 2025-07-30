//
//  ThermalWaveConfiguration.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/29.
//


//
//  ThermalWaveConfiguration.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/29.
//

import SwiftUI

// MARK: - 热度海浪配置数据模型
struct ThermalWaveConfiguration {
    let percent: Double          // 海浪高度百分比
    let colors: [Color]         // 海浪颜色渐变
    let animationSpeed: Double  // 动画速度（秒）
    let waveIntensity: Double   // 波浪强度
    let glowColors: [Color]     // 发光效果颜色
    let displayText: String     // 显示文本
    let textColor: Color        // 文本颜色
    
    // 根据热度状态获取配置
    static func configuration(for thermalState: ThermalState) -> ThermalWaveConfiguration {
        switch thermalState {
        case .normal:
            return ThermalWaveConfiguration(
                percent: 22.0,
                colors: [
                    Color(red: 0.2, green: 0.8, blue: 0.6).opacity(0.8),
                    Color(red: 0.1, green: 0.6, blue: 0.9).opacity(0.6)
                ],
                animationSpeed: 2.0,
                waveIntensity: 0.015,
                glowColors: [
                    Color(red: 0.2, green: 0.8, blue: 0.6).opacity(0.3),
                    Color(red: 0.1, green: 0.6, blue: 0.9).opacity(0.1)
                ],
                displayText: "正常",
                textColor: .white
            )
            
        case .fair:
            return ThermalWaveConfiguration(
                percent: 42.0,
                colors: [
                    Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.8),
                    Color(red: 0.9, green: 0.7, blue: 0.1).opacity(0.6)
                ],
                animationSpeed: 1.5,
                waveIntensity: 0.020,
                glowColors: [
                    Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.4),
                    Color(red: 0.9, green: 0.7, blue: 0.1).opacity(0.2)
                ],
                displayText: "轻微发热",
                textColor: .white
            )
            
        case .serious:
            return ThermalWaveConfiguration(
                percent: 68.0,
                colors: [
                    Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.9),
                    Color(red: 0.9, green: 0.3, blue: 0.05).opacity(0.7)
                ],
                animationSpeed: 1.0,
                waveIntensity: 0.025,
                glowColors: [
                    Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.5),
                    Color(red: 0.9, green: 0.3, blue: 0.05).opacity(0.3)
                ],
                displayText: "中度发热",
                textColor: .white
            )
            
        case .critical:
            return ThermalWaveConfiguration(
                percent: 88.0,
                colors: [
                    Color(red: 1.0, green: 0.2, blue: 0.2).opacity(0.95),
                    Color(red: 0.8, green: 0.1, blue: 0.1).opacity(0.8)
                ],
                animationSpeed: 0.7,
                waveIntensity: 0.030,
                glowColors: [
                    Color(red: 1.0, green: 0.2, blue: 0.2).opacity(0.6),
                    Color(red: 0.8, green: 0.1, blue: 0.1).opacity(0.4)
                ],
                displayText: "严重发热",
                textColor: .white
            )
        }
    }
    
    // 获取背景渐变色
    var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: glowColors),
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    // 获取海浪渐变色
    var waveGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .bottom,
            endPoint: .top
        )
    }
}