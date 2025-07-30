//
//  OnboardingPage.swift
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
    let backgroundImage: String
    let showPayment: Bool
    
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "欢迎使用\n手机热度",
            subtitle: "让您的设备更健康，使用更持久",
            backgroundImage: "onboarding4",
            showPayment: true
        )
    ]
}

// MARK: - 主引导视图
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @EnvironmentObject var onboardingManager: OnboardingManager
    
    private let pages = OnboardingPage.pages
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 单页面内容
                OnboardingPageView(
                    page: pages[0],
                    isLastPage: true,
                    onComplete: completeOnboarding,
                    onSkip: completeOnboarding
                )
                .environmentObject(onboardingManager)
                
                // 底部付费选项
                VStack {
                    Spacer()
                    paymentOptions
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - 付费选项
    private var paymentOptions: some View {
        VStack(spacing: 16) {
            // 购买按钮
            Button(action: {
                handlePurchase()
            }) {
                Text("¥3.00 永久使用")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 免费试用按钮
            Button(action: {
                handleFreeTrial()
            }) {
                Text("3天免费试用")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 底部链接按钮
            HStack(spacing: 20) {
                Button("恢复购买") {
                    handleRestorePurchase()
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .buttonStyle(PlainButtonStyle())
                
                Text("·").foregroundColor(.white.opacity(0.3))
                
                Button("隐私政策") {
                    // 打开隐私政策
                    openPrivacyPolicy()
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .buttonStyle(PlainButtonStyle())
                
                Text("·").foregroundColor(.white.opacity(0.3))
                
                Button("用户协议") {
                    // 打开用户协议
                    openTermsOfService()
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 40)
    }
    
    // MARK: - 完成引导
    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isOnboardingComplete = true
        }
    }
    
    // MARK: - 购买处理方法
    private func handlePurchase() {
        print("OnboardingPageView: 处理购买逻辑")
        DispatchQueue.main.async {
            onboardingManager.completePurchase()
            completeOnboarding()
        }
    }
    
    private func handleFreeTrial() {
        print("OnboardingPageView: 开始3天免费试用")
        DispatchQueue.main.async {
            onboardingManager.startFreeTrial()
            completeOnboarding()
        }
    }
    
    private func handleRestorePurchase() {
        print("OnboardingPageView: 恢复购买")
        DispatchQueue.main.async {
            onboardingManager.restorePurchase()
        }
    }
    
    private func openPrivacyPolicy() {
        // TODO: 实现隐私政策页面打开逻辑
        print("打开隐私政策")
    }
    
    private func openTermsOfService() {
        // TODO: 实现用户协议页面打开逻辑
        print("打开用户协议")
    }
}

// MARK: - 单页引导视图
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool
    let onComplete: () -> Void
    let onSkip: () -> Void
    @EnvironmentObject var onboardingManager: OnboardingManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片
                Image(page.backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // 内容区域
                VStack(spacing: 0) {
                    Spacer()
                    
                    // 文字内容区域 - 位于屏幕下方约1/3处
                    VStack(spacing: 12) {
                        // 主标题 - 更大更粗
                        Text(page.title)
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 副标题 - 稍小的字体
                        Text(page.subtitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 25)
                    
                    // 底部间距
                    Spacer().frame(height: 180)
                    
                    // 底部间距
                    Spacer().frame(height: 140)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct OnboardingPage_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingComplete: .constant(false))
            .environmentObject(OnboardingManager())
    }
}
