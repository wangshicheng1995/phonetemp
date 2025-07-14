//
//  CoolingTipsSheet.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//


//
//  CoolingTipsSheet.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/14.
//

import SwiftUI

// MARK: - 降温Tips Sheet
struct CoolingTipsSheet: View {
    let thermalState: ThermalState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 顶部标题区域
                VStack(spacing: 8) {
                    Text("降温 Tips")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("帮助您的设备快速降温")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // 当前状态显示
                HStack {
                    Circle()
                        .fill(thermalState.colorScheme.coreStroke[0])
                        .frame(width: 12, height: 12)
                    
                    Text("当前状态：\(thermalState.rawValue)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Tips内容区域
                VStack(spacing: 16) {
                    Text("降温建议将在此显示")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // 这里可以根据不同的热状态显示不同的建议
                    // 例如：关闭后台应用、降低屏幕亮度、移除充电器等
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}