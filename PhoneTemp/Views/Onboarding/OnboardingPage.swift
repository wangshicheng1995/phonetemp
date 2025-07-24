//
//  OnboardingView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/24.
//

import SwiftUI

// MARK: - 引导页面数据模型
struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let iconName: String
    let thermalState: ThermalState
    let showPayment: Bool
    
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "hey，数字时代的朋友。",
            subtitle: "初次相遇。",
            description: "我们的设备日夜不停地工作着，\n承载着我们的生活、工作和梦想。\n但它们的「感受」，\n却常常被我们忽略在匆忙的日常里。",
            iconName: "thermometer.sun",
            thermalState: .normal,
            showPayment: false
        ),
        OnboardingPage(
            title: "有时候，它们会发烫，",
            subtitle: "像发烧的孩子一样。",
            description: "当处理器全力运转，\n当电池拼命充电，\n当屏幕长时间发光，\n它们用温度向我们求救。",
            iconName: "cpu",
            thermalState: .fair,
            showPayment: false
        ),
        OnboardingPage(
            title: "而我们，往往察觉不到",
            subtitle: "这些无声的信号。",
            description: "直到设备变得卡顿，\n直到电池快速衰减，\n直到意外关机的那一刻，\n我们才意识到忽略了什么。",
            iconName: "antenna.radiowaves.left.and.right",
            thermalState: .serious,
            showPayment: false
        ),
        OnboardingPage(
            title: "所以我们创造了手机温度",
            subtitle: "就像关心朋友的体温一样，\n简单而温暖地。",
            description: "去感知，而非被忽视；\n去呵护，而非被透支。\n\n用（关怀），\n守护（数字生活的平衡）。\n\n你可以免费试用手机温度 3 天，\n或者，\n让它成为你设备健康的守护者。\n\nEnjoy。",
            iconName: "heart",
            thermalState: .critical,
            showPayment: true
        )
    ]
}

// MARK: - 主引导视图
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @EnvironmentObject var onboardingManager: OnboardingManager
    @State private var currentPageIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    private let pages = OnboardingPage.pages
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 深色背景 - 与主App一致
                Color(red: 0.05, green: 0.08, blue: 0.08)
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // 使用 HStack 替代 ScrollView，手动处理滑动
                    HStack(spacing: 0) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            OnboardingPageView(
                                page: pages[index],
                                isLastPage: index == pages.count - 1,
                                onComplete: completeOnboarding,
                                onSkip: completeOnboarding
                            )
                            .environmentObject(onboardingManager)
                            .frame(width: geometry.size.width)
                        }
                    }
                    .offset(x: -CGFloat(currentPageIndex) * geometry.size.width + dragOffset)
                    .animation(isDragging ? .none : .easeInOut(duration: 0.3), value: currentPageIndex)
                    .animation(isDragging ? .none : .easeInOut(duration: 0.3), value: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                isDragging = false
                                let threshold: CGFloat = geometry.size.width * 0.25 // 25% 的滑动距离触发切换
                                let newIndex: Int
                                
                                if value.translation.width > threshold && currentPageIndex > 0 {
                                    // 向右滑动，返回上一页
                                    newIndex = currentPageIndex - 1
                                } else if value.translation.width < -threshold && currentPageIndex < pages.count - 1 {
                                    // 向左滑动，进入下一页
                                    newIndex = currentPageIndex + 1
                                } else {
                                    // 滑动不足，保持当前页
                                    newIndex = currentPageIndex
                                }
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPageIndex = newIndex
                                    dragOffset = 0
                                }
                            }
                    )
                    
                    // 页面指示器和控制按钮
                    bottomControls
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // 确保初始页面索引有效
            if currentPageIndex >= pages.count {
                currentPageIndex = 0
            }
        }
    }
    
    // MARK: - 底部控制区域
    private var bottomControls: some View {
        HStack {
            // 跳过按钮（非最后一页显示）
            if currentPageIndex < pages.count - 1 {
                Button("跳过") {
                    completeOnboarding()
                }
                .foregroundColor(.white.opacity(0.6))
                .font(.subheadline)
            } else {
                Spacer()
            }
            
            Spacer()
            
            // 页面指示器
            if pages.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPageIndex = index
                                dragOffset = 0
                            }
                        }) {
                            Circle()
                                .fill(index == currentPageIndex ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Spacer()
            
            // 下一页按钮（非最后一页显示）
            if currentPageIndex < pages.count - 1 {
                Button("下一页") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        let nextIndex = min(currentPageIndex + 1, pages.count - 1)
                        currentPageIndex = nextIndex
                        dragOffset = 0
                    }
                }
                .foregroundColor(.blue)
                .font(.subheadline)
                .fontWeight(.medium)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 40)
    }
    
    // MARK: - 完成引导
    private func completeOnboarding() {
        DispatchQueue.main.async {
            self.isOnboardingComplete = true
        }
    }
}

