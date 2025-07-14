//
//  ContentView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/12.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var thermalManager = ThermalStateManager()
    @State private var currentPageIndex = 0
    @State private var showCoolingTips = false
    @Environment(\.scenePhase) private var scenePhase
    
    // 用于开发阶段预览的自定义热状态
    private let customThermalState: ThermalState?
    
    // 所有热状态的顺序
    private let allThermalStates: [ThermalState] = [.normal, .fair, .serious, .critical]
    
    // 获取真实热状态对应的索引
    private var realThermalStateIndex: Int {
        let targetState = customThermalState ?? thermalManager.currentThermalState
        return allThermalStates.firstIndex(of: targetState) ?? 0
    }
    
    // 获取当前显示的热状态
    private var currentDisplayState: ThermalState {
        return allThermalStates[currentPageIndex]
    }
    
    // 判断当前显示的是否为真实状态
    private var isCurrentRealState: Bool {
        return currentPageIndex == realThermalStateIndex
    }
    
    // 默认初始化器（用于正常运行）
    init() {
        self.customThermalState = nil
    }
    
    // 自定义初始化器（用于预览和测试）
    init(previewThermalState: ThermalState) {
        self.customThermalState = previewThermalState
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 深色背景 - 扩展到整个屏幕包括顶部
                Color(red: 0.05, green: 0.08, blue: 0.08)
                    .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // 固定的顶部工具栏
                topToolbar
                
                // 可滑动的主要内容区域
                TabView(selection: $currentPageIndex) {
                    ForEach(0..<allThermalStates.count, id: \.self) { index in
                        ZStack {
                            // 热状态显示
                            ThermalDisplayView(
                                thermalState: allThermalStates[index],
                                isCurrentState: index == realThermalStateIndex
                            )
                            
                            // 底部内容区域
                            VStack {
                                Spacer()
                                bottomContent(for: allThermalStates[index], isRealState: index == realThermalStateIndex)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onAppear {
                    // 启动时跳转到真实热状态页面
                    currentPageIndex = realThermalStateIndex
                }
                .onChange(of: thermalManager.currentThermalState) { _, _ in
                    // 只有在非预览模式下才响应真实热状态变化
                    guard customThermalState == nil else { return }
                    
                    // 当真实热状态改变时，如果当前显示的是之前的真实状态，则跳转到新的真实状态
                    if isCurrentRealState {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentPageIndex = realThermalStateIndex
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCoolingTips) {
            CoolingTipsSheet(thermalState: currentDisplayState)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // 应用进入后台时处理 Live Activity
                print("App entering background")
            case .active:
                // 应用变为活跃状态时处理 Live Activity
                print("App becoming active")
            case .inactive:
                break
            @unknown default:
                break
            }
        }
        .onOpenURL { url in
            // 处理从 Live Activity 点击返回应用的 URL
            print("App opened via URL: \(url)")
            if url.scheme == "phoneTemp" {
                // 这里可以添加特定的处理逻辑，比如导航到特定页面
                print("Opened from Live Activity")
            }
        }
        }
    }
    
    // MARK: - 顶部工具栏
    private var topToolbar: some View {
        ZStack {
            // App 名称
            HStack(spacing: 8) {
                Text("手机温度")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.system(size: 23, weight: .medium))
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 35)
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }
    
    // MARK: - 底部内容
    private func bottomContent(for thermalState: ThermalState, isRealState: Bool) -> some View {
        VStack(spacing: 16) {
            if thermalState == .normal && isRealState {
                // 正常状态且为真实状态时显示文字
                Text("看起来一切正常😉")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.center)
            } else if thermalState != .normal {
                // 发热状态显示降温按钮
                VStack(spacing: 12) {
                    Button(action: {
                        showCoolingTips = true
                    }) {
                        Image(systemName: "wind")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("轻点查看降温 Tips")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14, weight: .medium))
                    
                    // 测试 Live Activity 按钮
                    Button(action: {
                        Task {
                            await thermalManager.getActivityManager()?.startActivity(with: thermalState)
                        }
                    }) {
                        Text("测试灵动岛")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 测试控制台按钮
                    NavigationLink(destination: LiveActivityTestView()) {
                        Text("测试控制台")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                // 正常状态的预览模式
                Text("这是预览模式")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 50)
    }
}

// MARK: - Preview
#Preview("正常状态") {
    ContentView(previewThermalState: .normal)
}

#Preview("轻微发热") {
    ContentView(previewThermalState: .fair)
}

#Preview("中度发热") {
    ContentView(previewThermalState: .serious)
}

#Preview("严重发热") {
    ContentView(previewThermalState: .critical)
}

#Preview("默认运行") {
    ContentView()
}
