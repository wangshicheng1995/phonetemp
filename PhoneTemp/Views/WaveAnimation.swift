//
//  WaveAnimation.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/29.
//

import SwiftUI

// MARK: - 热度海浪动画视图
struct WaveAnimation: View {
    let realThermalState: ThermalState
    @State private var percent = 20.0
    @State private var waveOffset = Angle(degrees: 0)
    @State private var isInteracting = false
    @State private var lastInteractionTime = Date()
    
    // 交互超时时间
    private let interactionTimeout: TimeInterval = 3.0
    
    // 根据热度状态计算目标百分比
    private var targetPercent: Double {
        switch realThermalState {
        case .normal: return 22.0
        case .fair: return 42.0
        case .serious: return 68.0
        case .critical: return 88.0
        }
    }
    
    // 根据当前百分比计算热度状态
    private var currentThermalState: ThermalState {
        if percent <= 30.0 {
            return .normal
        } else if percent <= 50.0 {
            return .fair
        } else if percent <= 75.0 {
            return .serious
        } else {
            return .critical
        }
    }
    
    // 根据当前状态获取海浪颜色
    private var waveColor: Color {
        switch currentThermalState {
        case .normal:
            return Color.blue
        case .fair:
            return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .serious:
            return Color(red: 1.0, green: 0.5, blue: 0.1)
        case .critical:
            return Color(red: 1.0, green: 0.2, blue: 0.2)
        }
    }
    
    // 根据当前状态获取背景渐变
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                waveColor.opacity(0.3),
                waveColor.opacity(0.1),
                Color.clear
            ]),
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    // 状态显示文本
    private var stateText: String {
        if isInteracting {
            return currentThermalState.rawValue
        } else {
            return realThermalState.rawValue
        }
    }
    
    // 副标题文本
    private var subtitleText: String {
        if isInteracting {
            return "拖动调节"
        } else {
            return "当前状态"
        }
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            backgroundGradient
                .ignoresSafeArea(.all)
            
            // 海浪
            Wave(offSet: Angle(degrees: waveOffset.degrees), percent: percent)
                .fill(waveColor)
                .ignoresSafeArea(.all)
            
            // 中心文本
            VStack(spacing: 8) {
                Text(stateText)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text(subtitleText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            // 交互处理层
            InvisibleSlider(
                percent: $percent,
                isInteracting: $isInteracting,
                lastInteractionTime: $lastInteractionTime
            )
        }
        .onAppear {
            // 初始化为真实状态
            percent = targetPercent
            
            // 启动海浪动画
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                self.waveOffset = Angle(degrees: 360)
            }
        }
        .onChange(of: realThermalState) { _, newState in
            // 只有在非交互状态下才自动更新
            if !isInteracting {
                animateToRealState()
            }
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            checkInteractionTimeout()
        }
    }
    
    // MARK: - 动画到真实状态
    private func animateToRealState() {
        withAnimation(.easeInOut(duration: 1.5)) {
            percent = targetPercent
        }
    }
    
    // MARK: - 检查交互超时
    private func checkInteractionTimeout() {
        if isInteracting && Date().timeIntervalSince(lastInteractionTime) >= interactionTimeout {
            // 超时后回到真实状态
            isInteracting = false
            animateToRealState()
        }
    }
}

// MARK: - 海浪形状（保持原有实现）
struct Wave: Shape {
    
    var offSet: Angle
    var percent: Double
    
    var animatableData: Double {
        get { offSet.degrees }
        set { offSet = Angle(degrees: newValue) }
    }
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        
        let lowestWave = 0.02
        let highestWave = 1.00
        
        let newPercent = lowestWave + (highestWave - lowestWave) * (percent / 100)
        let waveHeight = 0.015 * rect.height
        let yOffSet = CGFloat(1 - newPercent) * (rect.height - 4 * waveHeight) + 2 * waveHeight
        let startAngle = offSet
        let endAngle = offSet + Angle(degrees: 360 + 10)
        
        p.move(to: CGPoint(x: 0, y: yOffSet + waveHeight * CGFloat(sin(offSet.radians))))
        
        for angle in stride(from: startAngle.degrees, through: endAngle.degrees, by: 5) {
            let x = CGFloat((angle - startAngle.degrees) / 360) * rect.width
            p.addLine(to: CGPoint(x: x, y: yOffSet + waveHeight * CGFloat(sin(Angle(degrees: angle).radians))))
        }
        
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        
        return p
    }
}

// MARK: - 修改后的交互滑块
struct InvisibleSlider: View {
    
    @Binding var percent: Double
    @Binding var isInteracting: Bool
    @Binding var lastInteractionTime: Date
    
    var body: some View {
        GeometryReader { geo in
            let dragGesture = DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isInteracting = true
                    lastInteractionTime = Date()
                    
                    let newPercent = 1.0 - Double(value.location.y / geo.size.height)
                    let clampedPercent = max(0, min(100, newPercent * 100))
                    
                    withAnimation(.easeOut(duration: 0.1)) {
                        self.percent = clampedPercent
                    }
                    
                    // 提供触觉反馈
                    provideTactileFeedback(for: clampedPercent)
                }
                .onEnded { value in
                    // 拖拽结束，准备超时检测
                    lastInteractionTime = Date()
                }
            
            Rectangle()
                .opacity(0.001)
                .frame(width: geo.size.width, height: geo.size.height)
                .gesture(dragGesture)
        }
    }
    
    // MARK: - 触觉反馈
    private func provideTactileFeedback(for percent: Double) {
        let newState = stateForPercent(percent)
        let currentState = stateForPercent(self.percent)
        
        // 只在状态改变时提供反馈
        if newState != currentState {
            let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
            
            switch newState {
            case .normal:
                feedbackStyle = .light
            case .fair:
                feedbackStyle = .medium
            case .serious:
                feedbackStyle = .heavy
            case .critical:
                feedbackStyle = .heavy
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: feedbackStyle)
            impactFeedback.impactOccurred()
        }
    }
    
    private func stateForPercent(_ percent: Double) -> ThermalState {
        if percent <= 30.0 {
            return .normal
        } else if percent <= 50.0 {
            return .fair
        } else if percent <= 75.0 {
            return .serious
        } else {
            return .critical
        }
    }
}

// MARK: - Preview
#Preview("正常状态") {
    WaveAnimation(realThermalState: .normal)
}

#Preview("严重发热") {
    WaveAnimation(realThermalState: .critical)
}
