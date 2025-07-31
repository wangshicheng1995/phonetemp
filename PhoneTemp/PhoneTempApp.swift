//
//  PhoneTempApp.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/12.
//

import SwiftUI
import SwiftData

@main
struct PhoneTempApp: App {
    @StateObject private var onboardingManager = OnboardingManager()
    
    // 检查是否在 Preview 环境中
    private var isPreviewEnvironment: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ||
               ProcessInfo.processInfo.arguments.contains("--preview")
    }
    
    // 简化的 ModelContainer - 仅用于保持兼容性
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])  // 移除 TemperatureRecord，使用简化存储
        
        do {
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,  // 强制使用内存存储
                allowsSave: true,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("PhoneTempApp: Simplified ModelContainer created successfully")
            return container
        } catch {
            print("PhoneTempApp: Error creating ModelContainer: \(error.localizedDescription)")
            // 创建一个最小的容器
            do {
                let minimalSchema = Schema([])
                let minimalConfig = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: minimalSchema, configurations: [minimalConfig])
            } catch {
                fatalError("Could not create any ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if isPreviewEnvironment {
                    ContentView(isPreview: true)
                } else {
                    mainAppView
                }
            }
            .onAppear {
                // 定期检查试用状态
                if !isPreviewEnvironment {
                    Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
                        DispatchQueue.main.async {
                            onboardingManager.refreshTrialStatus()
                        }
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - 主应用视图
    @ViewBuilder
    private var mainAppView: some View {
        if !onboardingManager.isOnboardingComplete {
            // 显示引导页面
            OnboardingView(isOnboardingComplete: $onboardingManager.isOnboardingComplete)
                .environmentObject(onboardingManager)
        } else if onboardingManager.canUseApp {
            // 已完成引导且有使用权限，显示主应用
            ContentView()
                .onAppear {
                    setupAppEnvironment()
                }
        } else {
            // 已完成引导但无使用权限，显示付费墙
            PaywallView()
                .environmentObject(onboardingManager)
        }
    }
    
    // MARK: - 应用环境设置
    private func setupAppEnvironment() {
        // 禁用一些可能导致 XPC 错误的功能
        if #available(iOS 18.0, *) {
            // iOS 18 特定的设置
            print("PhoneTempApp: Running on iOS 18+")
        }
        
        // 设置全局错误处理
        NSSetUncaughtExceptionHandler { exception in
            print("PhoneTempApp: Uncaught exception: \(exception)")
        }
    }
}

// MARK: - 付费墙视图
struct PaywallView: View {
    @EnvironmentObject var onboardingManager: OnboardingManager
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.08, blue: 0.08)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                // 标题
                VStack(spacing: 16) {
                    Image("temp_icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                    
                    Text("试用期已结束")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("感谢您试用手机温度！\n继续使用请购买完整版本。")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                // 购买按钮
                VStack(spacing: 12) {
                    Button(action: {
                        // 处理购买
                        handlePurchase()
                    }) {
                        Text("¥3.00 永久使用")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    
                    // 恢复购买按钮
                    Button("恢复购买") {
                        onboardingManager.restorePurchase()
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func handlePurchase() {
        // TODO: 实现购买逻辑
        onboardingManager.completePurchase()
    }
}
