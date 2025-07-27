//
//  FloatingActionButton.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/27.
//

import SwiftUI

// MARK: - 浮动操作按钮组件
struct FloatingActionButton: View {
    let thermalState: ThermalState
    @Binding var showCoolingTips: Bool
    @Binding var showTemperatureOverview: Bool
    @Binding var showOneTapCooling: Bool
    
    @State private var isExpanded = false
    
    // 检查是否为发热状态（用于一键降温功能启用判断）
    private var isHeatingState: Bool {
        thermalState != .normal
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                // 浮动按钮组 - 使用固定对齐方式
                VStack(alignment: .trailing, spacing: 0) {
                    // 展开的功能按钮
                    if isExpanded {
                        expandedButtons
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                    }
                    
                    // 主按钮 - 固定在右侧对齐
                    HStack {
                        Spacer()
                        mainButton
                    }
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - 主按钮
    private var mainButton: some View {
        Button(action: {
            toggleExpansion()
        }) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                if isExpanded {
                    // 展开状态：显示 X 图标
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                } else {
                    // 收起状态：显示 + 图标
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 展开的功能按钮
    private var expandedButtons: some View {
        VStack(alignment: .trailing, spacing: 16) {
            // 一键降温按钮（从上到下第一个）
            FloatingOptionButton(
                icon: "snowflake",
                label: "一键降温",
                color: .cyan,
                delay: 0.0,
                isEnabled: isHeatingState
            ) {
                triggerOneTapCooling()
            }
            
            // 降温提示按钮（从上到下第二个）
            FloatingOptionButton(
                icon: "lightbulb",
                label: "降温提示",
                color: .orange,
                delay: 0.1,
                isEnabled: isHeatingState
            ) {
                triggerCoolingTips()
            }
            
            // 温度回顾按钮（从上到下第三个，最靠近主按钮）
            FloatingOptionButton(
                icon: "chart.line.uptrend.xyaxis",
                label: "温度回顾",
                color: .blue,
                delay: 0.2,
                isEnabled: true
            ) {
                triggerTemperatureOverview()
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - 操作方法
    private func toggleExpansion() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded.toggle()
        }
    }
    
    private func triggerOneTapCooling() {
        closeWithAction {
            showOneTapCooling = true
        }
    }
    
    private func triggerTemperatureOverview() {
        closeWithAction {
            showTemperatureOverview = true
        }
    }
    
    private func triggerCoolingTips() {
        closeWithAction {
            showCoolingTips = true
        }
    }
    
    private func closeWithAction(_ action: @escaping () -> Void) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isExpanded = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            action()
        }
    }
}

// MARK: - 浮动选项按钮
struct FloatingOptionButton: View {
    let icon: String
    let label: String
    let color: Color
    let delay: Double
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            HStack(spacing: 12) {
                // 标签文本
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(isEnabled ? 0.7 : 0.4))
                    .cornerRadius(20)
                
                // 图标按钮
                ZStack {
                    Circle()
                        .fill(isEnabled ? color : color.opacity(0.3))
                        .frame(width: 48, height: 48)
                        .shadow(color: .black.opacity(isEnabled ? 0.2 : 0.1), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isEnabled ? .white : .white.opacity(0.5))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(scale)
        .opacity(opacity)
        .disabled(!isEnabled)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .onDisappear {
            scale = 0
            opacity = 0
        }
    }
}

// MARK: - Preview
#Preview("正常状态") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        FloatingActionButton(
            thermalState: .normal,
            showCoolingTips: .constant(false),
            showTemperatureOverview: .constant(false),
            showOneTapCooling: .constant(false)
        )
    }
}

#Preview("发热状态") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        FloatingActionButton(
            thermalState: .serious,
            showCoolingTips: .constant(false),
            showTemperatureOverview: .constant(false),
            showOneTapCooling: .constant(false)
        )
    }
}
