//
//  ThermalWaveView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/29.
//


//
//  ThermalWaveView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/29.
//

import SwiftUI
import Foundation

// MARK: - 热度海浪显示视图
struct ThermalWaveView: View {
    let thermalState: ThermalState
    let isCurrentState: Bool
    
    @State private var waveOffset = Angle(degrees: 0)
    @State private var secondWaveOffset = Angle(degrees: 180)
    @State private var currentPercent: Double = 0
    @State private var glowIntensity: Double = 0.5
    
    private var config: ThermalWaveConfiguration {
        ThermalWaveConfiguration.configuration(for: thermalState)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景渐变
                backgroundGradient(geometry: geometry)
                
                // 多层海浪效果
                multiLayerWaves(geometry: geometry)
                
                // 中心文本
                centerText
                
                // 状态指示器
                statusIndicator
            }
        }
        .onAppear {
            setupAnimations()
        }
        .onChange(of: thermalState) { _, newState in
            animateStateChange()
        }
    }
    
    // MARK: - 背景渐变
    private func backgroundGradient(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(config.backgroundGradient)
            .opacity(glowIntensity * 0.6)
            .blur(radius: 20)
            .ignoresSafeArea(.all)
    }
    
    // MARK: - 多层海浪效果
    private func multiLayerWaves(geometry: GeometryProxy) -> some View {
        ZStack {
            // 背景海浪层
            WaveBackgroundShape(
                offset: secondWaveOffset,
                percent: currentPercent,
                waveIntensity: config.waveIntensity,
                phaseShift: 180
            )
            .fill(config.waveGradient)
            .opacity(0.4)
            
            // 主海浪层
            WaveShape(
                offset: waveOffset,
                percent: currentPercent,
                waveIntensity: config.waveIntensity
            )
            .fill(config.waveGradient)
            
            // 表面光晕效果
            WaveShape(
                offset: waveOffset,
                percent: currentPercent,
                waveIntensity: config.waveIntensity * 0.5
            )
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.8),
                        Color.white.opacity(0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 2
            )
            .mask(
                Rectangle()
                    .frame(height: geometry.size.height * 0.1)
                    .offset(y: -geometry.size.height * CGFloat(currentPercent / 100) + geometry.size.height * 0.05)
            )
        }
    }
    
    // MARK: - 中心文本
    private var centerText: some View {
        VStack(spacing: 8) {
            Text(config.displayText)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(config.textColor)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            if isCurrentState {
                Text("当前状态")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(config.textColor.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            } else {
                Text("预览状态")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(config.textColor.opacity(0.6))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - 状态指示器
    private var statusIndicator: some View {
        VStack {
            HStack {
                Spacer()
                
                // 热度等级指示器
                VStack(spacing: 4) {
                    ForEach(ThermalState.allCases.reversed(), id: \.self) { state in
                        Circle()
                            .fill(state == thermalState ? config.colors.first ?? .white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.trailing, 20)
                .padding(.top, 20)
            }
            Spacer()
        }
    }
    
    // MARK: - 动画设置
    private func setupAnimations() {
        // 设置初始百分比
        currentPercent = config.percent
        
        // 启动海浪动画
        withAnimation(.linear(duration: config.animationSpeed).repeatForever(autoreverses: false)) {
            waveOffset = Angle(degrees: 360)
        }
        
        // 启动第二层海浪动画（反向）
        withAnimation(.linear(duration: config.animationSpeed * 1.2).repeatForever(autoreverses: false)) {
            secondWaveOffset = Angle(degrees: -360 + 180)
        }
        
        // 启动发光效果动画
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
    }
    
    // MARK: - 状态变化动画
    private func animateStateChange() {
        let newConfig = ThermalWaveConfiguration.configuration(for: thermalState)
        
        withAnimation(.easeInOut(duration: 1.0)) {
            currentPercent = newConfig.percent
        }
        
        // 重新设置动画速度
        withAnimation(.linear(duration: newConfig.animationSpeed).repeatForever(autoreverses: false)) {
            waveOffset = Angle(degrees: waveOffset.degrees + 360)
        }
        
        withAnimation(.linear(duration: newConfig.animationSpeed * 1.2).repeatForever(autoreverses: false)) {
            secondWaveOffset = Angle(degrees: secondWaveOffset.degrees - 360)
        }
    }
}

// MARK: - Preview
#Preview("正常状态") {
    ThermalWaveView(thermalState: .normal, isCurrentState: true)
        .background(Color.black)
}

#Preview("轻微发热") {
    ThermalWaveView(thermalState: .fair, isCurrentState: true)
        .background(Color.black)
}

#Preview("中度发热") {
    ThermalWaveView(thermalState: .serious, isCurrentState: true)
        .background(Color.black)
}

#Preview("严重发热") {
    ThermalWaveView(thermalState: .critical, isCurrentState: true)
        .background(Color.black)
}