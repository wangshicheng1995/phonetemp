//
//  TemperatureChartView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/22.
//

import SwiftUI
import Charts

// MARK: - 时间范围枚举（与TemperatureOverviewView保持一致）
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

// MARK: - 温度图表数据点
struct TemperatureChartData: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double  // 内部数值，仅用于图表绘制
    let state: ThermalState
    let timeLabel: String  // 显示在X轴的标签
    let categoryIndex: Int  // 用于条形图分组
    
    var color: Color {
        // 使用自定义的 barChart Color Set
        return Color("barChart")
    }
    
    /// 获取状态描述
    var stateDescription: String {
        return state.rawValue
    }
}

// MARK: - 图表数据分组结构
struct ChartDataGroup: Identifiable {
    let id = UUID()
    let timeLabel: String
    let categoryIndex: Int
    let averageValue: Double
    let records: [TemperatureRecord]
    let mostCommonState: ThermalState
    
    var color: Color {
        // 使用自定义的 barChart Color Set
        return Color("barChart")
    }
    
    var stateDescription: String {
        return mostCommonState.rawValue
    }
}

// MARK: - 温度图表视图
struct TemperatureChartView: View {
    let records: [TemperatureRecord]
    let timeRange: TimeRange
    @State private var selectedDataGroup: ChartDataGroup?
    
    // 默认初始化器（向后兼容）
    init(records: [TemperatureRecord]) {
        self.records = records
        self.timeRange = .day
    }
    
    // 新的初始化器，支持时间范围
    init(records: [TemperatureRecord], timeRange: TimeRange) {
        self.records = records
        self.timeRange = timeRange
    }
    
    private var chartDataGroups: [ChartDataGroup] {
        groupRecordsByTimeRange(records, timeRange: timeRange)
    }
    
