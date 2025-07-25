//
//  PurchaseTestView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/25.
//

import SwiftUI

// MARK: - 购买功能测试界面
struct PurchaseTestView: View {
    @StateObject private var testManager = PurchaseTestManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingDetails = false
    @State private var selectedTest: PurchaseTestManager.TestResult?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部控制区域
                controlSection
                
                // 当前测试状态
                if testManager.isRunningTests {
                    currentTestSection
                }
                
                // 测试结果列表
                testResultsList
            }
            .navigationTitle("购买功能测试")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清除") {
                        testManager.clearResults()
                    }
                    .disabled(testManager.isRunningTests)
                }
            }
        }
        .sheet(item: $selectedTest) { test in
            TestDetailView(testResult: test)
        }
    }
    
    // MARK: - 控制区域
    private var controlSection: some View {
        VStack(spacing: 16) {
            // 运行测试按钮
            Button(action: {
                Task {
                    await testManager.runAllTests()
                }
            }) {
                HStack {
                    if testManager.isRunningTests {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("测试进行中...")
                    } else {
                        Image(systemName: "play.fill")
                        Text("运行所有测试")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(testManager.isRunningTests ? Color.orange : Color.blue)
                .cornerRadius(12)
            }
            .disabled(testManager.isRunningTests)
            
            // 快速测试按钮
            HStack(spacing: 12) {
                Button("试用测试") {
                    Task {
                        await testManager.testTrialFlow()
                    }
                }
                .buttonStyle(QuickTestButtonStyle())
                .disabled(testManager.isRunningTests)
                
                Button("购买测试") {
                    Task {
                        await testManager.testPurchaseFlow()
                    }
                }
                .buttonStyle(QuickTestButtonStyle())
                .disabled(testManager.isRunningTests)
                
                Button("恢复测试") {
                    Task {
                        await testManager.testRestoreFlow()
                    }
                }
                .buttonStyle(QuickTestButtonStyle())
                .disabled(testManager.isRunningTests)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - 当前测试状态
    private var currentTestSection: some View {
        VStack(spacing: 8) {
            Text("正在执行测试")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(testManager.currentTest)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - 测试结果列表
    private var testResultsList: some View {
        Group {
            if testManager.testResults.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(testManager.testResults) { result in
                            TestResultRowView(result: result) {
                                selectedTest = result
                                showingDetails = true
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.badge.xmark")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("还没有测试结果")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击上方按钮开始测试购买功能")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - 测试结果行
struct TestResultRowView: View {
    let result: PurchaseTestManager.TestResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 状态图标
                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(result.isSuccess ? .green : .red)
                
                // 测试信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.testName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(result.resultText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 时间戳
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(result.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(result.isSuccess ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - 快速测试按钮样式
struct QuickTestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 测试详情视图
struct TestDetailView: View {
    let testResult: PurchaseTestManager.TestResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // 状态头部
                HStack {
                    Image(systemName: testResult.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(testResult.isSuccess ? .green : .red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(testResult.testName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(formatFullTime(testResult.timestamp))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // 结果信息
                VStack(alignment: .leading, spacing: 12) {
                    Text("测试结果")
                        .font(.headline)
                    
                    Text(testResult.resultText)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // 详细信息
                VStack(alignment: .leading, spacing: 12) {
                    Text("详细信息")
                        .font(.headline)
                    
                    Text(testResult.details)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("测试详情")
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
    
    private func formatFullTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    PurchaseTestView()
}
