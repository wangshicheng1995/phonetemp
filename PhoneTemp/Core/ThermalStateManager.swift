//
//  ThermalStateManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import Foundation
import Combine
import ActivityKit
import UIKit

// MARK: - 热状态管理器
@MainActor
class ThermalStateManager: ObservableObject {
    @Published var currentThermalState: ThermalState = .normal
    private var previousThermalState: ThermalState = .normal // 新增：追踪上一个状态
    private var timer: Timer?
    private var activityManager: ThermalActivityManager?
    private let notificationManager = NotificationManager.shared // 新增：推送管理器
    
    init() {
        startMonitoring()
        setupActivityManager()
        setupNotificationManager() // 新增：设置推送管理器
        
        // 监听热状态变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateDidChange),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
        
        // 监听应用生命周期 - 添加更多生命周期事件
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        // deinit 是非隔离的，只能执行线程安全的操作
        timer?.invalidate()
        timer = nil
        NotificationCenter.default.removeObserver(self)
        print("ThermalStateManager: Deinit complete")
    }
    
    // MARK: - 新增：设置推送管理器
    private func setupNotificationManager() {
        Task { @MainActor in
            // 请求推送权限
            let granted = await notificationManager.requestPermission()
            if granted {
                print("ThermalStateManager: 推送权限已获得")
            } else {
                print("ThermalStateManager: 推送权限被拒绝")
            }
        }
    }
    
    private func startMonitoring() {
        // 初始获取热状态
        updateThermalState()
        
        // 每2秒更新一次热状态（避免过于频繁）
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateThermalState()
            }
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - 手动清理方法（供外部调用）
    func invalidate() {
        // 这个方法可以被外部调用来手动清理资源
        stopMonitoring()
        print("ThermalStateManager: Manual invalidation complete")
    }
    
    @objc private func thermalStateDidChange() {
        Task { @MainActor in
            self.updateThermalState()
        }
    }
    
    private func updateThermalState() {
        let previousState = self.currentThermalState
        let currentThermalState = ProcessInfo.processInfo.thermalState
        
        switch currentThermalState {
        case .nominal:
            self.currentThermalState = .normal
        case .fair:
            self.currentThermalState = .fair
        case .serious:
            self.currentThermalState = .serious
        case .critical:
            self.currentThermalState = .critical
        @unknown default:
            self.currentThermalState = .normal
        }
        
        // 如果状态发生变化
        if previousState != self.currentThermalState {
            print("ThermalStateManager: 温度状态变化 - \(previousState.rawValue) → \(self.currentThermalState.rawValue)")
            
            // 发送推送通知（使用 Task 包装）
            Task { @MainActor in
                await self.sendThermalChangeNotification(from: previousState, to: self.currentThermalState)
            }
            
            // 更新 Live Activity
            updateLiveActivity()
            
            // 更新上一个状态
            self.previousThermalState = previousState
        }
    }
    
    // MARK: - 新增：发送温度变化推送（修复为 async）
    private func sendThermalChangeNotification(from previousState: ThermalState, to currentState: ThermalState) async {
        // 只在应用不在前台时发送推送（避免干扰用户）
        let appState = UIApplication.shared.applicationState
        if appState == .background || appState == .inactive {
            notificationManager.sendThermalStateChangeNotification(
                from: previousState,
                to: currentState
            )
        } else {
            print("ThermalStateManager: 应用在前台，跳过推送发送")
        }
    }
    
    // MARK: - 新增：发送测试推送（修复为 async）
    func sendTestNotification() {
        Task { @MainActor in
            notificationManager.sendTestNotification()
        }
    }
    
    // 手动触发更新（用于测试）
    func refreshThermalState() {
        updateThermalState()
    }
    
    // MARK: - Live Activity 相关方法
    private func setupActivityManager() {
        Task { @MainActor in
            self.activityManager = ThermalActivityManager()
        }
    }
    
    private func updateLiveActivity() {
        Task { @MainActor in
            self.activityManager?.updateActivity(with: self.currentThermalState)
        }
    }
    
    // MARK: - 应用生命周期处理（修改时机）
    
    @objc private func appWillResignActive() {
        print("ThermalStateManager: App will resign active")
        Task { @MainActor in
            // 在应用即将失去活跃状态时启动 Live Activity
            self.activityManager?.handleAppWillResignActive(with: self.currentThermalState)
        }
    }
    
    @objc private func appDidEnterBackground() {
        print("ThermalStateManager: App entered background")
        Task { @MainActor in
            // 作为备用处理，检查 Live Activity 是否已启动
            self.activityManager?.handleAppBackgrounding(with: self.currentThermalState)
        }
    }
    
    @objc private func appWillEnterForeground() {
        print("ThermalStateManager: App will enter foreground")
        Task { @MainActor in
            // 应用即将进入前台时的处理
            print("Preparing for app to become active...")
            // 清除推送角标
            notificationManager.clearBadge()
        }
    }
    
    @objc private func appDidBecomeActive() {
        print("ThermalStateManager: App became active")
        Task { @MainActor in
            // 应用变为活跃状态时停止 Live Activity
            self.activityManager?.handleAppForegrounding()
            // 清除推送角标
            notificationManager.clearBadge()
        }
    }
    
    // MARK: - 公开方法
    func getActivityManager() -> ThermalActivityManager? {
        return activityManager
    }
    
    // MARK: - 新增：获取推送管理器
    func getNotificationManager() -> NotificationManager {
        return notificationManager
    }
}
