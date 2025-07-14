//
//  BackgroundTaskManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import Foundation
import BackgroundTasks
import UIKit

// MARK: - 后台任务管理器
class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    private let backgroundTaskIdentifier = "com.phoneTemp.refresh"
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var isRegistered = false
    
    private init() {}
    
    // MARK: - 注册后台任务
    func registerBackgroundTasks() {
        guard !isRegistered else {
            print("Background task already registered")
            return
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        
        isRegistered = true
        print("Background task registered successfully")
    }
    
    // MARK: - 安排后台任务
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15分钟后
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled")
        } catch {
            print("Could not schedule background refresh: \(error)")
        }
    }
    
    // MARK: - 处理后台任务
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // 安排下一次后台任务
        scheduleBackgroundRefresh()
        
        // 设置任务过期处理
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // 执行后台更新
        performBackgroundUpdate { success in
            task.setTaskCompleted(success: success)
        }
    }
    
    // MARK: - 执行后台更新
    private func performBackgroundUpdate(completion: @escaping (Bool) -> Void) {
        // 这里执行实际的后台更新逻辑
        // 由于我们主要依赖系统的热状态通知，这里主要是保持活跃状态
        
        DispatchQueue.global(qos: .background).async {
            // 模拟短时间的后台工作
            Thread.sleep(forTimeInterval: 2.0)
            
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    // MARK: - 开始后台任务
    func beginBackgroundTask() {
        endBackgroundTask()
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "ThermalMonitoring") {
            self.endBackgroundTask()
        }
    }
    
    // MARK: - 结束后台任务
    func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}