//
//  ContentView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/12.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var thermalManager = ThermalStateManager()
    @StateObject private var temperatureRecorder = TemperatureRecorder()
    @StateObject private var storeKitManager = UniversalStoreKitManager.shared
    
    @State private var currentPageIndex = 0
    @State private var showCoolingTips = false
    @State private var showTemperatureOverview = false
    @State private var showPaywall = false
    @State private var showPurchaseTest = false
    @Environment(\.scenePhase) private var scenePhase
    
    // 用于开发阶段预览的自定义热状态
    private let customThermalState: ThermalState?
    private let isPreviewMode: Bool
    
    // 所有热状态的顺序
    private let allThermalStates: [ThermalState] = [.normal, .fair, .serious, .critical]
    
    // 获取真实热状态对应的索引
    private var realThermalStateIndex: Int {
        let targetState = customThermalState ?? thermalManager.currentThermalState
        return allThermalStates.firstIndex(of: targetState) ?? 0
    }
    
    // 获取当前显示的热状态
    private var currentDisplayState: ThermalState {
        guard currentPageIndex < allThermalStates.count else { return .normal }
        return allThermalStates[currentPageIndex]
    }
    
    // 判断当前显示的是否为真实状态
    private var isCurrentRealState: Bool {
        return currentPageIndex == realThermalStateIndex
    }
    
    // 默认初始化器（用于正常运行）
    init() {
        self.customThermalState = nil
        self.isPreviewMode = false
    }
    
    // 自定义初始化器（用于预览和测试）
    init(previewThermalState: ThermalState) {
        self.customThermalState = previewThermalState
        self.isPreviewMode = true
    }
    
    // Preview 专用初始化器
    init(isPreview: Bool) {
        self.customThermalState = nil
        self.isPreviewMode = isPreview
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
                                VStack(alignment: .center) {
                                    // 热状态显示
                                    Button(action: {
                                        triggerHapticFeedback()
                                        showTemperatureOverview = true
                                    }) {
                                        ThermalDisplayView(
                                            thermalState: allThermalStates[index],
                                            isCurrentState: index == realThermalStateIndex
                                        )
                                        .padding(.leading, 15)
                                    }
                                    
                                    // 底部内容和按钮
                                    VStack {
                                        bottomContent(for: allThermalStates[index], isRealState: index == realThermalStateIndex)
                                    }
                                    .padding(.bottom, 10)
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
                    .onDisappear {
                        // 视图消失时清理资源
                        if !isPreviewMode {
                            temperatureRecorder.invalidate()
                        }
                    }
                    .onChange(of: thermalManager.currentThermalState) { oldState, newState in
                        // 只有在非预览模式下才响应真实热状态变化
                        guard customThermalState == nil && !isPreviewMode else { return }
                        
                        // 记录温度变化
                        temperatureRecorder.recordTemperatureChange(newState: newState)
                        
                        // 当真实热状态改变时，如果当前显示的是之前的真实状态，则跳转到新的真实状态
                        if isCurrentRealState {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentPageIndex = realThermalStateIndex
                            }
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
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(OnboardingManager())
        }
        .sheet(isPresented: $showPurchaseTest) {
            PurchaseTestView()
        }
        .modifier(FullScreenCoverModifier(isPresented: $showTemperatureOverview) {
            TemperatureOverviewView(recorder: temperatureRecorder)
        })
        .onChange(of: scenePhase) { _, newPhase in
            guard !isPreviewMode else { return }
            
            switch newPhase {
            case .background:
                // 应用进入后台时处理 Live Activity
                print("App entering background")
            case .active:
                // 应用变为活跃状态时处理 Live Activity
                print("App becoming active")
                // 刷新温度记录
                temperatureRecorder.refresh()
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
    
    // MARK: - 顶部工具栏
    private var topToolbar: some View {
        ZStack {
            // App 名称和图标
            HStack(spacing: 8) {
                // App 图标
                Image("temp_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white.opacity(0.9))
                
                // App 名称
                Text("手机温度")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.title2)
            }
            
            // 右侧按钮组
            HStack {
                Spacer()
                
                // 升级按钮（仅在未购买时显示）
                if !isPreviewMode && !storeKitManager.isPremiumUnlocked {
                    Button(action: {
                        triggerHapticFeedback()
                        showPaywall = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text("升级")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 调试测试按钮
                #if DEBUG
                Button(action: {
                    triggerHapticFeedback()
                    showPurchaseTest = true
                }) {
                    Text("🧪")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .padding(.leading, 8)
                }
                #endif
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }
    
    // MARK: - 回顾按钮
    private var overviewButton: some View {
        VStack() {
            Button(action: {
                triggerHapticFeedback()
                showTemperatureOverview = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("回顾")
                .foregroundColor(.white.opacity(0.8))
                .font(.system(size: 12, weight: .medium))
        }
    }
    
    // 背景材质的降级处理
    private var backgroundMaterial: some ShapeStyle {
        if #available(iOS 15.0, *) {
            return AnyShapeStyle(.ultraThinMaterial)
        } else {
            return AnyShapeStyle(Color.black.opacity(0.3))
        }
    }
    
    // MARK: - 震动反馈方法
    private func triggerHapticFeedback() {
        // 统一使用轻微震动
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - 降温提示触发方法
    private func showCoolingTipsWithFeedback() {
        // 先触发震动反馈
        triggerHapticFeedback()
        
        // 稍微延迟显示界面，让震动效果更明显
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showCoolingTips = true
        }
    }
    
    // MARK: - 底部内容
    private func bottomContent(for thermalState: ThermalState, isRealState: Bool) -> some View {
        VStack(spacing: 16) {
            if thermalState == .normal {
                // 正常状态时显示文字
                if isRealState {
                    Text("😋看起来一切正常")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 13, weight: .medium))
                        .multilineTextAlignment(.center)
                        .padding(.leading, 15)
                }
            } else if thermalState != .normal {
                // 发热状态显示可点击的文本 - 添加震动反馈
                VStack(spacing: 12) {
                    Button(action: {
                        showCoolingTipsWithFeedback()
                    }) {
                        ZStack {
                            // 圆形背景框
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 5)
                                .frame(width: 60, height: 60)
                            
                            // 箭头图标
                            Image(systemName: "arrow.up")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 可点击的文本 - 震动反馈
                    Button(action: {
                        showCoolingTipsWithFeedback()
                    }) {
                        Text("轻点查看降温 Tips")
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.leading, 15)
            }
        }
        .padding(.bottom, -10)
    }
}

// MARK: - 兼容性修饰符
struct FullScreenCoverModifier<CoverContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> CoverContent
    
    func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            content
                .fullScreenCover(isPresented: $isPresented, content: self.content)
        } else {
            content
                .sheet(isPresented: $isPresented, content: self.content)
        }
    }
}

// MARK: - Preview - 使用安全的初始化方式
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
    ContentView(isPreview: true)
}
