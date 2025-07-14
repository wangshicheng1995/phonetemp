//
//  ContentView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/12.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var thermalManager = ThermalStateManager()
    @State private var animationProgress: CGFloat = 0
    @State private var glowIntensity: Double = 0.5
    
    // 用于开发阶段预览的自定义热状态
    private let customThermalState: ThermalState?
    
    // 计算当前应该显示的热状态
    private var currentDisplayState: ThermalState {
        return customThermalState ?? thermalManager.currentThermalState
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
        ZStack {
            // 深色背景
            Color(red: 0.05, green: 0.08, blue: 0.08)
                .ignoresSafeArea()
            
            // 主要的发光效果
            ZStack {
                let colorScheme = currentDisplayState.colorScheme
                
                // 最外层模糊光晕
                RoundedRectangle(cornerRadius: 150)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme.outerGlow),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 280, height: 480)
                    .blur(radius: 60)
                    .opacity(glowIntensity * 0.8)
                
                // 中层光晕
                RoundedRectangle(cornerRadius: 140)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme.middleGlow),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 260, height: 460)
                    .blur(radius: 40)
                    .opacity(glowIntensity)
                
                // 内层边框光晕
                RoundedRectangle(cornerRadius: 130)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: colorScheme.innerStroke[0], location: 0.0),
                                .init(color: colorScheme.innerStroke[1], location: 0.3),
                                .init(color: colorScheme.innerStroke[2], location: 0.7),
                                .init(color: colorScheme.innerStroke[3], location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 20
                    )
                    .frame(width: 240, height: 440)
                    .blur(radius: 15)
                    .opacity(glowIntensity * 1.2)
                
                // 核心发光边框
                RoundedRectangle(cornerRadius: 125)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme.coreStroke),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 220, height: 420)
                    .blur(radius: 3)
                    .opacity(glowIntensity * 1.5)
                
                // 最内层清晰边框
                RoundedRectangle(cornerRadius: 120)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme.coreStroke[0].opacity(0.9),
                                colorScheme.coreStroke[1].opacity(0.7)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 210, height: 410)
                    .opacity(glowIntensity * 1.8)
                
                // 内部填充 - 很淡的渐变
                RoundedRectangle(cornerRadius: 120)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme.innerFill),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 210, height: 410)
                
                // 热状态文本显示
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text(currentDisplayState.rawValue)
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .bold))
                        .shadow(color: colorScheme.coreStroke[0], radius: 10)
                    
                    Text("当前设备温度")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                }
            }
            .onAppear {
                // 呼吸动画
                withAnimation(
                    Animation.easeInOut(duration: 3.5)
                        .repeatForever(autoreverses: true)
                ) {
                    glowIntensity = 1.0
                }
            }
            .animation(.easeInOut(duration: 1.5), value: currentDisplayState)
            
            // UI 覆盖层
            VStack {
                // 顶部工具栏
                HStack {
                    // 左侧占位（保持平衡）
                    Spacer()
                        .frame(width: 22) // 与按钮图标宽度相同
                    
                    // App 名称居中
                    HStack(spacing: 8) {
                        Text("手机温度")
                            .foregroundColor(.white.opacity(0.9))
                            .font(.system(size: 17, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 更多选项按钮
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 22))
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 55)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
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
