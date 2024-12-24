import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            title: "Progress",
            image: UIImage(systemName: "star.fill"),
            selectedImage: UIImage(systemName: "star.fill")
        )
        
        // Assign both tabs to the UITabBarController
        viewControllers = [checkInVC, progressVC]
    }
} 