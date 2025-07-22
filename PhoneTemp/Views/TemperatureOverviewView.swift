//
//  TemperatureOverviewView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/22.
//

import SwiftUI

// MARK: - 温度回顾主视图
struct TemperatureOverviewView: View {
    private let recorder: TemperatureRecorder
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange: TimeRange = .day
    @State private var showingEducationSheet = false
    
    // 时间范围选择
    enum TimeRange: String, CaseIterable {
        case day = "日"
        case week = "周"
        case month = "月"
        case sixMonths = "6个月"
        case year = "年"
        
        var isAvailable: Bool {
            switch self {
            case .day: return true
            default: return false // 其他范围暂未实现
            }
        }
    }
    
    // 初始化器
    init(recorder: TemperatureRecorder? = nil) {
        self.recorder = recorder ?? TemperatureRecorder.previewInstance()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航区域
            topNavigationArea
            
            ScrollView {
                VStack(spacing: 0) {
                    // 时间范围选择器
                    timeRangeSelector
                    
                    // 主要数据区域
                    mainDataSection
                    
                    // 图表区域
                    chartSection
                    
                    // 统计数据区域
                    statsSection
                    
                    // 教育内容区域
                    educationSection
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            recorder.loadTodayRecords()
        }
        .sheet(isPresented: $showingEducationSheet) {
            TemperatureEducationSheet()
        }
    }
    
    // MARK: - 顶部导航区域
    private var topNavigationArea: some View {
        ZStack {
            // 标题居中显示
            Text("设备温度")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // 左右按钮
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: { showingEducationSheet = true }) {
                    Text("添加数据")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 时间范围选择器
    private var timeRangeSelector: some View {
        VStack(spacing: 0) {
            // 使用原生分段控件，完全模仿健康应用的样式
            Picker("时间范围", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue)
                        .tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .onChange(of: selectedTimeRange) { oldValue, newValue in
                // 如果选择了不可用的选项，自动切换回日选项
                if !newValue.isAvailable {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedTimeRange = .day
                        
                        // 可以添加触觉反馈提示用户
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - 主要数据区域
    private var mainDataSection: some View {
        VStack(spacing: 20) {
            // 范围和温度等级显示
            HStack(alignment: .bottom, spacing: 8) {
                Text(heatLevelRangeText)
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.primary)
                
                Text("级温度")
                    .font(.title3)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 今天标签和最新数据
            HStack {
                Text("今天")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // 最新记录信息
            if let latestRecord = recorder.todayRecords.last {
                HStack {
                    Text("最新：")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(latestRecord.timestamp))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorForState(latestRecord.thermalState))
                            .frame(width: 8, height: 8)
                        
                        Text(latestRecord.heatLevelDescription)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("温度")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
            } else {
                HStack {
                    Text("暂无记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 图表区域
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            TemperatureChartView(records: recorder.todayRecords)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .padding(.top, 8)
    }
    
    // MARK: - 统计数据区域
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("温度统计")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCard(
                    title: "记录次数",
                    value: "\(recorder.todayStats.totalRecords)",
                    subtitle: "今日",
                    color: .blue
                )
                
                StatCard(
                    title: "平均温度",
                    value: recorder.todayStats.formattedAverageHeatLevelShort,
                    subtitle: "温度等级",
                    color: .green
                )
                
                StatCard(
                    title: "峰值状态",
                    value: recorder.todayStats.peakState.rawValue,
                    subtitle: "最高温度",
                    color: colorForState(recorder.todayStats.peakState)
                )
                
                StatCard(
                    title: "正常时长",
                    value: formatDuration(recorder.todayStats.longestNormalPeriod),
                    subtitle: "最长持续",
                    color: .orange
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .padding(.top, 8)
    }
    
    // MARK: - 教育内容区域
    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("关于设备温度")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("设备温度监测帮助你了解手机的运行状态和发热程度。我们使用1-10级温度等级来直观显示设备的温度状态，让你更好地保护设备。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            // 设备发热科普内容
            VStack(alignment: .leading, spacing: 12) {
                EducationRow(
                    icon: "cpu",
                    title: "什么会让设备快速升温？",
                    description: "高性能应用（游戏、视频录制）、充电、阳光直射、后台应用过多、系统更新等都会快速提升设备温度等级。"
                )
                
                EducationRow(
                    icon: "snowflake",
                    title: "如何给设备降温？",
                    description: "关闭高耗能应用、降低屏幕亮度、停止充电、放置在通风处、启用低电量模式等方法都能有效降低温度等级。"
                )
                
                EducationRow(
                    icon: "exclamationmark.triangle",
                    title: "高温度对设备的影响",
                    description: "长期高温度会影响电池寿命、降低处理器性能、可能导致意外关机，严重时还可能造成硬件损坏。"
                )
                
                EducationRow(
                    icon: "checkmark.shield",
                    title: "保持设备健康的技巧",
                    description: "定期清理后台应用、使用原装充电器、选择透气手机壳、避免边充电边使用、保持良好的使用环境。"
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .padding(.top, 8)
        .padding(.bottom, 40)
    }
    
    // MARK: - 辅助方法
    
    private var heatLevelRangeText: String {
        let stats = recorder.todayStats
        if stats.totalRecords == 0 {
            return "0-0"
        }
        
        let minValue = recorder.todayRecords.map(\.heatLevel).min() ?? 0.0
        let maxValue = recorder.todayRecords.map(\.heatLevel).max() ?? 0.0
        
        return "\(Int(minValue))-\(Int(maxValue))"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "\(minutes)分钟"
        } else {
            return "少于1分钟"
        }
    }
    
    private func colorForState(_ state: ThermalState) -> Color {
        switch state {
        case .normal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - 统计卡片视图
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

// MARK: - 教育行视图
struct EducationRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - 温度教育详情页
struct TemperatureEducationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题区域
                    VStack(alignment: .leading, spacing: 8) {
                        Text("关于设备温度监测")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("了解如何保护你的设备，延长使用寿命")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // 详细教育内容
                    VStack(alignment: .leading, spacing: 16) {
                        EducationSection(
                            title: "什么是温度等级？",
                            icon: "thermometer.sun",
                            content: """
                            温度等级是我们自定义的1-10级评分系统，用于直观显示设备的发热程度：
                            
                            🟢 1-3级：正常温度
                            • 设备运行流畅，温度在正常范围内
                            • 可以放心使用各种应用功能
                            
                            🟡 4-6级：轻微发热  
                            • 设备开始升温，但仍在安全范围
                            • 建议适当减少高耗能操作
                            
                            🟠 7-8级：明显发热
                            • 系统开始限制性能以保护硬件
                            • 需要立即采取降温措施
                            
                            🔴 9-10级：严重发热
                            • 可能触发自动关机保护机制
                            • 必须停止使用并等待设备冷却
                            """
                        )
                        
                        EducationSection(
                            title: "设备为什么会发热？",
                            icon: "cpu",
                            content: """
                            设备发热是正常现象，主要原因包括：
                            • 处理器高负载运行（游戏、视频处理）
                            • 电池充电过程中的化学反应
                            • 屏幕长时间高亮度显示
                            • 多个应用同时在后台运行
                            • 网络信号差导致的功率增加
                            • 环境温度过高
                            """
                        )
                        
                        EducationSection(
                            title: "高温度的危害",
                            icon: "exclamationmark.triangle.fill",
                            content: """
                            长期高温度会对设备造成以下影响：
                            • 电池容量永久性下降
                            • 处理器自动降频保护
                            • 系统卡顿和应用崩溃
                            • 意外关机保护机制启动
                            • 硬件寿命缩短
                            • 触摸屏响应异常
                            """
                        )
                        
                        EducationSection(
                            title: "有效降温方法",
                            icon: "wind.snow",
                            content: """
                            当设备温度等级过高时，你可以：
                            • 立即关闭高耗能应用和游戏
                            • 降低屏幕亮度到最低
                            • 停止充电并拔掉充电器
                            • 关闭不必要的后台应用
                            • 启用飞行模式或低电量模式
                            • 将设备放在通风阴凉处
                            • 取下手机壳帮助散热
                            """
                        )
                        
                        EducationSection(
                            title: "预防措施",
                            icon: "shield.checkered",
                            content: """
                            日常使用中的预防建议：
                            • 避免边充电边使用
                            • 选择透气性好的手机壳
                            • 定期清理后台应用
                            • 不要在阳光下长时间使用
                            • 保持系统和应用更新
                            • 使用原装或认证充电器
                            • 避免在高温环境下使用
                            """
                        )
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 教育部分视图
struct EducationSection: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    TemperatureOverviewView()
}
