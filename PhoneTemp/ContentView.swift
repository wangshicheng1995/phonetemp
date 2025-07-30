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
    
    @State private var showCoolingTips = false
    @State private var showTemperatureOverview = false
    @State private var showPaywall = false
    @State private var showPurchaseTest = false
    @State private var showOneTapCooling = false
    @State private var showHint = true // 控制小箭头显示
    @Environment(\.scenePhase) private var scenePhase
    
    // 用于开发阶段预览的自定义热状态
    private let customThermalState: ThermalState?
    private let isPreviewMode: Bool
    
    // 获取当前真实热状态
    private var currentThermalState: ThermalState {
        return customThermalState ?? thermalManager.currentThermalState
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
                // 主要海浪视图（全屏）
                WaveAnimation(realThermalState: currentThermalState)
                    .ignoresSafeArea(.all)
                
                // 顶部工具栏
                VStack {
                    topToolbar
                    Spacer()
                }
                
                // 底部内容
                VStack {
                    Spacer()
                    bottomContent
                }
                
                // 浮动操作按钮
                FloatingActionButton(
                    thermalState: currentThermalState,
                    showCoolingTips: $showCoolingTips,
                    showTemperatureOverview: $showTemperatureOverview,
                    showOneTapCooling: $showOneTapCooling
                )
                
                // 一键降温全屏覆盖
                if showOneTapCooling {
                    OneTapCoolingView(
                        isPresented: $showOneTapCooling,
                        thermalState: currentThermalState
                    )
                    .zIndex(999)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCoolingTips) {
            CoolingTipsSheet(thermalState: currentThermalState)
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
                print("App entering background")
            case .active:
                print("App becoming active")
                temperatureRecorder.refresh()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
        .onAppear {
            if !isPreviewMode {
                temperatureRecorder.refresh()
            }
            
            // 首次打开时显示箭头提示3秒后淡出
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 1.0)) {
                    showHint = false
                }
            }
        }
        .onDisappear {
            if !isPreviewMode {
                temperatureRecorder.invalidate()
            }
        }
        .onOpenURL { url in
            print("App opened via URL: \(url)")
            if url.scheme == "phoneTemp" {
                print("Opened from Live Activity")
            }
        }
    }
    
    // MARK: - 顶部工具栏
    private var topToolbar: some View {
        ZStack {
            // App 名称和图标
            HStack(spacing: 8) {
                Image("temp_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("手机热度")
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
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 20)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 底部内容
    private var bottomContent: some View {
        VStack(spacing: 16) {
            // 拖动提示
            if showHint {
                dragHintView
            }
            
            // 降温按钮（仅在发热状态显示）
            if currentThermalState != .normal {
                coolingButton
            }
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - 拖动提示
    private var dragHintView: some View {
        VStack(spacing: 8) {
            
            HStack(spacing: 8) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("上下拖动体验不同热度")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .transition(.opacity.animation(.easeOut)) // 添加淡出过渡动画
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 降温按钮
    private var coolingButton: some View {
        Button(action: {
            showCoolingTipsWithFeedback()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .medium))
                
                Text("查看降温建议")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 震动反馈方法
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - 降温提示触发方法
    private func showCoolingTipsWithFeedback() {
        triggerHapticFeedback()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showCoolingTips = true
        }
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
