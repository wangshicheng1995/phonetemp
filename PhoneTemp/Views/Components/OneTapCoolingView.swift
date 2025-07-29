//
//  OneTapCoolingView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/27.
//

import SwiftUI

// MARK: - 一键降温视图
struct OneTapCoolingView: View {
    @Binding var isPresented: Bool
    let thermalState: ThermalState
    
    @State private var animationPhase: CoolingPhase = .initial
    @State private var currentTextIndex = 0
    @State private var showParticles = false
    @State private var showFinalText = false
    @State private var particleOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 0.1
    @State private var backgroundOpacity: Double = 0
    
    // 动画文本序列
    private let animationTexts = [
        "正在开启强力降温模式...",
        "启动 CPU 制冷系统...",
        "激活智能温控算法...",
        "优化散热性能中...",
        "降温模式已激活 ✓"
    ]
    
    // 动画阶段枚举
    enum CoolingPhase {
        case initial
        case particleAnimation
        case textSequence
        case finalMessage
    }
    
    var body: some View {
        ZStack {
            // 深色半透明背景
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    if showFinalText {
                        dismissView()
                    }
                }
            
            // 粒子动画层
            if showParticles {
                particleAnimationLayer
            }
            
            // 主要内容
            VStack(spacing: 30) {
                Spacer()
                
                // 中央动画图标
                if animationPhase != .finalMessage {
                    centralAnimationIcon
                }
                
                // 动态文本或最终消息
                if showFinalText {
                    finalMessageView
                } else if animationPhase == .textSequence {
                    animatedTextView
                }
                
                Spacer()
                
                // 底部关闭提示（仅在最终消息时显示）
                if showFinalText {
                    dismissHintView
                }
            }
        }
        .onAppear {
            startCoolingAnimation()
        }
    }
    
    // MARK: - 粒子动画层
    private var particleAnimationLayer: some View {
        ZStack {
            // 冷风粒子效果
            ForEach(0..<20, id: \.self) { index in
                ColdWindParticle(
                    delay: Double(index) * 0.1,
                    isActive: showParticles
                )
            }
            
            // 白雾效果
            ForEach(0..<8, id: \.self) { index in
                MistParticle(
                    delay: Double(index) * 0.2,
                    isActive: showParticles
                )
            }
        }
    }
    
    // MARK: - 中央动画图标
    private var centralAnimationIcon: some View {
        ZStack {
            // 外层旋转环
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .blue, .white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(rotationAngle))
            
            // 内层脉冲圆
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.cyan.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(scaleEffect)
            
            // 雪花图标
            Image(systemName: "snowflake")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.cyan)
                .rotationEffect(.degrees(-rotationAngle * 0.5))
        }
    }
    
    // MARK: - 动态文本视图
    private var animatedTextView: some View {
        Text(currentTextIndex < animationTexts.count ? animationTexts[currentTextIndex] : "")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .opacity(animationPhase == .textSequence ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5), value: currentTextIndex)
    }
    
    // MARK: - 最终消息视图
    private var finalMessageView: some View {
        VStack(spacing: 20) {
            Text("真正的一键降温模式，是放下手机，\n让眼睛和手机都得到休息。")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 30)
            
            Text("别担心，温度恢复正常后，\n手机热度会推送消息，你可继续正常使用。")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
        }
        .opacity(showFinalText ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 1.0), value: showFinalText)
    }
    
    // MARK: - 关闭提示视图
    private var dismissHintView: some View {
        VStack(spacing: 8) {
            Text("轻点任意位置关闭")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.bottom, 50)
    }
    
    // MARK: - 动画控制方法
    private func startCoolingAnimation() {
        // 第一阶段：背景淡入
        withAnimation(.easeInOut(duration: 0.5)) {
            backgroundOpacity = 0.9
        }
        
        // 第二阶段：开始粒子动画和中央图标
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animationPhase = .particleAnimation
            showParticles = true
            
            // 中央图标动画
            withAnimation(.linear(duration: 3.0).repeatCount(3, autoreverses: false)) {
                rotationAngle = 360
            }
            
            withAnimation(.easeInOut(duration: 1.5).repeatCount(3, autoreverses: true)) {
                scaleEffect = 1.2
            }
        }
        
        // 第三阶段：文本序列动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            animationPhase = .textSequence
            startTextSequence()
        }
    }
    
    private func startTextSequence() {
        // 每个文本显示1秒
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if currentTextIndex < animationTexts.count - 1 {
                currentTextIndex += 1
            } else {
                timer.invalidate()
                // 延迟0.5秒后显示最终消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showFinalMessageView()
                }
            }
        }
        
        // 立即显示第一个文本
        currentTextIndex = 0
    }
    
    private func showFinalMessageView() {
        animationPhase = .finalMessage
        
        // 停止粒子动画
        withAnimation(.easeOut(duration: 1.0)) {
            showParticles = false
        }
        
        // 显示最终消息
        withAnimation(.easeInOut(duration: 0.8)) {
            showFinalText = true
        }
    }
    
    private func dismissView() {
        withAnimation(.easeInOut(duration: 0.5)) {
            backgroundOpacity = 0
            showFinalText = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}

// MARK: - 冷风粒子组件
struct ColdWindParticle: View {
    let delay: Double
    let isActive: Bool
    
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotationAngle: Double = 0
    
    private let startPositions: [CGPoint] = [
        CGPoint(x: -50, y: 100),
        CGPoint(x: UIScreen.main.bounds.width + 50, y: 200),
        CGPoint(x: -30, y: 300),
        CGPoint(x: UIScreen.main.bounds.width + 30, y: 400)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let startPos = startPositions[Int(delay * 10) % startPositions.count]
            let isFromLeft = startPos.x < 0
            
            Image(systemName: "wind")
                .font(.system(size: CGFloat.random(in: 12...20)))
                .foregroundColor(.cyan.opacity(opacity))
                .rotationEffect(.degrees(rotationAngle))
                .position(
                    x: startPos.x + offset * (isFromLeft ? 1 : -1),
                    y: startPos.y
                )
                .onAppear {
                    if isActive {
                        startAnimation()
                    }
                }
                .onChange(of: isActive) { _, newValue in
                    if newValue {
                        startAnimation()
                    } else {
                        stopAnimation()
                    }
                }
        }
    }
    
    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 1.0
            }
            
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                offset = UIScreen.main.bounds.width + 100
                rotationAngle = 360
            }
            
            // 粒子生命周期：淡出
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0
                }
            }
        }
    }
    
    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
    }
}

