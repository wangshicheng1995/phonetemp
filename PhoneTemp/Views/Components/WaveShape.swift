//
//  WaveShape.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/29.
//


//
//  WaveShape.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/29.
//

import SwiftUI

// MARK: - 海浪形状
struct WaveShape: Shape {
    var offset: Angle
    var percent: Double
    var waveIntensity: Double
    
    var animatableData: Double {
        get { offset.degrees }
        set { offset = Angle(degrees: newValue) }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let lowestWave = 0.02
        let highestWave = 1.00
        
        let newPercent = lowestWave + (highestWave - lowestWave) * (percent / 100)
        let waveHeight = waveIntensity * rect.height
        let yOffset = CGFloat(1 - newPercent) * (rect.height - 4 * waveHeight) + 2 * waveHeight
        let startAngle = offset
        let endAngle = offset + Angle(degrees: 360 + 10)
        
        path.move(to: CGPoint(x: 0, y: yOffset + waveHeight * CGFloat(sin(offset.radians))))
        
        for angle in stride(from: startAngle.degrees, through: endAngle.degrees, by: 3) {
            let x = CGFloat((angle - startAngle.degrees) / 360) * rect.width
            let waveY = yOffset + waveHeight * CGFloat(sin(Angle(degrees: angle).radians))
            path.addLine(to: CGPoint(x: x, y: waveY))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - 海浪背景形状（用于创建多层效果）
struct WaveBackgroundShape: Shape {
    var offset: Angle
    var percent: Double
    var waveIntensity: Double
    var phaseShift: Double // 相位偏移，用于创建多层海浪效果
    
    var animatableData: Double {
        get { offset.degrees }
        set { offset = Angle(degrees: newValue) }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let lowestWave = 0.02
        let highestWave = 1.00
        
        let newPercent = lowestWave + (highestWave - lowestWave) * (percent / 100)
        let waveHeight = waveIntensity * rect.height * 0.7 // 背景波浪稍小
        let yOffset = CGFloat(1 - newPercent) * (rect.height - 4 * waveHeight) + 2 * waveHeight
        let startAngle = offset + Angle(degrees: phaseShift)
        let endAngle = startAngle + Angle(degrees: 360 + 10)
        
        path.move(to: CGPoint(x: 0, y: yOffset + waveHeight * CGFloat(sin(startAngle.radians))))
        
        for angle in stride(from: startAngle.degrees, through: endAngle.degrees, by: 3) {
            let x = CGFloat((angle - startAngle.degrees) / 360) * rect.width
            let waveY = yOffset + waveHeight * CGFloat(sin(Angle(degrees: angle).radians))
            path.addLine(to: CGPoint(x: x, y: waveY))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}