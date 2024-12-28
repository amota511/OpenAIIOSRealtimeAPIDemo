import UIKit
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        initIQKeyboardManagerSwift()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = GlobalColors.mainBackground
        
        let gptString = UserDefaults.standard.string(forKey: "GPTSystemString") ?? ""
        if !gptString.isEmpty {
            window?.rootViewController = MainTabBarController()
        } else {
            window?.rootViewController = OnboardingViewController()
        }

        window?.makeKeyAndVisible()
        
        return true
    }

    //MARK: Third SDK---IQKeyboardManager
    func initIQKeyboardManagerSwift(){
        IQKeyboardManager.shared.enable = true
    }

}