// MARK: - 单页引导视图
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool
    let onComplete: () -> Void
    let onSkip: () -> Void
    @EnvironmentObject var onboardingManager: OnboardingManager
    
    @State private var glowIntensity: Double = 0.5
    
    var body: some View {
        ZStack {
            // 背景动态效果
            backgroundEffects
            
            VStack(spacing: 0) {
                Spacer()
                
                // 主要内容区域
                contentArea
                
                Spacer()
                
                // 付费选项（仅最后一页显示）
                if page.showPayment {
                    paymentOptions
                        .padding(.bottom, 60)
                } else {
                    Spacer().frame(height: 120)
                }
            }
        }
        .onAppear {
            // 启动呼吸动画
            withAnimation(
                Animation.easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true)
            ) {
                glowIntensity = 1.0
            }
        }
    }
    
    // MARK: - 背景动态效果
    private var backgroundEffects: some View {
        ZStack {
            let colorScheme = page.thermalState.colorScheme
            
            // 最外层模糊光晕
            RoundedRectangle(cornerRadius: 150)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: colorScheme.outerGlow),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 200, height: 350)
                .blur(radius: 80)
                .opacity(glowIntensity * 0.4)
            
            // 中层光晕
            RoundedRectangle(cornerRadius: 120)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: colorScheme.middleGlow),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 180, height: 320)
                .blur(radius: 40)
                .opacity(glowIntensity * 0.6)
        }
        .offset(x: -80, y: -50)
    }
    
    // MARK: - 内容区域
    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 标题
            Text(page.title)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 副标题
            if !page.subtitle.isEmpty {
                Text(page.subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 描述文字
            Text(page.description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - 付费选项
    private var paymentOptions: some View {
        VStack(spacing: 12) {
            // 永久使用按钮
            Button(action: {
                // 处理购买逻辑
                handlePurchase()
            }) {
                Text("¥3.00 永久使用")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 免费试用按钮
            Button(action: {
                // 处理试用逻辑
                handleFreeTrial()
            }) {
                Text("3天免费试用")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 底部链接
            HStack(spacing: 20) {
                Button("恢复购买") {
                    // 处理恢复购买
                    handleRestorePurchase()
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .buttonStyle(PlainButtonStyle())
                
                Text("·")
                    .foregroundColor(.white.opacity(0.3))
                
                Button("隐私政策") {
                    // 打开隐私政策
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .buttonStyle(PlainButtonStyle())
                
                Text("·")
                    .foregroundColor(.white.opacity(0.3))
                
                Button("用户协议") {
                    // 打开用户协议
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - 购买处理方法
    private func handlePurchase() {
        print("OnboardingPageView: 处理购买逻辑")
        // TODO: 实现 StoreKit 购买逻辑
        onboardingManager.completePurchase()
        onComplete()
    }
    
    private func handleFreeTrial() {
        print("OnboardingPageView: 开始3天免费试用")
        onboardingManager.startFreeTrial()
        onComplete()
    }
    
    private func handleRestorePurchase() {
        print("OnboardingPageView: 恢复购买")
        onboardingManager.restorePurchase()
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
        .environmentObject(OnboardingManager())
}
