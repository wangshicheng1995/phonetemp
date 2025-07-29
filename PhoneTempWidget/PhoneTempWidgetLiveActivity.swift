//
//  PhoneTempWidgetLiveActivity.swift
//  PhoneTempWidget
//
//  Created by Echo Wang on 2025/7/15.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Live Activity Widget 配置
struct PhoneTempWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ThermalActivityAttributes.self) { context in
            // 锁屏/横幅 UI
            lockScreenView(context: context)
        } dynamicIsland: { context in
            // 灵动岛 UI
            DynamicIsland {
                // 展开状态的 UI
                DynamicIslandExpandedRegion(.leading) {
                    thermalIconLarge(for: context.state.thermalState)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatTime(context.state.lastUpdateTime))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        statusIndicator(for: context.state.thermalState)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("设备热度状态")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(context.state.thermalState.rawValue)
                                .font(.headline)
                                .foregroundColor(colorForState(context.state.thermalState))
                        }
                        
                        Spacer()
                        
                        Button(intent: OpenAppIntent()) {
                            Text("查看详情")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(colorForState(context.state.thermalState).opacity(0.2))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                // 紧凑模式左侧
                thermalIconSmall(for: context.state.thermalState)
            } compactTrailing: {
                // 紧凑模式右侧
                statusIndicator(for: context.state.thermalState)
            } minimal: {
                // 最小模式
                thermalIconMini(for: context.state.thermalState)
            }
            .widgetURL(URL(string: "phoneTemp://liveactivity"))
            .keylineTint(colorForState(context.state.thermalState))
        }
    }
}

// MARK: - 锁屏/横幅视图
private func lockScreenView(context: ActivityViewContext<ThermalActivityAttributes>) -> some View {
    HStack(spacing: 16) {
        // 温度图标
        thermalIcon(for: context.state.thermalState)
            .frame(width: 40, height: 40)
        
        // 状态信息
        VStack(alignment: .leading, spacing: 4) {
            Text("设备热度")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(context.state.thermalState.rawValue)
                .font(.headline)
                .foregroundColor(.primary)
        }
        
        Spacer()
        
        // 时间和状态指示器
        VStack(alignment: .trailing, spacing: 4) {
            Text(formatTime(context.state.lastUpdateTime))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            statusIndicator(for: context.state.thermalState)
        }
    }
    .padding()
    .background(.regularMaterial)
    .cornerRadius(12)
}

// MARK: - UI 组件

private func thermalIcon(for state: ThermalState) -> some View {
    ZStack {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        colorForState(state).opacity(0.3),
                        colorForState(state).opacity(0.1)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 20
                )
            )
        
        // 使用模板模式确保正确着色
        Image("live_activity_icon")
            .renderingMode(.template)  // 关键：模板模式
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .foregroundColor(colorForState(state))
    }
}

// 为不同场景提供不同尺寸，使用同一个矢量文件
private func thermalIconLarge(for state: ThermalState) -> some View {
    ZStack {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        colorForState(state).opacity(0.3),
                        colorForState(state).opacity(0.1)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 25
                )
            )
        
        Image("live_activity_icon")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
            .foregroundColor(colorForState(state))
    }
}

private func thermalIconSmall(for state: ThermalState) -> some View {
    ZStack {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        colorForState(state).opacity(0.4),
                        colorForState(state).opacity(0.2)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 10
                )
            )
        
        Image("live_activity_icon")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 12, height: 12)
            .foregroundColor(colorForState(state))
    }
}

private func thermalIconMini(for state: ThermalState) -> some View {
    Image("live_activity_icon")
        .renderingMode(.template)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 8, height: 8)
        .foregroundColor(colorForState(state))
}

private func statusIndicator(for state: ThermalState) -> some View {
    Circle()
        .fill(colorForState(state))
        .frame(width: 8, height: 8)
}

private func colorForState(_ state: ThermalState) -> Color {
    switch state {
    case .normal:
        return .green
    case .fair:
        return .yellow
    case .serious:
        return .orange
    case .critical:
        return .red
    }
}

private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

// MARK: - App Intent for Button Actions
struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "打开手机温度"
    
    func perform() async throws -> some IntentResult {
        // 这里可以添加特定的逻辑
        return .result()
    }
}

// MARK: - Preview Extensions
extension ThermalActivityAttributes {
    fileprivate static var preview: ThermalActivityAttributes {
        ThermalActivityAttributes()
    }
}

extension ThermalActivityAttributes.ContentState {
    fileprivate static var normal: ThermalActivityAttributes.ContentState {
        ThermalActivityAttributes.ContentState(thermalState: .normal)
    }
    
    fileprivate static var fair: ThermalActivityAttributes.ContentState {
        ThermalActivityAttributes.ContentState(thermalState: .fair)
    }
    
    fileprivate static var serious: ThermalActivityAttributes.ContentState {
        ThermalActivityAttributes.ContentState(thermalState: .serious)
    }
    
    fileprivate static var critical: ThermalActivityAttributes.ContentState {
        ThermalActivityAttributes.ContentState(thermalState: .critical)
    }
}

// MARK: - Preview 配置

#Preview("锁屏通知", as: .content, using: ThermalActivityAttributes.preview) {
    PhoneTempWidgetLiveActivity()
} contentStates: {
    ThermalActivityAttributes.ContentState.normal
    ThermalActivityAttributes.ContentState.fair
    ThermalActivityAttributes.ContentState.serious
    ThermalActivityAttributes.ContentState.critical
}

#Preview("灵动岛 - 最小化", as: .dynamicIsland(.minimal), using: ThermalActivityAttributes.preview) {
    PhoneTempWidgetLiveActivity()
} contentStates: {
    ThermalActivityAttributes.ContentState.normal
    ThermalActivityAttributes.ContentState.fair
    ThermalActivityAttributes.ContentState.serious
    ThermalActivityAttributes.ContentState.critical
}

#Preview("灵动岛 - 紧凑模式", as: .dynamicIsland(.compact), using: ThermalActivityAttributes.preview) {
    PhoneTempWidgetLiveActivity()
} contentStates: {
    ThermalActivityAttributes.ContentState.normal
    ThermalActivityAttributes.ContentState.fair
    ThermalActivityAttributes.ContentState.serious
    ThermalActivityAttributes.ContentState.critical
}

#Preview("灵动岛 - 展开模式", as: .dynamicIsland(.expanded), using: ThermalActivityAttributes.preview) {
    PhoneTempWidgetLiveActivity()
} contentStates: {
    ThermalActivityAttributes.ContentState.normal
    ThermalActivityAttributes.ContentState.fair
    ThermalActivityAttributes.ContentState.serious
    ThermalActivityAttributes.ContentState.critical
}