// MARK: - 白雾粒子组件
struct MistParticle: View {
    let delay: Double
    let isActive: Bool
    
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        Circle()
            .fill(.white.opacity(opacity))
            .frame(width: CGFloat.random(in: 30...80), height: CGFloat.random(in: 30...80))
            .scaleEffect(scale)
            .offset(offset)
            .position(
                x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                y: CGFloat.random(in: 200...UIScreen.main.bounds.height - 200)
            )
            .blur(radius: 10)
            .onAppear {
                if isActive {
                    startMistAnimation()
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startMistAnimation()
                } else {
                    stopMistAnimation()
                }
            }
    }
    
    private func startMistAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 1.0)) {
                opacity = Double.random(in: 0.1...0.3)
                scale = CGFloat.random(in: 0.8...1.5)
            }
            
            withAnimation(.linear(duration: 4.0)) {
                offset = CGSize(
                    width: CGFloat.random(in: -100...100),
                    height: CGFloat.random(in: -150...150)
                )
            }
            
            // 雾气消散
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 1.0)) {
                    opacity = 0
                    scale = 0.1
                }
            }
        }
    }
    
    private func stopMistAnimation() {
        withAnimation(.easeOut(duration: 0.5)) {
            opacity = 0
            scale = 0.1
        }
    }
}

// MARK: - Preview
#Preview {
    OneTapCoolingView(
        isPresented: .constant(true),
        thermalState: .serious
    )
}
