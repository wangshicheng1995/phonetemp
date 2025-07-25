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
    
    // 单例
    static let shared = StoreKitManager()
    
    private init() {
        // 启动事务监听
        updateListenerTask = listenForTransactions()
        
        // 初始化时检查购买状态
        Task {
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - 获取商品信息
    func fetchProducts() async {
        guard !isLoading else { return }
        
        isLoading = true
        lastError = nil
        
        do {
            let storeProducts = try await Product.products(for: productIdentifiers)
            products = storeProducts.sorted { $0.price < $1.price }
            print("StoreKitManager: 成功获取 \(products.count) 个商品")
        } catch {
            lastError = .networkError
            print("StoreKitManager: 获取商品失败 - \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - 购买商品
    func purchase(_ product: Product) async -> Bool {
        guard !isLoading else { return false }
        
        isLoading = true
        lastError = nil
        
        do {
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
    
    // MARK: - 恢复购买
    func restorePurchases() async {
        isLoading = true
        lastError = nil
        
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
            print("StoreKitManager: 恢复购买完成")
        } catch {
            lastError = .networkError
            print("StoreKitManager: 恢复购买失败 - \(error.localizedDescription)")
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
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                    print("StoreKitManager: 事务更新完成")
                } catch {
                    print("StoreKitManager: 事务验证失败 - \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 更新客户商品状态
    private func updateCustomerProductStatus() async {
        var purchasedProducts: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            // 检查交易是否未被撤销
            if transaction.revocationDate == nil {
                purchasedProducts.insert(transaction.productID)
            }
        }
        
        DispatchQueue.main.async {
            self.purchasedProductIDs = purchasedProducts
            self.isPremiumUnlocked = purchasedProducts.contains(ProductType.premium.rawValue)
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
        isPremiumUnlocked = true
        purchasedProductIDs.insert(ProductType.premium.rawValue)
        print("StoreKitManager: 模拟购买完成")
    }
    
    func resetPurchases() {
        isPremiumUnlocked = false
        purchasedProductIDs.removeAll()
        print("StoreKitManager: 重置购买状态")
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

// MARK: - 通用 StoreKit 包装器
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
            .assign(to: &$isPremiumUnlocked)
        
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
        if #available(iOS 15.0, *), let manager = modernManager {
            await manager.restorePurchases()
        } else if let manager = legacyManager {
            await manager.restorePurchases()
        }
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
