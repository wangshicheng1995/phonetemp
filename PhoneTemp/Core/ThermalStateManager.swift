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
class ThermalStateManager: ObservableObject {
    @Published var currentThermalState: ThermalState = .normal
    private var timer: Timer?
    private var activityManager: ThermalActivityManager?
    
    init() {
        startMonitoring()
        setupActivityManager()
        // 监听热状态变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateDidChange),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
        
        // 监听应用生命周期
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
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func startMonitoring() {
        // 初始获取热状态
        updateThermalState()
        
        // 每2秒更新一次热状态（避免过于频繁）
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateThermalState()
            }
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func thermalStateDidChange() {
        DispatchQueue.main.async {
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
        
        // 如果状态发生变化，更新 Live Activity
        if previousState != self.currentThermalState {
            updateLiveActivity()
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
    
    // MARK: - 应用生命周期处理
    @objc private func appDidEnterBackground() {
        print("ThermalStateManager: App entered background")
        Task { @MainActor in
            self.activityManager?.handleAppBackgrounding(with: self.currentThermalState)
        }
    }
    
    @objc private func appWillEnterForeground() {
        print("ThermalStateManager: App will enter foreground")
        Task { @MainActor in
            self.activityManager?.handleAppForegrounding()
        }
    }
    
    // MARK: - 公开方法
    func getActivityManager() -> ThermalActivityManager? {
        return activityManager
    }
}
