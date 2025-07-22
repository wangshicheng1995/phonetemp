//
//  ThermalDisplayView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//


//
//  ThermalDisplayView.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import SwiftUI

// MARK: - 热状态显示视图
struct ThermalDisplayView: View {
    let thermalState: ThermalState
    let isCurrentState: Bool
    @State private var glowIntensity: Double = 0.5
    
    var body: some View {
        ZStack {
            let colorScheme = thermalState.colorScheme
            
            // 辅助线
//            Rectangle()
//                .fill(Color.red)
//                .frame(width: 2, height: UIScreen.main.bounds.height)
//                .opacity(0.5)
//            
//            Rectangle()
//                .fill(Color.blue)
//                .frame(width: UIScreen.main.bounds.width, height: 2)
//                .opacity(0.5)

            
            // 最外层模糊光晕
            RoundedRectangle(cornerRadius: 150)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: colorScheme.outerGlow),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 280, height: 480)
                .blur(radius: 60)
                .opacity(glowIntensity * 0.8)
            
            // 中层光晕
            RoundedRectangle(cornerRadius: 140)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: colorScheme.middleGlow),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 260, height: 460)
                .blur(radius: 40)
                .opacity(glowIntensity)
            
            // 内层边框光晕
            RoundedRectangle(cornerRadius: 130)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: colorScheme.innerStroke[0], location: 0.0),
                            .init(color: colorScheme.innerStroke[1], location: 0.3),
                            .init(color: colorScheme.innerStroke[2], location: 0.7),
                            .init(color: colorScheme.innerStroke[3], location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 20
                )
                .frame(width: 200, height: 440)
                .blur(radius: 15)
                .opacity(glowIntensity * 1.2)
            
            // 核心发光边框
            RoundedRectangle(cornerRadius: 125)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: colorScheme.coreStroke),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 8
                )
                .frame(width: 220, height: 420)
                .blur(radius: 3)
                .opacity(glowIntensity * 1.5)
            
            // 最内层清晰边框
            RoundedRectangle(cornerRadius: 120)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorScheme.coreStroke[0].opacity(0.9),
                            colorScheme.coreStroke[1].opacity(0.7)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .frame(width: 210, height: 410)
                .opacity(glowIntensity * 1.8)
            
            // 内部填充 - 很淡的渐变
            RoundedRectangle(cornerRadius: 120)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: colorScheme.innerFill),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 210, height: 410)
            
            // 热状态文本显示
            VStack(spacing: 20) {
                Spacer()
                
                Text(thermalState.rawValue)
                    .foregroundColor(.white)
                    .font(.system(size: 28, weight: .bold))
                    .shadow(color: colorScheme.coreStroke[0], radius: 10)
                
                Text(isCurrentState ? "当前状态" : "预览模式")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
            }
        }
        .onAppear {
            // 呼吸动画
            withAnimation(
                Animation.easeInOut(duration: 3.5)
                    .repeatForever(autoreverses: true)
            ) {
                glowIntensity = 1.0
            }
        }
    }
}