    private var valueRange: ClosedRange<Double> {
        // 固定Y轴范围，确保能显示所有状态
        return 0...10
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if chartDataGroups.isEmpty {
                emptyStateView
            } else {
                if #available(iOS 16.0, *) {
                    chartView
                } else {
                    fallbackChartView
                }
            }
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("暂无状态数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("开始使用应用后，设备状态变化将显示在这里")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - 图表视图
    @available(iOS 16.0, *)
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 选中数据组信息
            if let selectedGroup = selectedDataGroup {
                selectedGroupInfo(selectedGroup)
            }
            
            // 条形图
            Chart {
                // 先创建一个隐藏的数据系列来定义完整的X轴范围
                ForEach(getXAxisLabels(for: timeRange), id: \.self) { label in
                    BarMark(
                        x: .value("时间", label),
                        y: .value("数值", 0)
                    )
                    .opacity(0) // 完全透明，只用于定义X轴
                }
                
                // 实际的数据条形图
                ForEach(chartDataGroups) { dataGroup in
                    BarMark(
                        x: .value("时间", dataGroup.timeLabel),
                        y: .value("数值", dataGroup.averageValue)
                    )
                    .foregroundStyle(dataGroup.color)
                    .cornerRadius(4)
                    
                    // 选中状态的指示器
                    if let selected = selectedDataGroup, selected.id == dataGroup.id {
                        RectangleMark(
                            x: .value("时间", dataGroup.timeLabel),
                            y: .value("数值", dataGroup.averageValue)
                        )
                        .foregroundStyle(Color("barChart").opacity(0.3))  // 使用自定义颜色的透明版本
                        .cornerRadius(4)
                    }
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...10)  // 固定Y轴范围
            .chartXAxis {
                AxisMarks(values: getXAxisLabels(for: timeRange)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisTick(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.gray.opacity(0.5))
                    AxisValueLabel {
                        if let stringValue = value.as(String.self) {
                            Text(stringValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 2.0, 4.0, 7.0, 9.0]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisTick(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.gray.opacity(0.5))
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(stateLabelForValue(doubleValue))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            handleChartTap(at: location, geometry: geometry, chartProxy: chartProxy)
                        }
                }
            }
        }
    }
    
    // MARK: - 降级图表视图（iOS 16 以下）
    private var fallbackChartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("图表功能需要 iOS 16 或更高版本")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("简化状态记录")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let latest = chartDataGroups.last {
                            Text("最新: \(latest.stateDescription)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                )
        }
    }
    
    // MARK: - 选中组信息
    private func selectedGroupInfo(_ group: ChartDataGroup) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(group.color)
                    .frame(width: 12, height: 12)
                
                Text("\(group.timeLabel) - \(group.stateDescription)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("清除选择") {
                    selectedDataGroup = nil
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Text("记录数量: \(group.records.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - 处理图表点击
    @available(iOS 16.0, *)
    private func handleChartTap(at location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        let plotAreaFrame = chartProxy.plotAreaFrame
        let origin = geometry.frame(in: .local).origin
        let relativeXPosition = location.x - origin.x
        
        if let timeLabel = chartProxy.value(atX: relativeXPosition, as: String.self) {
            // 找到对应的数据组
            if let matchingGroup = chartDataGroups.first(where: { $0.timeLabel == timeLabel }) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDataGroup = matchingGroup
                }
                
                // 触觉反馈
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    // MARK: - 获取X轴标签
    private func getXAxisLabels(for timeRange: TimeRange) -> [String] {
        switch timeRange {
        case .day:
            return ["0时", "6时", "12时", "18时"]
        case .week:
            return ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        case .month:
            return ["第1周", "第2周", "第3周", "第4周"]
        case .sixMonths:
            return ["1月", "2月", "3月", "4月", "5月", "6月"]
        case .year:
            return ["Q1", "Q2", "Q3", "Q4"]
        }
    }
    
    // MARK: - 状态标签
    private func stateLabelForValue(_ value: Double) -> String {
        switch value {
        case 0: return ""  // 不显示0的标签
        case 2.0: return "正常"
        case 4.0: return "轻微"
        case 7.0: return "中度"
        case 9.0: return "严重"
        default: return ""
        }
    }
}

// MARK: - 数据分组函数
private func groupRecordsByTimeRange(_ records: [TemperatureRecord], timeRange: TimeRange) -> [ChartDataGroup] {
    let calendar = Calendar.current
    let now = Date()
    
    switch timeRange {
    case .day:
        return groupRecordsByHour(records, calendar: calendar, currentDate: now)
    case .week:
        return groupRecordsByWeekday(records, calendar: calendar, currentDate: now)
    case .month:
        return groupRecordsByWeek(records, calendar: calendar, currentDate: now)
    case .sixMonths:
        return groupRecordsByMonth(records, calendar: calendar, currentDate: now)
    case .year:
        return groupRecordsByQuarter(records, calendar: calendar, currentDate: now)
    }
}

// MARK: - 按小时分组（日视图）
private func groupRecordsByHour(_ records: [TemperatureRecord], calendar: Calendar, currentDate: Date) -> [ChartDataGroup] {
    let timeSlots = [(0, "0时"), (6, "6时"), (12, "12时"), (18, "18时")]
    var groups: [ChartDataGroup] = []
    
    for (index, (hour, label)) in timeSlots.enumerated() {
        let startHour = hour
        let endHour = index < timeSlots.count - 1 ? timeSlots[index + 1].0 : 24
        
        let filteredRecords = records.filter { record in
            let recordHour = calendar.component(.hour, from: record.timestamp)
            return recordHour >= startHour && recordHour < endHour
        }
        
        if !filteredRecords.isEmpty {
            let averageValue = calculateAverageValue(filteredRecords)
            let mostCommonState = findMostCommonState(filteredRecords)
            
            groups.append(ChartDataGroup(
                timeLabel: label,
                categoryIndex: index,
                averageValue: averageValue,
                records: filteredRecords,
                mostCommonState: mostCommonState
            ))
        }
        // 没有数据时不添加任何组，这样不会显示条形图
    }
    
    return groups
}

// MARK: - 按星期分组（周视图）
private func groupRecordsByWeekday(_ records: [TemperatureRecord], calendar: Calendar, currentDate: Date) -> [ChartDataGroup] {
    let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    var groups: [ChartDataGroup] = []
    
    for (index, dayLabel) in weekdays.enumerated() {
        let weekday = (index + 2) % 7 + 1 // 转换为Calendar的weekday格式
        
        let filteredRecords = records.filter { record in
            calendar.component(.weekday, from: record.timestamp) == weekday
        }
        
        if !filteredRecords.isEmpty {
            let averageValue = calculateAverageValue(filteredRecords)
            let mostCommonState = findMostCommonState(filteredRecords)
            
            groups.append(ChartDataGroup(
                timeLabel: dayLabel,
                categoryIndex: index,
                averageValue: averageValue,
                records: filteredRecords,
                mostCommonState: mostCommonState
            ))
        }
        // 没有数据时不添加组
    }
    
    return groups
}

// MARK: - 按周分组（月视图）
private func groupRecordsByWeek(_ records: [TemperatureRecord], calendar: Calendar, currentDate: Date) -> [ChartDataGroup] {
    let weekLabels = ["第1周", "第2周", "第3周", "第4周"]
    var groups: [ChartDataGroup] = []
    
    for (index, weekLabel) in weekLabels.enumerated() {
        let weekOfMonth = index + 1
        
        let filteredRecords = records.filter { record in
            calendar.component(.weekOfMonth, from: record.timestamp) == weekOfMonth
        }
        
        if !filteredRecords.isEmpty {
            let averageValue = calculateAverageValue(filteredRecords)
            let mostCommonState = findMostCommonState(filteredRecords)
            
            groups.append(ChartDataGroup(
                timeLabel: weekLabel,
                categoryIndex: index,
                averageValue: averageValue,
                records: filteredRecords,
                mostCommonState: mostCommonState
            ))
        }
        // 没有数据时不添加组
    }
    
    return groups
}

// MARK: - 按月分组（6个月视图）
private func groupRecordsByMonth(_ records: [TemperatureRecord], calendar: Calendar, currentDate: Date) -> [ChartDataGroup] {
    let monthLabels = ["1月", "2月", "3月", "4月", "5月", "6月"]
    var groups: [ChartDataGroup] = []
    
    for (index, monthLabel) in monthLabels.enumerated() {
        let month = index + 1
        
        let filteredRecords = records.filter { record in
            calendar.component(.month, from: record.timestamp) == month
        }
        
        if !filteredRecords.isEmpty {
            let averageValue = calculateAverageValue(filteredRecords)
            let mostCommonState = findMostCommonState(filteredRecords)
            
            groups.append(ChartDataGroup(
                timeLabel: monthLabel,
                categoryIndex: index,
                averageValue: averageValue,
                records: filteredRecords,
                mostCommonState: mostCommonState
            ))
        }
        // 没有数据时不添加组
    }
    
    return groups
}

// MARK: - 按季度分组（年视图）
private func groupRecordsByQuarter(_ records: [TemperatureRecord], calendar: Calendar, currentDate: Date) -> [ChartDataGroup] {
    let quarterLabels = ["Q1", "Q2", "Q3", "Q4"]
    var groups: [ChartDataGroup] = []
    
    for (index, quarterLabel) in quarterLabels.enumerated() {
        let startMonth = index * 3 + 1
        let endMonth = startMonth + 2
        
        let filteredRecords = records.filter { record in
            let month = calendar.component(.month, from: record.timestamp)
            return month >= startMonth && month <= endMonth
        }
        
        if !filteredRecords.isEmpty {
            let averageValue = calculateAverageValue(filteredRecords)
            let mostCommonState = findMostCommonState(filteredRecords)
            
            groups.append(ChartDataGroup(
                timeLabel: quarterLabel,
                categoryIndex: index,
                averageValue: averageValue,
                records: filteredRecords,
                mostCommonState: mostCommonState
            ))
        }
        // 没有数据时不添加组
    }
    
    return groups
}

// MARK: - 辅助函数
private func calculateAverageValue(_ records: [TemperatureRecord]) -> Double {
    guard !records.isEmpty else { return 0 }
    let totalValue = records.reduce(0.0) { $0 + $1.internalValue }
    return totalValue / Double(records.count)
}

private func findMostCommonState(_ records: [TemperatureRecord]) -> ThermalState {
    guard !records.isEmpty else { return .normal }
    
    let stateCounts = records.reduce(into: [ThermalState: Int]()) { counts, record in
        counts[record.thermalState, default: 0] += 1
    }
    
    return stateCounts.max(by: { $0.value < $1.value })?.key ?? .normal
}

// MARK: - Preview
#Preview {
    let sampleRecords = [
        TemperatureRecord(timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!, thermalState: .normal),
        TemperatureRecord(timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!, thermalState: .fair),
        TemperatureRecord(timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, thermalState: .serious),
        TemperatureRecord(timestamp: Date(), thermalState: .normal)
    ]
    
    VStack(spacing: 20) {
        Text("日视图")
            .font(.headline)
        TemperatureChartView(records: sampleRecords, timeRange: .day)
        
        Text("周视图")
            .font(.headline)
        TemperatureChartView(records: sampleRecords, timeRange: .week)
    }
    .padding()
}
