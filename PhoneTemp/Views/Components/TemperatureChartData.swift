//
//  TemperatureChartView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/22.
//

import SwiftUI
import Charts

// MARK: - 温度图表数据点
struct TemperatureChartData: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
    let state: ThermalState
    
    var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        return formatter.string(from: time)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    var color: Color {
        switch state {
        case .normal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - 温度图表视图
struct TemperatureChartView: View {
    let records: [TemperatureRecord]
    @State private var selectedDataPoint: TemperatureChartData?
    
    private var chartData: [TemperatureChartData] {
        records.map { record in
            TemperatureChartData(
                time: record.timestamp,
                value: record.temperatureValue,
                state: record.thermalState
            )
        }
    }
    
    private var valueRange: ClosedRange<Double> {
        guard !chartData.isEmpty else { return 0...6 }
        let minValue = chartData.map(\.value).min() ?? 0
        let maxValue = chartData.map(\.value).max() ?? 6
        return (minValue - 0.5)...(maxValue + 0.5)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if chartData.isEmpty {
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
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("暂无温度数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("开始使用应用后，温度变化将显示在这里")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 图表视图
    @available(iOS 16.0, *)
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 选中数据点信息
            if let selectedPoint = selectedDataPoint {
                selectedPointInfo(selectedPoint)
            }
            
            // 图表
            Chart(chartData) { dataPoint in
                // 线图
                LineMark(
                    x: .value("时间", dataPoint.time),
                    y: .value("温度", dataPoint.value)
                )
                .foregroundStyle(dataPoint.color)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                // 数据点
                PointMark(
                    x: .value("时间", dataPoint.time),
                    y: .value("温度", dataPoint.value)
                )
                .foregroundStyle(dataPoint.color)
                .symbolSize(40)
                
                // 选中状态的指示器
                if let selected = selectedDataPoint, selected.id == dataPoint.id {
                    RuleMark(x: .value("时间", dataPoint.time))
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }
            }
            .frame(height: 200)
            .chartYScale(domain: valueRange)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text("\(date, format: .dateTime.hour())时")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [1.0, 2.5, 4.0, 5.5]) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(temperatureLabelForValue(doubleValue))
                                .font(.caption)
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
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("简化温度记录")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let latest = chartData.last {
                            Text("最新: \(latest.state.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                )
        }
    }
    
    // MARK: - 选中点信息
    private func selectedPointInfo(_ point: TemperatureChartData) -> some View {
        HStack {
            Circle()
                .fill(point.color)
                .frame(width: 12, height: 12)
            
            Text("\(point.timeString) - \(point.state.rawValue)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("清除选择") {
                selectedDataPoint = nil
            }
            .font(.caption)
            .foregroundColor(.blue)
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
        
        if let date = chartProxy.value(atX: relativeXPosition, as: Date.self) {
            // 找到最接近的数据点
            if let closestPoint = findClosestDataPoint(to: date) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDataPoint = closestPoint
                }
                
                // 触觉反馈
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    // MARK: - 找到最接近的数据点
    private func findClosestDataPoint(to date: Date) -> TemperatureChartData? {
        chartData.min { abs($0.time.timeIntervalSince(date)) < abs($1.time.timeIntervalSince(date)) }
    }
    
    // MARK: - 温度标签
    private func temperatureLabelForValue(_ value: Double) -> String {
        switch value {
        case 1.0: return "正常"
        case 2.5: return "轻微"
        case 4.0: return "中度"
        case 5.5: return "严重"
        default: return ""
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleRecords = [
        TemperatureRecord(timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!, thermalState: .normal),
        TemperatureRecord(timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!, thermalState: .fair),
        TemperatureRecord(timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, thermalState: .serious),
        TemperatureRecord(timestamp: Date(), thermalState: .normal)
    ]
    
    TemperatureChartView(records: sampleRecords)
        .padding()
}
