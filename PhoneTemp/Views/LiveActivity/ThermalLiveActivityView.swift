//
//  ThermalLiveActivityView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Live Activity 锁屏/横幅视图
struct ThermalLiveActivityView: View {
    let context: ActivityViewContext<ThermalActivityAttributes>
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.8)
            
            HStack(spacing: 12) {
                // 温度图标
                thermalIcon
                
                // 温度状态信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.thermalState.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("轻点查看详情")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // 时间信息
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(context.state.lastUpdateTime))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .cornerRadius(16)
    }
    
    // MARK: - 温度图标
    private var thermalIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            statusColor.opacity(0.3),
                            statusColor.opacity(0.1)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)
            
            Image(systemName: "thermometer")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(statusColor)
        }
    }
    
    // MARK: - 状态颜色
    private var statusColor: Color {
        switch context.state.thermalState {
        case .normal:
            return Color.green
        case .fair:
            return Color.yellow
        case .serious:
            return Color.orange
        case .critical:
            return Color.red
        }
    }
    
    // MARK: - 时间格式化
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Live Activity 配置说明
// 
// 在 iOS 16.1+ 中，Live Activity 需要通过以下方式配置：
// 1. 定义 ActivityAttributes（已完成）
// 2. 在主应用中通过 Activity.request() 启动（已完成）
// 3. 系统会自动处理 Live Activity 的 UI 显示
// 
// 不需要显式的 Widget 配置或 @main 注解，
// 因为 Live Activity 是通过 ActivityKit 框架动态管理的