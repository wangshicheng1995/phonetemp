//
//  ThermalActivityManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import Foundation
import ActivityKit
import Combine

// MARK: - Live Activity 管理器
@MainActor
class ThermalActivityManager: ObservableObject {
    @Published var isActivityActive = false
    @Published var currentActivity: Activity<ThermalActivityAttributes>?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkInitialActivityStatus()
    }
    
    // MARK: - 启动 Live Activity
    func startActivity(with thermalState: ThermalState) {
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
        
        let attributes = ThermalActivityAttributes()
        let contentState = ThermalActivityAttributes.ContentState(thermalState: thermalState)
        
        do {
            let activity = try Activity<ThermalActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(
                    state: contentState,
                    staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
                ),
                pushType: nil
            )
            
            currentActivity = activity
            isActivityActive = true
            
            print("Live Activity started successfully with state: \(thermalState.rawValue)")
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
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
    
    // MARK: - 应用进入后台时启动 Live Activity
    func handleAppBackgrounding(with thermalState: ThermalState) {
        print("App backgrounding - checking Live Activity permission...")
        if checkActivityPermission() {
            print("Permission granted - starting Live Activity")
            startActivity(with: thermalState)
        } else {
            print("Live Activity permission denied")
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
}