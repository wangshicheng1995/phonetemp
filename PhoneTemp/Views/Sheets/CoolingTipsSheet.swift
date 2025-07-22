//
//  CoolingTipsSheet.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import SwiftUI

// MARK: - 降温建议数据模型
struct CoolingTip {
    let icon: String
    let title: String
    let description: String
    let priority: TipPriority
    
    enum TipPriority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
        
        var text: String {
            switch self {
            case .high: return "紧急"
            case .medium: return "建议"
            case .low: return "可选"
            }
        }
    }
}

// MARK: - 降温Tips Sheet
struct CoolingTipsSheet: View {
    let thermalState: ThermalState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部状态显示
                    headerSection
                    
                    // 降温建议列表
                    tipsSection
                    
                    // 底部提醒
                    bottomWarning
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("降温建议")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - 顶部状态区域
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(colorForState(thermalState))
                    .frame(width: 16, height: 16)
                
                Text("当前状态：\(thermalState.rawValue)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(getStateDescription(for: thermalState))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - 建议列表区域
    private var tipsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("推荐操作")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(getCoolingTips(for: thermalState).count) 项建议")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(getCoolingTips(for: thermalState).enumerated()), id: \.offset) { index, tip in
                    CoolingTipRow(tip: tip, index: index + 1)
                }
            }
        }
    }
    
    // MARK: - 底部警告
    private var bottomWarning: some View {
        VStack(spacing: 8) {
            if thermalState == .critical {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text("设备温度过高，请立即采取降温措施")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            Text("持续高温可能影响设备性能和电池寿命")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - 辅助方法
    
    private func colorForState(_ state: ThermalState) -> Color {
        switch state {
        case .normal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        }
    }
    
    private func getStateDescription(for state: ThermalState) -> String {
        switch state {
        case .normal:
            return "设备温度正常，运行状态良好"
        case .fair:
            return "设备开始升温，建议适当降低使用强度"
        case .serious:
            return "设备温度较高，需要采取降温措施"
        case .critical:
            return "设备温度危险，请立即停止高耗能操作"
        }
    }
    
    private func getCoolingTips(for state: ThermalState) -> [CoolingTip] {
        switch state {
        case .normal:
            return normalStateTips
        case .fair:
            return fairStateTips
        case .serious:
            return seriousStateTips
        case .critical:
            return criticalStateTips
        }
    }
    
    // MARK: - 各状态降温建议
    
    private var normalStateTips: [CoolingTip] {
        [
            CoolingTip(
                icon: "checkmark.circle.fill",
                title: "保持良好习惯",
                description: "继续当前的使用方式，设备状态良好",
                priority: .low
            ),
            CoolingTip(
                icon: "thermometer.sun",
                title: "避免阳光直射",
                description: "不要将设备长时间放置在阳光下或高温环境中",
                priority: .medium
            ),
            CoolingTip(
                icon: "case",
                title: "选择透气保护套",
                description: "使用具有良好散热性能的手机壳",
                priority: .low
            ),
            CoolingTip(
                icon: "battery.100",
                title: "合理充电",
                description: "避免边充电边使用，选择原装充电器",
                priority: .medium
            ),
            CoolingTip(
                icon: "app.badge",
                title: "定期清理应用",
                description: "关闭不必要的后台应用，保持系统流畅",
                priority: .low
            )
        ]
    }
    
    private var fairStateTips: [CoolingTip] {
        [
            CoolingTip(
                icon: "pause.circle.fill",
                title: "暂停高耗能应用",
                description: "关闭游戏、视频录制等高性能需求的应用",
                priority: .high
            ),
            CoolingTip(
                icon: "sun.max.fill",
                title: "降低屏幕亮度",
                description: "将屏幕亮度调至舒适的较低水平",
                priority: .medium
            ),
            CoolingTip(
                icon: "wifi.slash",
                title: "关闭不必要连接",
                description: "暂时关闭WiFi、蓝牙、定位等功能",
                priority: .medium
            ),
            CoolingTip(
                icon: "battery.0",
                title: "停止充电",
                description: "如果正在充电，请暂时拔掉充电器",
                priority: .high
            ),
            CoolingTip(
                icon: "wind",
                title: "改善散热环境",
                description: "将设备放在通风良好的地方，避免捂住散热孔",
                priority: .medium
            ),
            CoolingTip(
                icon: "camera.fill",
                title: "暂停拍摄功能",
                description: "停止使用相机、录像等功能",
                priority: .medium
            )
        ]
    }
    
    private var seriousStateTips: [CoolingTip] {
        [
            CoolingTip(
                icon: "power",
                title: "启用低电量模式",
                description: "立即开启省电模式，降低系统性能",
                priority: .high
            ),
            CoolingTip(
                icon: "xmark.circle.fill",
                title: "关闭所有应用",
                description: "强制关闭所有后台应用，只保留必要功能",
                priority: .high
            ),
            CoolingTip(
                icon: "snowflake",
                title: "物理降温",
                description: "将设备放在阴凉处，可用风扇辅助散热（避免直吹）",
                priority: .high
            ),
            CoolingTip(
                icon: "airplane",
                title: "开启飞行模式",
                description: "暂时开启飞行模式，减少网络通信耗电",
                priority: .medium
            ),
            CoolingTip(
                icon: "case",
                title: "移除保护套",
                description: "临时取下手机壳和屏幕保护膜，提高散热效率",
                priority: .medium
            ),
            CoolingTip(
                icon: "moon.fill",
                title: "调至最暗屏幕",
                description: "将屏幕亮度调至最低，减少显示屏发热",
                priority: .medium
            )
        ]
    }
    
    private var criticalStateTips: [CoolingTip] {
        [
            CoolingTip(
                icon: "exclamationmark.triangle.fill",
                title: "立即停止使用",
                description: "马上停止所有操作，让设备休息降温",
                priority: .high
            ),
            CoolingTip(
                icon: "power",
                title: "关机降温",
                description: "考虑完全关机10-15分钟，让设备充分散热",
                priority: .high
            ),
            CoolingTip(
                icon: "wind.snow",
                title: "紧急物理降温",
                description: "放置在空调房间或风扇前，但避免直接冷风吹袭",
                priority: .high
            ),
            CoolingTip(
                icon: "battery.25",
                title: "断开所有连接",
                description: "拔掉充电器，关闭所有无线连接功能",
                priority: .high
            ),
            CoolingTip(
                icon: "case",
                title: "完全裸机散热",
                description: "移除所有配件和保护套，让设备直接散热",
                priority: .high
            ),
            CoolingTip(
                icon: "clock.fill",
                title: "等待自然冷却",
                description: "耐心等待设备温度自然降低，不要强制使用",
                priority: .medium
            ),
            CoolingTip(
                icon: "phone.down.fill",
                title: "避免水冷降温",
                description: "绝对不要用水或湿布直接接触设备进行降温",
                priority: .high
            )
        ]
    }
}

// MARK: - 建议行视图
struct CoolingTipRow: View {
    let tip: CoolingTip
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            ZStack {
                Circle()
                    .fill(tip.priority.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: tip.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(tip.priority.color)
            }
            
            // 中间内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 优先级标签
                    Text(tip.priority.text)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(tip.priority.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(tip.priority.color.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(tip.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            // 右侧序号
            Text("\(index)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
                .background(Color(.systemGray5))
                .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview
#Preview("正常状态") {
    CoolingTipsSheet(thermalState: .normal)
}

#Preview("轻微发热") {
    CoolingTipsSheet(thermalState: .fair)
}

#Preview("中度发热") {
    CoolingTipsSheet(thermalState: .serious)
}

#Preview("严重发热") {
    CoolingTipsSheet(thermalState: .critical)
}
