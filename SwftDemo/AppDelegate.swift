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
        Purchases.shared.restorePurchases()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = GlobalColors.mainBackground
        
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                
                // Check specifically for subscription_monthly_v1
                let hasActiveSubscription = customerInfo.activeSubscriptions.contains("monthly_sub_20_v1")
                print("Active subscriptions: \(customerInfo.activeSubscriptions)")
                print("Monthly subscription active: \(hasActiveSubscription)")
                
                DispatchQueue.main.async {
                    if hasActiveSubscription {
                        self.window?.rootViewController = MainTabBarController()
                    } else {
                        self.window?.rootViewController = OnboardingViewController()
                    }
                    self.window?.makeKeyAndVisible()
                }
            } catch {
                print("Failed to fetch subscription status: \(error)")
                // If there's an error checking subscription status, 
                // default to showing the onboarding experience
                DispatchQueue.main.async {
                    self.window?.rootViewController = OnboardingViewController()
                    self.window?.makeKeyAndVisible()
                }
            }
        }

        return true
    }

    // MARK: Third SDK---IQKeyboardManager
    func initIQKeyboardManagerSwift() {
        IQKeyboardManager.shared.enable = true
    }
}
