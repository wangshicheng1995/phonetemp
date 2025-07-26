//
//  ThermalActivityManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import Foundation
import ActivityKit
import Combine
import UIKit

// MARK: - Live Activity 管理器
@MainActor
class ThermalActivityManager: ObservableObject {
    @Published var isActivityActive = false
    @Published var currentActivity: Activity<ThermalActivityAttributes>?
    
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    init() {
        checkInitialActivityStatus()
    }
    
    // MARK: - 启动 Live Activity
    func startActivity(with thermalState: ThermalState) {
        // 检查权限
        let authInfo = ActivityAuthorizationInfo()
        print("Live Activity authorization status: \(authInfo.areActivitiesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // 如果已有活动，先停止
        if let currentActivity = currentActivity {
            Task {
                await stopActivity()
            }
        }
        
        // 使用 Task 在主线程上执行
        Task { @MainActor in
            do {
                let attributes = ThermalActivityAttributes()
                let contentState = ThermalActivityAttributes.ContentState(thermalState: thermalState)
                
                let activity = try Activity<ThermalActivityAttributes>.request(
                    attributes: attributes,
                    content: ActivityContent(
                        state: contentState,
                        staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
                    ),
                    pushType: nil
                )
                
                self.currentActivity = activity
                self.isActivityActive = true
                
                print("Live Activity started successfully with state: \(thermalState.rawValue)")
            } catch {
                print("Failed to start Live Activity: \(error.localizedDescription)")
                
                // 如果是因为 not foreground 错误，尝试延迟重试
                if error.localizedDescription.contains("not foreground") {
                    self.retryStartActivityWithDelay(thermalState: thermalState)
                }
            }
        }
    }
    
    // MARK: - 延迟重试启动 Live Activity
    private func retryStartActivityWithDelay(thermalState: ThermalState) {
        print("Retrying Live Activity start with delay...")
        
        // 延迟 0.5 秒后重试
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task { @MainActor in
                do {
                    let attributes = ThermalActivityAttributes()
                    let contentState = ThermalActivityAttributes.ContentState(thermalState: thermalState)
                    
                    let activity = try Activity<ThermalActivityAttributes>.request(
                        attributes: attributes,
                        content: ActivityContent(
                            state: contentState,
                            staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
                        ),
                        pushType: nil
                    )
                    
                    self.currentActivity = activity
                    self.isActivityActive = true
                    
                    print("Live Activity started successfully on retry with state: \(thermalState.rawValue)")
                } catch {
                    print("Failed to start Live Activity on retry: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 更新 Live Activity
    func updateActivity(with thermalState: ThermalState) {
        guard let activity = currentActivity else {
            print("No active Live Activity to update")
            return
        }
        
        let contentState = ThermalActivityAttributes.ContentState(thermalState: thermalState)
        
        Task {
            await activity.update(
                ActivityContent(
                    state: contentState,
                    staleDate: Calendar.current.date(byAdding: .minute, value: 5, to: Date())
                )
            )
            
            print("Live Activity updated with thermal state: \(thermalState.rawValue)")
        }
    }
    
    // MARK: - 停止 Live Activity
    func stopActivity() async {
        guard let activity = currentActivity else {
            print("No active Live Activity to stop")
            return
        }
        
        let contentState = ThermalActivityAttributes.ContentState(thermalState: .normal)
        
        await activity.end(
            ActivityContent(
                state: contentState,
                staleDate: Date()
            ),
            dismissalPolicy: .immediate
        )
        
        currentActivity = nil
        isActivityActive = false
        
        print("Live Activity stopped")
    }
    
    // MARK: - 检查初始状态
    private func checkInitialActivityStatus() {
        let authInfo = ActivityAuthorizationInfo()
        print("Live Activity authorization status: \(authInfo.areActivitiesEnabled)")
        
        // 检查是否有现有的活动
        let activities = Activity<ThermalActivityAttributes>.activities
        if let activity = activities.first {
            currentActivity = activity
            isActivityActive = true
            print("Found existing Live Activity")
        } else {
            print("No existing Live Activity found")
        }
    }
    
    // MARK: - 获取活动权限状态
    func checkActivityPermission() -> Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    // MARK: - 应用即将进入后台时启动 Live Activity（修改时机）
    func handleAppWillResignActive(with thermalState: ThermalState) {
        print("App will resign active - preparing Live Activity...")
        
        if checkActivityPermission() {
            print("Permission granted - starting Live Activity in will resign active")
            
            // 开始后台任务以确保有足够时间启动 Live Activity
            beginBackgroundTask()
            
            // 立即启动，不要等到完全进入后台
            startActivity(with: thermalState)
            
            // 延迟结束后台任务
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.endBackgroundTask()
            }
        } else {
            print("Live Activity permission denied")
        }
    }
    
    // MARK: - 应用进入后台时的备用处理
    func handleAppBackgrounding(with thermalState: ThermalState) {
        print("App backgrounding - checking Live Activity status...")
        
        // 如果在 will resign active 阶段没有成功启动，这里再尝试一次
        if !isActivityActive && checkActivityPermission() {
            print("Live Activity not active, attempting to start...")
            startActivity(with: thermalState)
        }
    }
    
    // MARK: - 应用进入前台时停止 Live Activity
    func handleAppForegrounding() {
        print("App foregrounding - checking for active Live Activity...")
        if isActivityActive {
            print("Active Live Activity found - stopping it")
            Task {
                await stopActivity()
            }
        } else {
            print("No active Live Activity to stop")
        }
    }
    
    // MARK: - 后台任务管理
    private func beginBackgroundTask() {
        endBackgroundTask() // 先结束之前的任务
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "LiveActivityStart") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
