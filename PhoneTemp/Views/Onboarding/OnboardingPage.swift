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
    
    //
    // Note: The `totalOffset` state is no longer needed.
    // The offset is now calculated directly from `currentPageIndex`.
    //
    private let pages = OnboardingPage.pages
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 深色背景 - 与主App一致
                Color(red: 0.05, green: 0.08, blue: 0.08)
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // 主内容区域 - 使用 TabView 实现更原生的滑动翻页
                    TabView(selection: $currentPageIndex.animation(.spring())) {
                        ForEach(pages.indices, id: \.self) { index in
                            OnboardingPageView(
                                page: pages[index],
                                isLastPage: index == pages.count - 1,
                                onComplete: completeOnboarding,
                                onSkip: completeOnboarding
                            )
                            .environmentObject(onboardingManager)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never)) // 使用 .page 样式并隐藏默认指示器
                    
                    // 页面指示器和控制按钮
                    bottomControls(screenWidth: geometry.size.width)
                        .frame(height: 100) // 固定高度
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - 底部控制区域
    private func bottomControls(screenWidth: CGFloat) -> some View {
        HStack {
            // MARK: - FIX: Replaced placeholder with a more robust version
            // 跳过按钮 (在最后一页隐藏)
            Button("跳过") {
                completeOnboarding()
            }
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.6))
            .opacity(currentPageIndex < pages.count - 1 ? 1 : 0) // 通过透明度隐藏
            .disabled(currentPageIndex == pages.count - 1) // 禁用按钮
            
            Spacer()
            
            // 页面指示器
            if pages.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPageIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                // 点击指示器时，平滑地切换页面
                                currentPageIndex = index
                            }
                    }
                }
            }
            
            Spacer()
            
            // MARK: - FIX: Replaced placeholder logic to ensure visibility
            // 下一页按钮 (在最后一页隐藏)
            Button("下一页") {
                // 平滑地移动到下一页
                let nextIndex = min(currentPageIndex + 1, pages.count - 1)
                currentPageIndex = nextIndex
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .opacity(currentPageIndex < pages.count - 1 ? 1 : 0) // 通过透明度隐藏
            .disabled(currentPageIndex == pages.count - 1) // 禁用按钮
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 40)
    }
    
    // MARK: - 完成引导
    private func completeOnboarding() {
        // 使用 withAnimation 使得可能的界面切换更平滑
        withAnimation {
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
    
    @State private var animationOffset: CGFloat = 0
    @State private var animationTimer: Timer?
    
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
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    // MARK: - 手动动画控制
    private func startAnimation() {
        stopAnimation()
        DispatchQueue.main.async {
            self.animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                DispatchQueue.main.async {
                    self.animationOffset += 0.05
                    if self.animationOffset > .pi * 2 {
                        self.animationOffset = 0
                    }
                }
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    // MARK: - 背景动态效果
    private var backgroundEffects: some View {
        ZStack {
            let colorScheme = page.thermalState.colorScheme
            let glowIntensity = 0.5 + 0.3 * sin(animationOffset)
            
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
            Text(page.title)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !page.subtitle.isEmpty {
                Text(page.subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text(page.description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 30)
        .offset(y: page.showPayment ? 30 : 0) // 第四页的偏移量
    }
    
    // MARK: - 付费选项
    private var paymentOptions: some View {
        VStack(spacing: 12) {
            Button(action: {
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
            
            Button(action: {
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
            
            HStack(spacing: 20) {
                Button("恢复购买") { handleRestorePurchase() }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .buttonStyle(PlainButtonStyle())
                
                Text("·").foregroundColor(.white.opacity(0.3))
                
                Button("隐私政策") { /* 打开隐私政策 */ }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .buttonStyle(PlainButtonStyle())
                
                Text("·").foregroundColor(.white.opacity(0.3))
                
                Button("用户协议") { /* 打开用户协议 */ }
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
        DispatchQueue.main.async {
            onboardingManager.completePurchase()
            onComplete()
        }
    }
    
    private func handleFreeTrial() {
        print("OnboardingPageView: 开始3天免费试用")
        DispatchQueue.main.async {
            onboardingManager.startFreeTrial()
            onComplete()
        }
    }
    
    private func handleRestorePurchase() {
        print("OnboardingPageView: 恢复购买")
        DispatchQueue.main.async {
            onboardingManager.restorePurchase()
        }
    }
}

// MARK: - Preview
#Preview {
    //
    // Note: You will need to define `ThermalState`, `OnboardingManager`,
    // and the color schemes for the preview to work, as they were
    // not fully defined in the original file.
    //
    OnboardingView(isOnboardingComplete: .constant(false))
        .environmentObject(OnboardingManager())
}
