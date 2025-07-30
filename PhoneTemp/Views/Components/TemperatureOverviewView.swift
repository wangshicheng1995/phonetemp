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
                    
                    // 主要数据区域（包含范围和今天标签）
                    mainDataSection
                    
                    // 图表区域
                    chartSection
                    
                    // 最新记录信息
                    latestRecordSection
                    
                    // 统计数据区域
                    statsSection
                    
                    // 教育内容区域（灰色背景）
                    educationSection
                }
            }
        }
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
            Text("设备热度")
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
                    Text("关于")
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
            .onChange(of: selectedTimeRange) { _, newValue in
                // 如果选择了不可用的选项，自动切换回日选项
                if !newValue.isAvailable {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedTimeRange = .day
                        
                        // 可以添加触觉反馈提示用户
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
                
                // 触发数据重新加载
                loadDataForSelectedRange()
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 主要数据区域

    private var mainDataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 范围标签
            Text("范围")
                .font(.footnote)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            // 状态范围显示
            HStack(alignment: .bottom, spacing: 8) {
                Text(stateRangeText)
                    .font(.system(size: 38, weight: .light))
                    .foregroundColor(.primary)
                
                Text("状态")
                    .font(.title3)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 3)
            }
            
            // 时间范围标签
            Text(timeRangeLabel)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 图表区域

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            TemperatureChartView(records: currentRecords, timeRange: selectedTimeRange)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 0)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 最新记录区域

    private var latestRecordSection: some View {
        Group {
            if let latestRecord = currentRecords.last {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最新：\(latestRecord.formattedTime)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(latestRecord.color))
                            .frame(width: 10, height: 10)
                        
                        Text(latestRecord.stateDescription)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 200)
                        .stroke(Color(UIColor.separator), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 统计数据区域

    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("状态统计")
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
                    value: "\(currentStats.totalRecords)",
                    subtitle: timeRangeLabel,
                    color: .blue
                )
                
                StatCard(
                    title: "主要状态",
                    value: currentStats.formattedMostCommonState,
                    subtitle: "最常见",
                    color: .green
                )
                
                StatCard(
                    title: "峰值状态",
                    value: currentStats.peakState.rawValue,
                    subtitle: "最高状态",
                    color: colorForState(currentStats.peakState)
                )
                
                StatCard(
                    title: "正常时长",
                    value: formatDuration(currentStats.longestNormalPeriod),
                    subtitle: "最长持续",
                    color: .orange
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 教育内容区域

    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("关于设备状态")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("设备状态监测帮助你了解手机的运行状态和发热程度。我们直接显示设备的温度状态，让你更直观地了解设备当前的工作情况。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            // 设备发热科普内容
            VStack(alignment: .leading, spacing: 12) {
                EducationRow(
                    icon: "cpu",
                    title: "什么会让设备快速升温？",
                    description: "高性能应用（游戏、视频录制）、充电、阳光直射、后台应用过多、系统更新等都会让设备从正常状态变为发热状态。"
                )
                
                EducationRow(
                    icon: "snowflake",
                    title: "如何给设备降温？",
                    description: "关闭高耗能应用、降低屏幕亮度、停止充电、放置在通风处、启用低电量模式等方法都能有效让设备恢复到正常状态。"
                )
                
                EducationRow(
                    icon: "exclamationmark.triangle",
                    title: "不同状态对设备的影响",
                    description: "轻微发热时设备仍可正常使用；中度发热时系统开始限制性能；严重发热时可能自动关机以保护硬件。"
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
        .background(Color(.systemGray6))
        .padding(.top, 8)
        .padding(.bottom, 40)
    }
    
    // MARK: - 计算属性和辅助方法
    
    private var currentRecords: [TemperatureRecord] {
        switch selectedTimeRange {
        case .day:
            return recorder.todayRecords
        case .week:
            return getRecordsForCurrentWeek()
        case .month:
            return getRecordsForCurrentMonth()
        case .sixMonths:
            return getRecordsForSixMonths()
        case .year:
            return getRecordsForCurrentYear()
        }
    }
    
    private var currentStats: TemperatureStats {
        return TemperatureStats(records: currentRecords)
    }
    
    private var timeRangeLabel: String {
        switch selectedTimeRange {
        case .day:
            return "今天"
        case .week:
            return "本周"
        case .month:
            return "本月"
        case .sixMonths:
            return "6个月"
        case .year:
            return "今年"
        }
    }

    private var stateRangeText: String {
        guard !currentRecords.isEmpty else { return "无数据" }
        
        let sortedRecords = currentRecords.sorted { $0.internalValue < $1.internalValue }
        guard let minState = sortedRecords.first?.stateDescription,
              let maxState = sortedRecords.last?.stateDescription
        else {
            return "无数据"
        }
        
        if minState == maxState {
            return minState
        } else {
            return "\(minState) - \(maxState)"
        }
    }
    
    // MARK: - 数据加载方法
    
    private func loadDataForSelectedRange() {
        // 触发UI刷新
        DispatchQueue.main.async {
            recorder.refresh()
        }
    }
    
    private func getRecordsForCurrentWeek() -> [TemperatureRecord] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }
        
        return recorder.todayRecords.filter { record in
            weekInterval.contains(record.timestamp)
        }
    }
    
    private func getRecordsForCurrentMonth() -> [TemperatureRecord] {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
            return []
        }
        
        return recorder.todayRecords.filter { record in
            monthInterval.contains(record.timestamp)
        }
    }
    
    private func getRecordsForSixMonths() -> [TemperatureRecord] {
        let calendar = Calendar.current
        let now = Date()
        guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) else {
            return []
        }
        
        return recorder.todayRecords.filter { record in
            record.timestamp >= sixMonthsAgo
        }
    }
    
    private func getRecordsForCurrentYear() -> [TemperatureRecord] {
        let calendar = Calendar.current
        let now = Date()
        guard let yearInterval = calendar.dateInterval(of: .year, for: now) else {
            return []
        }
        
        return recorder.todayRecords.filter { record in
            yearInterval.contains(record.timestamp)
        }
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
        .background(Color(.tertiarySystemGroupedBackground))
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
                        Text("关于设备状态监测")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("了解如何保护你的设备，延长使用寿命")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // 详细教育内容
                    VStack(alignment: .leading, spacing: 16) {
                        EducationSection(
                            title: "设备状态说明",
                            icon: "thermometer.sun",
                            content: """
                            我们监测设备的四种温度状态：
                            
                            🟢 正常状态
                            • 设备运行流畅，温度在正常范围内
                            • 可以放心使用各种应用功能
                            
                            🟡 轻微发热
                            • 设备开始升温，但仍在安全范围
                            • 建议适当减少高耗能操作
                            
                            🟠 中度发热
                            • 系统开始限制性能以保护硬件
                            • 需要立即采取降温措施
                            
                            🔴 严重发热
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
                            title: "不同状态的危害",
                            icon: "exclamationmark.triangle.fill",
                            content: """
                            长期处于发热状态会对设备造成以下影响：
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
                            当设备状态为发热时，你可以：
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
