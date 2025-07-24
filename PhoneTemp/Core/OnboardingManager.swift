//
//  OnboardingManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/24.
//

import Foundation
import Combine

// MARK: - 引导页面管理器
class OnboardingManager: ObservableObject {
    @Published var isOnboardingComplete: Bool = false
    @Published var isTrialActive: Bool = false
    @Published var isPurchased: Bool = false
    @Published var trialDaysRemaining: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let onboardingCompleteKey = "OnboardingComplete"
    private let purchaseStatusKey = "PurchaseStatus"
    private let trialStartDateKey = "TrialStartDate"
    private let trialDurationDays = 3
    
    init() {
        print("OnboardingManager: 初始化开始")
        loadOnboardingStatus()
        loadPurchaseStatus()
        checkTrialStatus()
        
        print("OnboardingManager: 初始化完成")
        print("  - isOnboardingComplete: \(isOnboardingComplete)")
        print("  - isPurchased: \(isPurchased)")
        print("  - isTrialActive: \(isTrialActive)")
        print("  - canUseApp: \(canUseApp)")
        print("  - shouldShowPaywall: \(shouldShowPaywall)")
    }
    
    // MARK: - 引导状态管理
    private func loadOnboardingStatus() {
        let storedValue = userDefaults.bool(forKey: onboardingCompleteKey)
        DispatchQueue.main.async {
            self.isOnboardingComplete = storedValue
        }
        print("OnboardingManager: 加载引导状态 - isOnboardingComplete: \(storedValue)")
    }
    
    func completeOnboarding() {
        DispatchQueue.main.async {
            self.isOnboardingComplete = true
        }
        userDefaults.set(true, forKey: onboardingCompleteKey)
        print("OnboardingManager: 引导完成，状态已保存")
    }
    
    // MARK: - 购买状态管理
    private func loadPurchaseStatus() {
        let storedValue = userDefaults.bool(forKey: purchaseStatusKey)
        DispatchQueue.main.async {
            self.isPurchased = storedValue
        }
    }
    
    func completePurchase() {
        DispatchQueue.main.async {
            self.isPurchased = true
            self.isTrialActive = false
        }
        userDefaults.set(true, forKey: purchaseStatusKey)
        userDefaults.removeObject(forKey: trialStartDateKey)
    }
    
    // MARK: - 试用状态管理
    func startFreeTrial() {
        guard !isPurchased && !isTrialActive else { return }
        
        let startDate = Date()
        userDefaults.set(startDate, forKey: trialStartDateKey)
        
        DispatchQueue.main.async {
            self.isTrialActive = true
            self.updateTrialDaysRemaining()
        }
        
        completeOnboarding()
        print("OnboardingManager: 开始3天免费试用")
    }
    
    private func checkTrialStatus() {
        guard !isPurchased else {
            DispatchQueue.main.async {
                self.isTrialActive = false
                self.trialDaysRemaining = 0
            }
            return
        }
        
        guard let trialStartDate = userDefaults.object(forKey: trialStartDateKey) as? Date else {
            DispatchQueue.main.async {
                self.isTrialActive = false
                self.trialDaysRemaining = 0
            }
            return
        }
        
        let daysSinceStart = Calendar.current.dateComponents([.day], from: trialStartDate, to: Date()).day ?? 0
        let remainingDays = max(0, trialDurationDays - daysSinceStart)
        
        DispatchQueue.main.async {
            if remainingDays > 0 {
                self.isTrialActive = true
                self.trialDaysRemaining = remainingDays
            } else {
                self.isTrialActive = false
                self.trialDaysRemaining = 0
                // 试用期结束，可以在这里显示购买提示
            }
        }
        
        print("OnboardingManager: 试用状态检查 - isTrialActive: \(isTrialActive), 剩余天数: \(trialDaysRemaining)")
    }
    
    // MARK: - 公开的试用状态检查方法
    func refreshTrialStatus() {
        checkTrialStatus()
    }
    
    private func updateTrialDaysRemaining() {
        checkTrialStatus()
    }
    
    // MARK: - 应用访问权限
    var canUseApp: Bool {
        return isPurchased || isTrialActive
    }
    
    var shouldShowPaywall: Bool {
        return !isPurchased && !isTrialActive
    }
    
    // MARK: - 恢复购买
    func restorePurchase() {
        // TODO: 实现 StoreKit 恢复购买逻辑
        // 这里需要与 App Store 进行通信验证购买状态
        print("恢复购买中...")
    }
    
    // MARK: - 重置状态（用于调试）
    func resetAllData() {
        userDefaults.removeObject(forKey: onboardingCompleteKey)
        userDefaults.removeObject(forKey: purchaseStatusKey)
        userDefaults.removeObject(forKey: trialStartDateKey)
        
        isOnboardingComplete = false
        isPurchased = false
        isTrialActive = false
        trialDaysRemaining = 0
    }
}
