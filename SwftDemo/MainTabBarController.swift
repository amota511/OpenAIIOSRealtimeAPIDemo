import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Customize tab bar appearance to have a raised background color
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = .systemGray6
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.barTintColor = .systemGray6
        }
        
        // First tab: Your existing RootViewController
        let checkInVC = RootViewController()
        checkInVC.tabBarItem = UITabBarItem(
            title: "Check In",
            image: UIImage(systemName: "waveform"),
            selectedImage: UIImage(systemName: "waveform")
        )
        
        // Second tab: A new, blank ProgressViewController
        let progressVC = ProgressViewController()
        progressVC.tabBarItem = UITabBarItem(
            title: "You",
            image: UIImage(systemName: "star.fill"),
            selectedImage: UIImage(systemName: "star.fill")
        )
        
        // Third tab: Replace green VC with TalkThroughViewController
        let talkThroughVC = TalkThroughViewController()
        talkThroughVC.tabBarItem = UITabBarItem(
            title: "Unblock",
            image: UIImage(systemName: "hand.raised.slash"),
            selectedImage: UIImage(systemName: "hand.raised.slash")
        )
        
        // Assign all tabs to the UITabBarController
        viewControllers = [checkInVC, progressVC, talkThroughVC]
    }
} 
