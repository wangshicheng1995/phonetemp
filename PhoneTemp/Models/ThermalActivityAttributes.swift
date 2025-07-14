//
//  ThermalActivityAttributes.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import Foundation
import ActivityKit

// MARK: - Live Activity 属性
struct ThermalActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var thermalState: ThermalState
        var lastUpdateTime: Date
        
        init(thermalState: ThermalState) {
            self.thermalState = thermalState
            self.lastUpdateTime = Date()
        }
    }
    
    var startTime: Date
    
    init() {
        self.startTime = Date()
    }
}

// MARK: - ThermalState Codable 扩展
extension ThermalState: Codable {
    
}