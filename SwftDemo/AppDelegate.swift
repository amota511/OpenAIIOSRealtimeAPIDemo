import UIKit
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        initIQKeyboardManagerSwift()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = GlobalColors.mainBackground
        
        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()
        
        return true
    }

    //MARK: Third SDK---IQKeyboardManager
    func initIQKeyboardManagerSwift(){
        IQKeyboardManager.shared.enable = true
    }

}
