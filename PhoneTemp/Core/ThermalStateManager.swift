//
//  ThermalStateManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import Foundation
import Combine

// MARK: - 热状态管理器
class ThermalStateManager: ObservableObject {
    @Published var currentThermalState: ThermalState = .normal
    private var timer: Timer?
    
    init() {
        startMonitoring()
        // 监听热状态变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateDidChange),
            name: ProcessInfo.thermalStateDidChangeNotification,
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
    }
    
    // 手动触发更新（用于测试）
    func refreshThermalState() {
        updateThermalState()
    }
}
