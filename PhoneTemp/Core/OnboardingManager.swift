//
//  OnboardingManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/24.
//

import Foundation
import Combine

// MARK: - 引导页面管理器
@MainActor
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
    
    // 添加 StoreKit 管理器的引用和订阅
    private let storeKitManager = UniversalStoreKitManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("OnboardingManager: 初始化开始")
        loadOnboardingStatus()
        loadPurchaseStatus()
        checkTrialStatus()
        setupStoreKitBinding()
        
        print("OnboardingManager: 初始化完成")
        print("  - isOnboardingComplete: \(isOnboardingComplete)")
        print("  - isPurchased: \(isPurchased)")
        print("  - isTrialActive: \(isTrialActive)")
        print("  - canUseApp: \(canUseApp)")
        print("  - shouldShowPaywall: \(shouldShowPaywall)")
    }
    
    // MARK: - 设置与 StoreKit 的绑定
    private func setupStoreKitBinding() {
        // 监听 StoreKit 的购买状态变化
        storeKitManager.$isPremiumUnlocked
            .sink { [weak self] isPremiumUnlocked in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if isPremiumUnlocked && !self.isPurchased {
                        // StoreKit 显示已购买，但本地状态未同步，更新本地状态
                        self.syncPurchaseFromStoreKit()
                        print("OnboardingManager: 从 StoreKit 同步购买状态")
                    } else if !isPremiumUnlocked && self.isPurchased {
                        // StoreKit 显示未购买，但本地状态显示已购买，以 StoreKit 为准
                        self.isPurchased = false
                        self.userDefaults.set(false, forKey: self.purchaseStatusKey)
                        print("OnboardingManager: StoreKit 状态不匹配，重置本地购买状态")
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 从 StoreKit 同步购买状态
    private func syncPurchaseFromStoreKit() {
        self.isPurchased = true
        self.isTrialActive = false
        userDefaults.set(true, forKey: purchaseStatusKey)
        userDefaults.removeObject(forKey: trialStartDateKey)
        print("OnboardingManager: 购买状态已从 StoreKit 同步")
    }
    
    // MARK: - 引导状态管理
    private func loadOnboardingStatus() {
        let storedValue = userDefaults.bool(forKey: onboardingCompleteKey)
        self.isOnboardingComplete = storedValue
        print("OnboardingManager: 加载引导状态 - isOnboardingComplete: \(storedValue)")
    }
    
    func completeOnboarding() {
        self.isOnboardingComplete = true
        userDefaults.set(true, forKey: onboardingCompleteKey)
        print("OnboardingManager: 引导完成，状态已保存")
    }
    
    // MARK: - 购买状态管理
    private func loadPurchaseStatus() {
        // 优先使用 StoreKit 的状态，如果 StoreKit 状态未加载完成，则使用本地存储
        let localPurchased = userDefaults.bool(forKey: purchaseStatusKey)
        let storeKitPurchased = storeKitManager.isPremiumUnlocked
        
        let finalPurchased = storeKitPurchased || localPurchased
        
        self.isPurchased = finalPurchased
        
        // 如果状态不一致，同步到本地存储
        if localPurchased != storeKitPurchased {
            userDefaults.set(finalPurchased, forKey: purchaseStatusKey)
            print("OnboardingManager: 同步购买状态 - Local: \(localPurchased), StoreKit: \(storeKitPurchased), Final: \(finalPurchased)")
        }
    }
    
    func completePurchase() {
        self.isPurchased = true
        self.isTrialActive = false
        userDefaults.set(true, forKey: purchaseStatusKey)
        userDefaults.removeObject(forKey: trialStartDateKey)
        print("OnboardingManager: 购买完成，状态已保存")
    }
    
    // MARK: - 试用状态管理
    func startFreeTrial() {
        guard !isPurchased && !isTrialActive else {
            print("OnboardingManager: 已购买或试用中，无法重新开始试用")
            return
        }
        
        let startDate = Date()
        userDefaults.set(startDate, forKey: trialStartDateKey)
        
        self.isTrialActive = true
        self.updateTrialDaysRemaining()
        
        completeOnboarding()
        print("OnboardingManager: 开始3天免费试用")
    }
    
    private func checkTrialStatus() {
        guard !isPurchased else {
            self.isTrialActive = false
            self.trialDaysRemaining = 0
            return
        }
        
        guard let trialStartDate = userDefaults.object(forKey: trialStartDateKey) as? Date else {
            self.isTrialActive = false
            self.trialDaysRemaining = 0
            return
        }
        
        let daysSinceStart = Calendar.current.dateComponents([.day], from: trialStartDate, to: Date()).day ?? 0
        let remainingDays = max(0, trialDurationDays - daysSinceStart)
        
        if remainingDays > 0 {
            self.isTrialActive = true
            self.trialDaysRemaining = remainingDays
        } else {
            self.isTrialActive = false
            self.trialDaysRemaining = 0
        }
        
        print("OnboardingManager: 试用状态检查 - isTrialActive: \(isTrialActive), 剩余天数: \(trialDaysRemaining)")
    }
    
    // MARK: - 公开的试用状态检查方法
    func refreshTrialStatus() {
        checkTrialStatus()
        loadPurchaseStatus() // 同时刷新购买状态
    }
    
    private func updateTrialDaysRemaining() {
        checkTrialStatus()
    }
    
    // MARK: - 应用访问权限
    var canUseApp: Bool {
        let storeKitPurchased = storeKitManager.isPremiumUnlocked
        let result = isPurchased || storeKitPurchased || isTrialActive
        
        if !result {
            print("OnboardingManager: canUseApp = false - isPurchased: \(isPurchased), storeKitPurchased: \(storeKitPurchased), isTrialActive: \(isTrialActive)")
        }
        
        return result
    }
    
    var shouldShowPaywall: Bool {
        let storeKitPurchased = storeKitManager.isPremiumUnlocked
        return !isPurchased && !storeKitPurchased && !isTrialActive
    }
    
    // MARK: - 恢复购买
    func restorePurchase() {
        print("OnboardingManager: 开始恢复购买...")
        
        Task { @MainActor in
            await storeKitManager.restorePurchases()
            
            // 等待一下让 StoreKit 状态更新
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 检查 StoreKit 状态并同步
            if self.storeKitManager.isPremiumUnlocked {
                self.syncPurchaseFromStoreKit()
                print("OnboardingManager: 恢复购买成功")
            } else {
                print("OnboardingManager: 恢复购买失败 - 未找到有效购买记录")
            }
        }
    }
    
    // MARK: - 重置状态（用于调试）
    func resetAllData() {
        userDefaults.removeObject(forKey: onboardingCompleteKey)
        userDefaults.removeObject(forKey: purchaseStatusKey)
        userDefaults.removeObject(forKey: trialStartDateKey)
        
        self.isOnboardingComplete = false
        self.isPurchased = false
        self.isTrialActive = false
        self.trialDaysRemaining = 0
        
        print("OnboardingManager: 所有数据已重置")
    }
}
