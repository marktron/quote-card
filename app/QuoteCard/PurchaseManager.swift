//
//  PurchaseManager.swift
//  QuoteCard
//
//  Manages in-app purchases using StoreKit 2
//

import Foundation
import StoreKit
import Combine

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    // Product identifier for unlocking all themes
    static let allThemesProductId = "com.quotecard.allthemes"

    // App Group identifier for sharing purchase state with extension
    static let appGroupId = "group.com.quotecard.shared"

    @Published private(set) var allThemesUnlocked: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress: Bool = false

    private var transactionListener: Task<Void, Error>?

    private init() {
        // Load cached purchase state
        loadPurchaseState()

        // Start listening for transactions
        transactionListener = listenForTransactions()

        // Load products and check entitlements
        Task {
            await loadProducts()
            await updatePurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.allThemesProductId])
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    var allThemesProduct: Product? {
        products.first { $0.id == Self.allThemesProductId }
    }

    // MARK: - Purchase

    func purchase() async throws {
        guard let product = allThemesProduct else {
            throw PurchaseError.productNotFound
        }

        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchaseStatus()

        case .userCancelled:
            throw PurchaseError.userCancelled

        case .pending:
            throw PurchaseError.pending

        @unknown default:
            throw PurchaseError.unknown
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchaseStatus()
    }

    // MARK: - Transaction Handling

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) {
        do {
            let transaction = try checkVerified(result)
            Task {
                await updatePurchaseStatus()
                await transaction.finish()
            }
        } catch {
            print("Transaction verification failed: \(error)")
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Purchase Status

    func updatePurchaseStatus() async {
        var unlocked = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == Self.allThemesProductId {
                    unlocked = true
                    break
                }
            } catch {
                print("Entitlement verification failed: \(error)")
            }
        }

        allThemesUnlocked = unlocked
        savePurchaseState()
    }

    // MARK: - Persistence (App Group for Extension Access)

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupId)
    }

    private func savePurchaseState() {
        sharedDefaults?.set(allThemesUnlocked, forKey: "allThemesUnlocked")

        // Also save to standard defaults as backup
        UserDefaults.standard.set(allThemesUnlocked, forKey: "allThemesUnlocked")
    }

    private func loadPurchaseState() {
        // Try shared defaults first, fall back to standard
        if let shared = sharedDefaults {
            allThemesUnlocked = shared.bool(forKey: "allThemesUnlocked")
        } else {
            allThemesUnlocked = UserDefaults.standard.bool(forKey: "allThemesUnlocked")
        }
    }

    // MARK: - Theme Access

    func isThemeUnlocked(_ theme: Theme) -> Bool {
        // Free themes are always unlocked
        if theme.isFree {
            return true
        }
        // Premium themes require purchase
        return allThemesUnlocked
    }
}

// MARK: - Errors

enum PurchaseError: LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .verificationFailed:
            return "Purchase verification failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
