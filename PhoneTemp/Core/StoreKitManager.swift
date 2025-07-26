//
//  StoreKitManager.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/25.
//

import Foundation
import StoreKit
import Combine

// MARK: - StoreKit 错误类型
enum StoreKitError: Error, LocalizedError {
    case failedVerification
    case userCancelled
    case networkError
    case systemError
    case productNotFound
    case notSupported
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "购买验证失败"
        case .userCancelled:
            return "用户取消购买"
        case .networkError:
            return "网络连接错误"
        case .systemError:
            return "系统错误"
        case .productNotFound:
            return "商品不存在"
        case .notSupported:
            return "当前 iOS 版本不支持此功能"
        }
    }
}

// MARK: - 商品类型
enum ProductType: String, CaseIterable {
    case premium = "com.echo.PhoneTemp.premium"
    
    var displayName: String {
        switch self {
        case .premium:
            return "永久使用"
        }
    }
    
    var description: String {
        switch self {
        case .premium:
            return "解锁所有功能，永久使用手机温度"
        }
    }
}

// MARK: - StoreKit 管理器
@available(iOS 15.0, *)
@MainActor
class StoreKitManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: StoreKitError?
    
    // 购买状态
    @Published var isPremiumUnlocked = false
    
    private var updateListenerTask: Task<Void, Error>?
    private let productIdentifiers = ProductType.allCases.map { $0.rawValue }
    
    // 添加测试环境的购买状态持久化
    #if DEBUG
    private let testPurchaseKey = "TestPurchaseStatus"
    private var isTestEnvironment: Bool {
        // 检查是否在使用 StoreKit 配置文件
        return true // 在测试环境中始终为 true
    }
    #endif
    
    // 单例
    static let shared = StoreKitManager()
    
    private init() {
        #if DEBUG
        // 在测试环境中先加载本地购买状态
        loadTestPurchaseStatus()
        #endif
        
        // 启动事务监听
        updateListenerTask = listenForTransactions()
        
        // 初始化时检查购买状态
        Task {
            await updateCustomerProductStatus()
            await fetchProducts() // 启动时就获取商品
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    #if DEBUG
    // MARK: - 测试环境购买状态管理
    private func loadTestPurchaseStatus() {
        let testPurchased = UserDefaults.standard.bool(forKey: testPurchaseKey)
        if testPurchased {
            isPremiumUnlocked = true
            purchasedProductIDs.insert(ProductType.premium.rawValue)
            print("StoreKitManager: 加载测试购买状态 - Premium: \(isPremiumUnlocked)")
        }
    }
    
    private func saveTestPurchaseStatus() {
        UserDefaults.standard.set(isPremiumUnlocked, forKey: testPurchaseKey)
        print("StoreKitManager: 保存测试购买状态 - Premium: \(isPremiumUnlocked)")
    }
    #endif
    
    // MARK: - 获取商品信息
    func fetchProducts() async {
        guard !isLoading else { return }
        
        isLoading = true
        lastError = nil
        
        do {
            print("StoreKitManager: 开始获取商品，商品ID: \(productIdentifiers)")
            let storeProducts = try await Product.products(for: productIdentifiers)
            products = storeProducts.sorted { $0.price < $1.price }
            print("StoreKitManager: 成功获取 \(products.count) 个商品")
            
            // 打印商品详情用于调试
            for product in products {
                print("StoreKitManager: 商品 - ID: \(product.id), 名称: \(product.displayName), 价格: \(product.displayPrice)")
            }
        } catch {
            lastError = .networkError
            print("StoreKitManager: 获取商品失败 - \(error.localizedDescription)")
            print("StoreKitManager: 错误详情 - \(error)")
            
            // 根据错误类型提供不同的调试信息
            if error.localizedDescription.contains("invalid") || error.localizedDescription.contains("not found") {
                print("StoreKitManager: 沙盒环境可能的问题：")
                print("  1. 检查 App Store Connect 中是否创建了商品 ID: \(productIdentifiers)")
                print("  2. 确保商品状态为 '准备提交' 或更高状态")
                print("  3. 验证 Bundle ID 是否与 App Store Connect 中的应用匹配")
                print("  4. 检查是否正确登录了沙盒测试账户")
                print("  5. 确认网络连接正常")
            } else {
                print("StoreKitManager: 其他可能问题：")
                print("  1. 网络连接问题")
                print("  2. 沙盒服务器暂时不可用")
                print("  3. Apple ID 沙盒账户问题")
            }
        }
        
        isLoading = false
    }
    
    // MARK: - 购买商品
    func purchase(_ product: Product) async -> Bool {
        guard !isLoading else { return false }
        
        isLoading = true
        lastError = nil
        
        do {
            print("StoreKitManager: 开始购买商品 - \(product.id)")
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateCustomerProductStatus()
                await transaction.finish()
                
                print("StoreKitManager: 购买成功 - \(product.id)")
                isLoading = false
                return true
                
            case .userCancelled:
                lastError = .userCancelled
                print("StoreKitManager: 用户取消购买")
                
            case .pending:
                print("StoreKitManager: 购买等待中（可能需要家长批准）")
                
            @unknown default:
                lastError = .systemError
                print("StoreKitManager: 未知购买结果")
            }
        } catch {
            lastError = .systemError
            print("StoreKitManager: 购买失败 - \(error.localizedDescription)")
        }
        
        isLoading = false
        return false
    }
    
    // MARK: - 恢复购买（修复版）
    func restorePurchases() async {
        isLoading = true
        lastError = nil
        
        print("StoreKitManager: 开始恢复购买...")
        
        #if DEBUG
        if isTestEnvironment {
            // 在测试环境中，优先检查本地保存的购买状态
            let testPurchased = UserDefaults.standard.bool(forKey: testPurchaseKey)
            if testPurchased {
                isPremiumUnlocked = true
                purchasedProductIDs.insert(ProductType.premium.rawValue)
                print("StoreKitManager: 测试环境恢复购买成功")
                print("StoreKitManager: 当前 Premium 状态: \(isPremiumUnlocked)")
                isLoading = false
                return
            }
        }
        #endif
        
        do {
            // 先尝试同步 App Store 数据
            try await AppStore.sync()
            print("StoreKitManager: App Store 同步完成")
            
            // 等待一小段时间让系统处理
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            
            // 保存同步前的状态
            let previousState = isPremiumUnlocked
            
            // 更新本地购买状态
            await updateCustomerProductStatus()
            
            #if DEBUG
            // 如果在测试环境中状态被重置，但之前有购买记录，则恢复状态
            if isTestEnvironment && !isPremiumUnlocked && previousState {
                let testPurchased = UserDefaults.standard.bool(forKey: testPurchaseKey)
                if testPurchased {
                    isPremiumUnlocked = true
                    purchasedProductIDs.insert(ProductType.premium.rawValue)
                    print("StoreKitManager: 测试环境中恢复之前的购买状态")
                }
            }
            #endif
            
            print("StoreKitManager: 恢复购买完成")
            print("StoreKitManager: 当前 Premium 状态: \(isPremiumUnlocked)")
            print("StoreKitManager: 已购买商品: \(purchasedProductIDs)")
            
        } catch {
            lastError = .networkError
            print("StoreKitManager: 恢复购买失败 - \(error.localizedDescription)")
            
            #if DEBUG
            // 即使同步失败，也尝试恢复测试环境的购买状态
            if isTestEnvironment {
                let testPurchased = UserDefaults.standard.bool(forKey: testPurchaseKey)
                if testPurchased {
                    isPremiumUnlocked = true
                    purchasedProductIDs.insert(ProductType.premium.rawValue)
                    print("StoreKitManager: 同步失败，但从本地恢复了测试购买状态")
                }
            } else {
                // 生产环境中仍然尝试更新本地状态
                await updateCustomerProductStatus()
            }
            #else
            // 生产环境中仍然尝试更新本地状态
            await updateCustomerProductStatus()
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - 检查验证结果
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - 监听事务更新
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    print("StoreKitManager: 收到事务更新 - \(transaction.productID)")
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                    print("StoreKitManager: 事务更新完成")
                } catch {
                    print("StoreKitManager: 事务验证失败 - \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 更新客户商品状态（改进版）
    private func updateCustomerProductStatus() async {
        var purchasedProducts: Set<String> = []
        var transactionCount = 0
        
        print("StoreKitManager: 开始检查当前权益...")
        
        for await result in Transaction.currentEntitlements {
            transactionCount += 1
            
            guard case .verified(let transaction) = result else {
                print("StoreKitManager: 跳过未验证的事务")
                continue
            }
            
            print("StoreKitManager: 检查事务 - 商品ID: \(transaction.productID), 撤销日期: \(transaction.revocationDate?.description ?? "无")")
            
            // 检查交易是否未被撤销
            if transaction.revocationDate == nil {
                purchasedProducts.insert(transaction.productID)
                print("StoreKitManager: 添加有效购买 - \(transaction.productID)")
            }
        }
        
        print("StoreKitManager: 共检查 \(transactionCount) 个事务，有效购买 \(purchasedProducts.count) 个")
        
        #if DEBUG
        // 在测试环境中，如果没有找到有效事务但本地有购买记录，则使用本地记录
        if isTestEnvironment && purchasedProducts.isEmpty {
            let testPurchased = UserDefaults.standard.bool(forKey: testPurchaseKey)
            if testPurchased {
                purchasedProducts.insert(ProductType.premium.rawValue)
                print("StoreKitManager: 测试环境中使用本地购买记录")
            }
        }
        #endif
        
        let wasPremiumUnlocked = isPremiumUnlocked
        
        DispatchQueue.main.async {
            self.purchasedProductIDs = purchasedProducts
            self.isPremiumUnlocked = purchasedProducts.contains(ProductType.premium.rawValue)
            
            if wasPremiumUnlocked != self.isPremiumUnlocked {
                print("StoreKitManager: Premium 状态发生变化 - 从 \(wasPremiumUnlocked) 到 \(self.isPremiumUnlocked)")
            }
            
            print("StoreKitManager: 更新购买状态 - Premium: \(self.isPremiumUnlocked)")
        }
    }
    
    // MARK: - 便利方法
    func getPremiumProduct() -> Product? {
        return products.first { $0.id == ProductType.premium.rawValue }
    }
    
    func clearError() {
        lastError = nil
    }
    
    // MARK: - 开发调试方法
    #if DEBUG
    func simulatePurchase() {
        print("StoreKitManager: 模拟购买开始")
        DispatchQueue.main.async {
            self.isPremiumUnlocked = true
            self.purchasedProductIDs.insert(ProductType.premium.rawValue)
            self.saveTestPurchaseStatus()
        }
        print("StoreKitManager: 模拟购买完成")
    }
    
    func resetPurchases() {
        print("StoreKitManager: 重置购买状态开始")
        UserDefaults.standard.removeObject(forKey: testPurchaseKey)
        DispatchQueue.main.async {
            self.isPremiumUnlocked = false
            self.purchasedProductIDs.removeAll()
        }
        print("StoreKitManager: 重置购买状态完成")
    }
    #endif
}

// MARK: - iOS 14 及更早版本的兼容层
@available(iOS, deprecated: 15.0, message: "请升级到 iOS 15+ 以获得完整功能")
@MainActor
class LegacyStoreKitManager: ObservableObject {
    @Published var isPremiumUnlocked = false
    @Published var isLoading = false
    @Published var lastError: StoreKitError?
    
    static let shared = LegacyStoreKitManager()
    
    private init() {}
    
    func fetchProducts() async {
        // 在旧版本中不支持 StoreKit 2
        lastError = .notSupported
    }
    
    func purchase(_ product: Any) async -> Bool {
        lastError = .notSupported
        return false
    }
    
    func restorePurchases() async {
        lastError = .notSupported
    }
    
    func getPremiumProduct() -> Any? {
        return nil
    }
    
    func clearError() {
        lastError = nil
    }
    
    #if DEBUG
    func simulatePurchase() {
        isPremiumUnlocked = true
    }
    
    func resetPurchases() {
        isPremiumUnlocked = false
    }
    #endif
}

// MARK: - 通用 StoreKit 包装器（改进版）
@MainActor
class UniversalStoreKitManager: ObservableObject {
    @Published var isPremiumUnlocked = false
    @Published var isLoading = false
    @Published var lastError: StoreKitError?
    
    private var modernManager: StoreKitManager?
    private var legacyManager: LegacyStoreKitManager?
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = UniversalStoreKitManager()
    
    private init() {
        if #available(iOS 15.0, *) {
            modernManager = StoreKitManager.shared
            bindModernManager()
        } else {
            legacyManager = LegacyStoreKitManager.shared
            bindLegacyManager()
        }
    }
    
    // MARK: - 绑定现代管理器
    @available(iOS 15.0, *)
    private func bindModernManager() {
        guard let manager = modernManager else { return }
        
        manager.$isPremiumUnlocked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPremium in
                if self?.isPremiumUnlocked != isPremium {
                    print("UniversalStoreKitManager: Premium 状态更新 - \(isPremium)")
                }
                self?.isPremiumUnlocked = isPremium
            }
            .store(in: &cancellables)
        
        manager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        manager.$lastError
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastError)
    }
    
    // MARK: - 绑定传统管理器
    private func bindLegacyManager() {
        guard let manager = legacyManager else { return }
        
        manager.$isPremiumUnlocked
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPremiumUnlocked)
        
        manager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        manager.$lastError
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastError)
    }
    
    // MARK: - 公共接口方法
    func fetchProducts() async {
        if #available(iOS 15.0, *), let manager = modernManager {
            await manager.fetchProducts()
        } else if let manager = legacyManager {
            await manager.fetchProducts()
        }
    }
    
    func purchase(_ product: Any) async -> Bool {
        if #available(iOS 15.0, *),
           let manager = modernManager,
           let storeKitProduct = product as? Product {
            return await manager.purchase(storeKitProduct)
        } else if let manager = legacyManager {
            return await manager.purchase(product)
        }
        return false
    }
    
    func restorePurchases() async {
        print("UniversalStoreKitManager: 开始恢复购买...")
        if #available(iOS 15.0, *), let manager = modernManager {
            await manager.restorePurchases()
        } else if let manager = legacyManager {
            await manager.restorePurchases()
        }
        print("UniversalStoreKitManager: 恢复购买完成")
    }
    
    func getPremiumProduct() -> Any? {
        if #available(iOS 15.0, *), let manager = modernManager {
            return manager.getPremiumProduct()
        } else if let manager = legacyManager {
            return manager.getPremiumProduct()
        }
        return nil
    }
    
    func clearError() {
        if #available(iOS 15.0, *), let manager = modernManager {
            manager.clearError()
        } else if let manager = legacyManager {
            manager.clearError()
        }
    }
    
    #if DEBUG
    func simulatePurchase() {
        if #available(iOS 15.0, *), let manager = modernManager {
            manager.simulatePurchase()
        } else if let manager = legacyManager {
            manager.simulatePurchase()
        }
    }
    
    func resetPurchases() {
        if #available(iOS 15.0, *), let manager = modernManager {
            manager.resetPurchases()
        } else if let manager = legacyManager {
            manager.resetPurchases()
        }
    }
    #endif
}

// MARK: - 扩展：产品信息格式化
@available(iOS 15.0, *)
extension Product {
    var localizedPrice: String {
        return priceFormatStyle.format(price)
    }
}
