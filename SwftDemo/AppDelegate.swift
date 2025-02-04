import UIKit
import IQKeyboardManagerSwift
import StoreKit
import RevenueCat

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        initIQKeyboardManagerSwift()
        
        Purchases.configure(withAPIKey: "appl_yNrrltRysQlLBFkWMcIeaNwEwsC")
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = GlobalColors.mainBackground
        
        Task {
            let subscriptionIsActive = await isSubscriptionActive()
            
            DispatchQueue.main.async {
                if subscriptionIsActive {
                    self.window?.rootViewController = MainTabBarController()
                } else {
                    self.window?.rootViewController = OnboardingViewController()
                }
                self.window?.makeKeyAndVisible()
            }
        }

        return true
    }

    // MARK: Third SDK---IQKeyboardManager
    func initIQKeyboardManagerSwift() {
        IQKeyboardManager.shared.enable = true
    }
    
    // MARK: - Subscription Status Check
    // Checks whether the user has an active subscription, using:
    // - StoreKit 2 if running on iOS 15+, or
    // - StoreKit 1 fallback if iOS < 15.
    private func isSubscriptionActive() async -> Bool {
        if #available(iOS 15.0, *) {
            return await checkSubscriptionStoreKit2()
        } else {
            return await checkSubscriptionStoreKit1()
        }
    }

    // MARK: - StoreKit 2 (iOS 15+)
    @available(iOS 15.0, *)
    private func checkSubscriptionStoreKit2() async -> Bool {
        do {
            // currentEntitlements is an AsyncSequence<VerificationResult<Transaction>>
            let transactionResults = Transaction.currentEntitlements
            
            // 1) Use a for await loop to iterate over the async sequence
            for await verificationResult in transactionResults {
                // 2) If it's verified, check its properties
                if case let .verified(tx) = verificationResult {
                    let meetsProductID = (tx.productID == "monthly_20_v1")
                    let notRevoked     = (tx.revocationDate == nil)
                    let notUpgraded    = (tx.isUpgraded == false)
                    
                    if meetsProductID && notRevoked && notUpgraded {
                        return true
                    }
                }
            }
            
            // 3) No active subscription found
            return false
            
        } catch {
            print("StoreKit 2 error: \(error)")
            return false
        }
    }

    // MARK: - StoreKit 1 (iOS < 15)
    // Example uses SKReceiptRefreshRequest to refresh the App Store receipt,
    // then parse it (locally or via server) to check for active subscriptions.
    private func checkSubscriptionStoreKit1() async -> Bool {
        return await withCheckedContinuation { continuation in
            // 1) Check if we already have a receipt. If not, we'll request one.
            guard let receiptURL = Bundle.main.appStoreReceiptURL,
                  FileManager.default.fileExists(atPath: receiptURL.path) else {
                // 2) Refresh the receipt
                let request = SKReceiptRefreshRequest()
                request.delegate = self
                storeKit1RefreshCompletion = { isActive in
                    continuation.resume(returning: isActive)
                }
                request.start()
                return
            }
            
            // 3) If we already have a receipt, check it to see if monthly_20_v1 is active.
            let active = storeKit1ReceiptContainsActiveSubscription(for: "monthly_20_v1")
            continuation.resume(returning: active)
        }
    }
    
    // Delegate-based completion for the SKReceiptRefreshRequest
    private var storeKit1RefreshCompletion: ((Bool) -> Void)?

    // Helper to parse the local receipt to see if "monthly_20_v1" is active
    // In a production setup, you would do server-side or local receipt validation.
    private func storeKit1ReceiptContainsActiveSubscription(for productId: String) -> Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            return false
        }
        // TODO: Parse or send receiptData to your server to check if subscription is active
        // This is just a placeholder:
        print("StoreKit 1 receipt data size: \(receiptData.count) bytes")
        return false
    }
}

// MARK: - SKRequestDelegate for StoreKit 1
extension AppDelegate: SKRequestDelegate {

    public func requestDidFinish(_ request: SKRequest) {
        // If we were refreshing a receipt, check it now
        if let refreshRequest = request as? SKReceiptRefreshRequest,
           let completion = storeKit1RefreshCompletion {
            let active = storeKit1ReceiptContainsActiveSubscription(for: "monthly_20_v1")
            completion(active)
            storeKit1RefreshCompletion = nil
        }
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        // Receipt refresh failed, continue with false
        if request is SKReceiptRefreshRequest,
           let completion = storeKit1RefreshCompletion {
            print("StoreKit 1 refresh request failed: \(error.localizedDescription)")
            completion(false)
            storeKit1RefreshCompletion = nil
        }
    }
}
