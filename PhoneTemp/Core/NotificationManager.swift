//
//  NotificationManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/27.
//


//
//  NotificationManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/27.
//

import Foundation
import UserNotifications
import UIKit

// MARK: - 推送通知管理器
@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - 请求推送权限
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.authorizationStatus = .authorized
                    print("NotificationManager: 推送权限已授权")
                } else {
                    self.authorizationStatus = .denied
                    print("NotificationManager: 推送权限被拒绝")
                }
            }
            
            return granted
        } catch {
            print("NotificationManager: 请求推送权限失败 - \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 检查当前授权状态
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
                
                print("NotificationManager: 当前授权状态 - \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    // MARK: - 发送热度变化通知
    func sendThermalStateChangeNotification(from previousState: ThermalState, to currentState: ThermalState) {
        guard isAuthorized else {
            print("NotificationManager: 推送未授权，跳过发送")
            return
        }
        
        let content = createThermalChangeContent(from: previousState, to: currentState)
        let request = UNNotificationRequest(
            identifier: "thermal_change_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // 立即发送
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationManager: 发送热度变化通知失败 - \(error.localizedDescription)")
            } else {
                print("NotificationManager: 热度变化通知已发送 - \(previousState.rawValue) → \(currentState.rawValue)")
            }
        }
    }
    
    // MARK: - 发送测试通知
    func sendTestNotification() {
        guard isAuthorized else {
            print("NotificationManager: 推送未授权，无法发送测试通知")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "手机热度测试"
        content.body = "推送功能正常工作 ✓\n当前时间：\(formatCurrentTime())"
        content.sound = .default
        content.badge = 1
        
        // 添加用户信息用于处理点击
        content.userInfo = [
            "type": "test",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        let request = UNNotificationRequest(
            identifier: "test_notification_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationManager: 发送测试通知失败 - \(error.localizedDescription)")
            } else {
                print("NotificationManager: 测试通知已发送")
            }
        }
    }
    
    // MARK: - 创建热度变化通知内容
    private func createThermalChangeContent(from previousState: ThermalState, to currentState: ThermalState) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // 根据热度变化方向和状态生成不同的通知内容
        let isHeatingUp = isStateHigher(currentState, than: previousState)
        
        if isHeatingUp {
            // 热度上升
            content.title = getThermalUpgradeTitle(to: currentState)
            content.body = getThermalUpgradeBody(from: previousState, to: currentState)
            content.sound = currentState == .critical ? .defaultCritical : .default
        } else {
            // 热度下降
            content.title = getThermalDowngradeTitle(to: currentState)
            content.body = getThermalDowngradeBody(from: previousState, to: currentState)
            content.sound = .default
        }
        
        // 设置 badge 数字
        content.badge = getBadgeNumber(for: currentState)
        
        // 添加用户信息
        content.userInfo = [
            "type": "thermal_change",
            "previous_state": previousState.rawValue,
            "current_state": currentState.rawValue,
            "is_heating_up": isHeatingUp,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        return content
    }
    
    // MARK: - 热度上升通知文案
    private func getThermalUpgradeTitle(to state: ThermalState) -> String {
        switch state {
        case .normal:
            return "设备热度正常"
        case .fair:
            return "设备开始升温"
        case .serious:
            return "设备热度较高"
        case .critical:
            return "⚠️ 设备严重发热"
        }
    }
    
    private func getThermalUpgradeBody(from previousState: ThermalState, to currentState: ThermalState) -> String {
        switch currentState {
        case .normal:
            return "设备运行正常，可以放心使用。"
        case .fair:
            return "设备开始升温，建议适当减少高耗能操作。"
        case .serious:
            return "设备热度较高，建议立即采取降温措施。"
        case .critical:
            return "设备严重发热！请立即停止使用并等待设备冷却。"
        }
    }
    
    // MARK: - 热度下降通知文案
    private func getThermalDowngradeTitle(to state: ThermalState) -> String {
        switch state {
        case .normal:
            return "😊 设备已恢复正常"
        case .fair:
            return "设备热度好转"
        case .serious:
            return "设备热度下降"
        case .critical:
            return "设备仍在发热"
        }
    }
    
    private func getThermalDowngradeBody(from previousState: ThermalState, to currentState: ThermalState) -> String {
        switch currentState {
        case .normal:
            return "设备热度已恢复正常，可以正常使用了。"
        case .fair:
            return "设备热度有所好转，继续保持良好的使用习惯。"
        case .serious:
            return "设备热度有所下降，但仍需注意散热。"
        case .critical:
            return "设备热度略有下降，但仍处于危险状态，请继续等待。"
        }
    }
    
    // MARK: - 辅助方法
    private func isStateHigher(_ state1: ThermalState, than state2: ThermalState) -> Bool {
        let stateOrder: [ThermalState: Int] = [
            .normal: 0,
            .fair: 1,
            .serious: 2,
            .critical: 3
        ]
        
        let level1 = stateOrder[state1] ?? 0
        let level2 = stateOrder[state2] ?? 0
        
        return level1 > level2
    }
    
    private func getBadgeNumber(for state: ThermalState) -> NSNumber {
        switch state {
        case .normal:
            return 0
        case .fair:
            return 1
        case .serious:
            return 2
        case .critical:
            return 3
        }
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    // MARK: - 清除所有通知
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("NotificationManager: 已清除所有通知")
    }
    
    // MARK: - 清除应用角标
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // 应用在前台时收到通知的处理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 即使应用在前台也显示通知
        completionHandler([.alert, .sound, .badge])
    }
    
    // 用户点击通知的处理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "test":
                print("NotificationManager: 用户点击了测试通知")
                // 可以在这里添加特定的处理逻辑
                
            case "thermal_change":
                if let currentState = userInfo["current_state"] as? String,
                   let isHeatingUp = userInfo["is_heating_up"] as? Bool {
                    print("NotificationManager: 用户点击了热度变化通知 - 当前状态: \(currentState), 升温: \(isHeatingUp)")
                    // 可以在这里添加导航到特定页面的逻辑
                }
                
            default:
                print("NotificationManager: 收到未知类型的通知点击")
            }
        }
        
        completionHandler()
    }
}
