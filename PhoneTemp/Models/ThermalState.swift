//
//  ThermalState.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import SwiftUI
import UIKit

// MARK: - 热状态枚举
enum ThermalState: String, CaseIterable {
    case normal = "正常"
    case fair = "轻微发热"
    case serious = "中度发热"
    case critical = "严重发热"
    
    // 根据热状态返回对应的颜色方案
    var colorScheme: ThermalColorScheme {
        switch self {
        case .normal:
            return ThermalColorScheme.normal
        case .fair:
            return ThermalColorScheme.fair
        case .serious:
            return ThermalColorScheme.serious
        case .critical:
            return ThermalColorScheme.critical
        }
    }
}

// MARK: - 热状态颜色方案
struct ThermalColorScheme {
    let outerGlow: [Color]
    let middleGlow: [Color]
    let innerStroke: [Color]
    let coreStroke: [Color]
    let innerFill: [Color]
    
    static let normal = ThermalColorScheme(
        outerGlow: [
            Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.3),
            Color(red: 0.1, green: 0.6, blue: 0.3).opacity(0.2),
            Color(red: 0.05, green: 0.4, blue: 0.2).opacity(0.1)
        ],
        middleGlow: [
            Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.5),
            Color(red: 0.1, green: 0.5, blue: 0.3).opacity(0.3)
        ],
        innerStroke: [
            Color(red: 0.4, green: 0.9, blue: 0.6),
            Color(red: 0.2, green: 0.7, blue: 0.4),
            Color(red: 0.1, green: 0.5, blue: 0.3),
            Color(red: 0.05, green: 0.3, blue: 0.2)
        ],
        coreStroke: [
            Color(red: 0.5, green: 0.95, blue: 0.7),
            Color(red: 0.3, green: 0.8, blue: 0.5),
            Color(red: 0.1, green: 0.6, blue: 0.3)
        ],
        innerFill: [
            Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1),
            Color(red: 0.05, green: 0.3, blue: 0.2).opacity(0.05)
        ]
    )
    
    static let fair = ThermalColorScheme(
        outerGlow: [
            Color(red: 0.8, green: 0.8, blue: 0.2).opacity(0.3),
            Color(red: 0.6, green: 0.6, blue: 0.1).opacity(0.2),
            Color(red: 0.4, green: 0.4, blue: 0.05).opacity(0.1)
        ],
        middleGlow: [
            Color(red: 0.8, green: 0.8, blue: 0.3).opacity(0.5),
            Color(red: 0.5, green: 0.5, blue: 0.1).opacity(0.3)
        ],
        innerStroke: [
            Color(red: 0.9, green: 0.9, blue: 0.4),
            Color(red: 0.7, green: 0.7, blue: 0.2),
            Color(red: 0.5, green: 0.5, blue: 0.1),
            Color(red: 0.3, green: 0.3, blue: 0.05)
        ],
        coreStroke: [
            Color(red: 0.95, green: 0.95, blue: 0.5),
            Color(red: 0.8, green: 0.8, blue: 0.3),
            Color(red: 0.6, green: 0.6, blue: 0.1)
        ],
        innerFill: [
            Color(red: 0.8, green: 0.8, blue: 0.2).opacity(0.1),
            Color(red: 0.3, green: 0.3, blue: 0.05).opacity(0.05)
        ]
    )
    
    static let serious = ThermalColorScheme(
        outerGlow: [
            Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.3),
            Color(red: 0.8, green: 0.4, blue: 0.1).opacity(0.2),
            Color(red: 0.5, green: 0.2, blue: 0.05).opacity(0.1)
        ],
        middleGlow: [
            Color(red: 1.0, green: 0.6, blue: 0.3).opacity(0.5),
            Color(red: 0.7, green: 0.3, blue: 0.1).opacity(0.3)
        ],
        innerStroke: [
            Color(red: 1.0, green: 0.7, blue: 0.4),
            Color(red: 0.9, green: 0.5, blue: 0.2),
            Color(red: 0.7, green: 0.3, blue: 0.1),
            Color(red: 0.5, green: 0.2, blue: 0.05)
        ],
        coreStroke: [
            Color(red: 1.0, green: 0.8, blue: 0.5),
            Color(red: 0.95, green: 0.6, blue: 0.3),
            Color(red: 0.8, green: 0.4, blue: 0.1)
        ],
        innerFill: [
            Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.1),
            Color(red: 0.4, green: 0.2, blue: 0.05).opacity(0.05)
        ]
    )
    
    static let critical = ThermalColorScheme(
        outerGlow: [
            Color(red: 1.0, green: 0.2, blue: 0.2).opacity(0.3),
            Color(red: 0.8, green: 0.1, blue: 0.1).opacity(0.2),
            Color(red: 0.5, green: 0.05, blue: 0.05).opacity(0.1)
        ],
        middleGlow: [
            Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.5),
            Color(red: 0.7, green: 0.1, blue: 0.1).opacity(0.3)
        ],
        innerStroke: [
            Color(red: 1.0, green: 0.4, blue: 0.4),
            Color(red: 0.9, green: 0.2, blue: 0.2),
            Color(red: 0.7, green: 0.1, blue: 0.1),
            Color(red: 0.5, green: 0.05, blue: 0.05)
        ],
        coreStroke: [
            Color(red: 1.0, green: 0.5, blue: 0.5),
            Color(red: 0.95, green: 0.3, blue: 0.3),
            Color(red: 0.8, green: 0.1, blue: 0.1)
        ],
        innerFill: [
            Color(red: 1.0, green: 0.2, blue: 0.2).opacity(0.1),
            Color(red: 0.4, green: 0.05, blue: 0.05).opacity(0.05)
        ]
    )
}
