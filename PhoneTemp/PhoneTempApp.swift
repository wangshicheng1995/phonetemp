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
            if isPreviewEnvironment {
                ContentView(isPreview: true)
            } else {
                ContentView()
                    .onAppear {
                        setupAppEnvironment()
                    }
            }
        }
        .modelContainer(sharedModelContainer)
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
