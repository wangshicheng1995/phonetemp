//
//  LiveActivityTestView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/15.
//


//
//  LiveActivityTestView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import SwiftUI
import ActivityKit

// MARK: - Live Activity 测试控制台
struct LiveActivityTestView: View {
    @StateObject private var thermalManager = ThermalStateManager()
    @State private var selectedState: ThermalState = .normal
    @State private var testResults: [TestResult] = []
    @State private var isRunningTest = false
    @State private var currentActivityStatus = "未知"
    @State private var showingClearConfirmation = false
    
    // 测试结果数据模型
    struct TestResult: Identifiable, Equatable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let type: ResultType
        
        enum ResultType {
            case info, success, warning, error
            
            var color: Color {
                switch self {
                case .info: return .blue
                case .success: return .green
                case .warning: return .orange
                case .error: return .red
                }
            }
            
            var icon: String {
                switch self {
                case .info: return "info.circle"
                case .success: return "checkmark.circle"
                case .warning: return "exclamationmark.triangle"
                case .error: return "xmark.circle"
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题区域
                    headerSection
                    
                    // 系统状态区域
                    systemStatusSection
                    
                    // 测试控制区域
                    testControlSection
                    
                    // 快速测试按钮
                    quickTestSection
                    
                    // 高级测试区域
                    advancedTestSection
                    
                    // 测试结果区域
                    testResultsSection
                }
                .padding()
            }
            .navigationTitle("Live Activity 测试")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                updateActivityStatus()
                addTestResult("测试控制台已启动", type: .info)
            }
            .confirmationDialog("确认清除", isPresented: $showingClearConfirmation) {
                Button("清除所有日志", role: .destructive) {
                    clearResults()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("是否要清除所有测试日志？")
            }
        }
    }
    
    // MARK: - 标题区域
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Live Activity 测试控制台")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("测试和调试手机温度的灵动岛功能")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - 系统状态区域
    private var systemStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("系统状态", systemImage: "gearshape.2")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                StatusRow(
                    title: "Live Activity 权限",
                    status: thermalManager.getActivityManager()?.checkActivityPermission() == true ? "已启用" : "未启用",
                    isPositive: thermalManager.getActivityManager()?.checkActivityPermission() == true
                )
                
                StatusRow(
                    title: "当前活动状态",
                    status: currentActivityStatus,
                    isPositive: currentActivityStatus == "运行中"
                )
                
                StatusRow(
                    title: "当前热状态",
                    status: thermalManager.currentThermalState.rawValue,
                    isPositive: thermalManager.currentThermalState == .normal
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 测试控制区域
    private var testControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("测试控制", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // 温度状态选择器
                VStack(alignment: .leading, spacing: 8) {
                    Text("选择测试温度状态")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("温度状态", selection: $selectedState) {
                        ForEach(ThermalState.allCases, id: \.self) { state in
                            HStack {
                                Circle()
                                    .fill(colorForState(state))
                                    .frame(width: 12, height: 12)
                                Text(state.rawValue)
                            }
                            .tag(state)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 基础操作按钮
                HStack(spacing: 12) {
                    Button(action: startLiveActivity) {
                        Label("启动", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRunningTest)
                    
                    Button(action: updateLiveActivity) {
                        Label("更新", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRunningTest)
                    
                    Button(action: stopLiveActivity) {
                        Label("停止", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(isRunningTest)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 快速测试区域
    private var quickTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("快速测试", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundColor(.orange)
            
            HStack(spacing: 12) {
                Button(action: runQuickTest) {
                    Label("状态循环测试", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(isRunningTest)
                
                Button(action: runLifecycleTest) {
                    Label("生命周期测试", systemImage: "arrow.up.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isRunningTest)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 高级测试区域
    private var advancedTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("高级测试", systemImage: "cpu")
                .font(.headline)
                .foregroundColor(.purple)
            
            VStack(spacing: 8) {
                Button(action: runStressTest) {
                    HStack {
                        Image(systemName: "speedometer")
                        Text("压力测试 (30秒)")
                        Spacer()
                        if isRunningTest {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                .disabled(isRunningTest)
                
                Button(action: testAppLifecycle) {
                    Label("应用生命周期测试", systemImage: "app.badge")
                }
                .buttonStyle(.bordered)
                .disabled(isRunningTest)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 测试结果区域
    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("测试日志", systemImage: "doc.text")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("清除") {
                    showingClearConfirmation = true
                }
                .font(.caption)
                .foregroundColor(.red)
                .disabled(testResults.isEmpty)
            }
            
            if testResults.isEmpty {
                Text("暂无测试日志")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(testResults.suffix(20)) { result in
                        TestResultRow(result: result)
                    }
                }
                .frame(maxHeight: 300)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 测试方法
    
    private func startLiveActivity() {
        addTestResult("🚀 启动 Live Activity - 状态: \(selectedState.rawValue)", type: .info)
        
        Task { @MainActor in
            await thermalManager.getActivityManager()?.startActivity(with: selectedState)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                updateActivityStatus()
                let isActive = thermalManager.getActivityManager()?.isActivityActive ?? false
                addTestResult(
                    isActive ? "✅ Live Activity 启动成功" : "❌ Live Activity 启动失败",
                    type: isActive ? .success : .error
                )
            }
        }
    }
    
    private func updateLiveActivity() {
        addTestResult("🔄 更新 Live Activity - 新状态: \(selectedState.rawValue)", type: .info)
        
        Task { @MainActor in
            thermalManager.getActivityManager()?.updateActivity(with: selectedState)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                addTestResult("✅ Live Activity 已更新", type: .success)
                updateActivityStatus()
            }
        }
    }
    
    private func stopLiveActivity() {
        addTestResult("🛑 停止 Live Activity", type: .info)
        
        Task { @MainActor in
            await thermalManager.getActivityManager()?.stopActivity()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                updateActivityStatus()
                addTestResult("✅ Live Activity 已停止", type: .success)
            }
        }
    }
    
    private func runQuickTest() {
        isRunningTest = true
        addTestResult("🧪 开始快速测试...", type: .info)
        
        Task { @MainActor in
            let testStates: [ThermalState] = [.normal, .fair, .serious, .critical]
            
            for (index, state) in testStates.enumerated() {
                addTestResult("📊 测试状态 \(index + 1)/\(testStates.count): \(state.rawValue)", type: .info)
                
                if index == 0 {
                    await thermalManager.getActivityManager()?.startActivity(with: state)
                } else {
                    thermalManager.getActivityManager()?.updateActivity(with: state)
                }
                
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
            }
            
            updateActivityStatus()
            addTestResult("✅ 快速测试完成", type: .success)
            isRunningTest = false
        }
    }
    
    private func runLifecycleTest() {
        isRunningTest = true
        addTestResult("🔄 开始生命周期测试...", type: .info)
        
        Task { @MainActor in
            // 启动
            await thermalManager.getActivityManager()?.startActivity(with: .serious)
            addTestResult("1️⃣ Live Activity 已启动", type: .info)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // 模拟后台
            thermalManager.getActivityManager()?.handleAppBackgrounding(with: .critical)
            addTestResult("2️⃣ 模拟应用进入后台", type: .info)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // 模拟前台
            thermalManager.getActivityManager()?.handleAppForegrounding()
            addTestResult("3️⃣ 模拟应用回到前台", type: .info)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // 停止
            await thermalManager.getActivityManager()?.stopActivity()
            addTestResult("4️⃣ Live Activity 已停止", type: .info)
            
            updateActivityStatus()
            addTestResult("✅ 生命周期测试完成", type: .success)
            isRunningTest = false
        }
    }
    
    private func runStressTest() {
        isRunningTest = true
        addTestResult("💪 开始压力测试 (30秒)...", type: .warning)
        
        Task { @MainActor in
            let startTime = Date()
            var updateCount = 0
            
            // 启动 Live Activity
            await thermalManager.getActivityManager()?.startActivity(with: .normal)
            
            while Date().timeIntervalSince(startTime) < 30 {
                let randomState = ThermalState.allCases.randomElement() ?? .normal
                thermalManager.getActivityManager()?.updateActivity(with: randomState)
                updateCount += 1
                
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            }
            
            await thermalManager.getActivityManager()?.stopActivity()
            
            addTestResult("✅ 压力测试完成 - 更新次数: \(updateCount)", type: .success)
            updateActivityStatus()
            isRunningTest = false
        }
    }
    
    private func testAppLifecycle() {
        addTestResult("📱 测试应用生命周期处理", type: .info)
        
        Task { @MainActor in
            thermalManager.getActivityManager()?.handleAppBackgrounding(with: selectedState)
            addTestResult("🌙 模拟应用进入后台", type: .info)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.thermalManager.getActivityManager()?.handleAppForegrounding()
                self.addTestResult("☀️ 模拟应用回到前台", type: .info)
                self.updateActivityStatus()
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func updateActivityStatus() {
        let isActive = thermalManager.getActivityManager()?.isActivityActive ?? false
        currentActivityStatus = isActive ? "运行中" : "已停止"
    }
    
    private func addTestResult(_ message: String, type: TestResult.ResultType) {
        let result = TestResult(timestamp: Date(), message: message, type: type)
        testResults.append(result)
        
        // 保持最新的50条记录
        if testResults.count > 50 {
            testResults.removeFirst(testResults.count - 50)
        }
    }
    
    private func clearResults() {
        testResults.removeAll()
        addTestResult("📝 测试日志已清除", type: .info)
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

// MARK: - 辅助视图组件

struct StatusRow: View {
    let title: String
    let status: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(isPositive ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct TestResultRow: View {
    let result: LiveActivityTestView.TestResult
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: result.type.icon)
                .foregroundColor(result.type.color)
                .frame(width: 16)
            
            Text(result.message)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Text(formatTime(result.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    LiveActivityTestView()
}