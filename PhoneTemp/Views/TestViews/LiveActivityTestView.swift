//
//  LiveActivityTestView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import SwiftUI
import ActivityKit

// MARK: - Live Activity 测试视图
struct LiveActivityTestView: View {
    @StateObject private var thermalManager = ThermalStateManager()
    @State private var selectedState: ThermalState = .normal
    @State private var testResults: [String] = []
    @State private var isRunningTest = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                Text("灵动岛测试控制台")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                // 权限状态
                permissionStatusView
                
                // 温度状态选择
                temperatureStateSelector
                
                // 测试按钮组
                testButtonsView
                
                // 自动测试按钮
                autoTestButton
                
                // 测试结果
                testResultsView
                
                Spacer()
            }
            .padding()
            .navigationTitle("Live Activity 测试")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - 权限状态视图
    private var permissionStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("权限状态")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(thermalManager.getActivityManager()?.checkActivityPermission() == true ? .green : .red)
                    .frame(width: 12, height: 12)
                
                Text(thermalManager.getActivityManager()?.checkActivityPermission() == true ? "Live Activity 已启用" : "Live Activity 未启用")
                    .font(.body)
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 温度状态选择器
    private var temperatureStateSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择温度状态")
                .font(.headline)
            
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
    }
    
    // MARK: - 测试按钮组
    private var testButtonsView: some View {
        VStack(spacing: 12) {
            Text("手动测试")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button("启动 Live Activity") {
                    startLiveActivity()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunningTest)
                
                Button("更新状态") {
                    updateLiveActivity()
                }
                .buttonStyle(.bordered)
                .disabled(isRunningTest)
            }
            
            HStack(spacing: 12) {
                Button("停止 Live Activity") {
                    stopLiveActivity()
                }
                .buttonStyle(.bordered)
                .disabled(isRunningTest)
                
                Button("清除日志") {
                    clearResults()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - 自动测试按钮
    private var autoTestButton: some View {
        VStack(spacing: 8) {
            Text("自动测试")
                .font(.headline)
            
            Button(isRunningTest ? "测试进行中..." : "运行完整测试") {
                runFullTest()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunningTest)
        }
    }
    
    // MARK: - 测试结果视图
    private var testResultsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("测试结果")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(testResults, id: \.self) { result in
                        Text(result)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 150)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 测试方法
    private func startLiveActivity() {
        addTestResult("🚀 启动 Live Activity - 状态: \(selectedState.rawValue)")
        
        Task { @MainActor in
            thermalManager.getActivityManager()?.startActivity(with: selectedState)
            
            // 等待一下然后检查状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let isActive = thermalManager.getActivityManager()?.isActivityActive ?? false
                addTestResult("✅ Live Activity 状态: \(isActive ? "活跃" : "非活跃")")
            }
        }
    }
    
    private func updateLiveActivity() {
        addTestResult("🔄 更新 Live Activity - 新状态: \(selectedState.rawValue)")
        
        Task { @MainActor in
            thermalManager.getActivityManager()?.updateActivity(with: selectedState)
            addTestResult("✅ Live Activity 已更新")
        }
    }
    
    private func stopLiveActivity() {
        addTestResult("🛑 停止 Live Activity")
        
        Task { @MainActor in
            await thermalManager.getActivityManager()?.stopActivity()
            addTestResult("✅ Live Activity 已停止")
        }
    }
    
    private func runFullTest() {
        isRunningTest = true
        addTestResult("🧪 开始完整测试...")
        
        Task { @MainActor in
            // 测试序列
            let testStates: [ThermalState] = [.normal, .fair, .serious, .critical]
            
            for (index, state) in testStates.enumerated() {
                addTestResult("📊 测试状态 \(index + 1)/\(testStates.count): \(state.rawValue)")
                
                // 启动或更新 Live Activity
                if index == 0 {
                    thermalManager.getActivityManager()?.startActivity(with: state)
                } else {
                    thermalManager.getActivityManager()?.updateActivity(with: state)
                }
                
                // 等待2秒观察效果
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
            
            addTestResult("🎯 测试应用生命周期...")
            
            // 测试应用生命周期
            thermalManager.getActivityManager()?.handleAppBackgrounding(with: .serious)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            thermalManager.getActivityManager()?.handleAppForegrounding()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            addTestResult("✅ 完整测试完成")
            isRunningTest = false
        }
    }
    
    private func clearResults() {
        testResults.removeAll()
    }
    
    private func addTestResult(_ result: String) {
        let timestamp = DateFormatter().string(from: Date())
        testResults.append("[\(timestamp)] \(result)")
    }
    
    // MARK: - 辅助方法
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
}

// MARK: - 预览
#Preview {
    LiveActivityTestView()
}