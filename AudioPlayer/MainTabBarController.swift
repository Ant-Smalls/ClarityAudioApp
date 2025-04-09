import UIKit
import SwiftUI

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupAppearance()
    }
    
    private func setupViewControllers() {
        // Recorder Tab
        let recorderVC = ViewController()
        recorderVC.tabBarItem = UITabBarItem(
            title: "Record",
            image: UIImage(systemName: "mic"),
            selectedImage: UIImage(systemName: "mic.fill")
        )
        
        // Library Tab
        let libraryView = LibraryView()
        let libraryHostingController = UIHostingController(rootView: libraryView)
        libraryHostingController.tabBarItem = UITabBarItem(
            title: "Library",
            image: UIImage(systemName: "folder"),
            selectedImage: UIImage(systemName: "folder.fill")
        )
        
        // Set View Controllers
        viewControllers = [recorderVC, libraryHostingController]
    }
    
    private func setupAppearance() {
        // Set tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#23252c")
        
        // Set colors for items
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        appearance.stackedLayoutAppearance.normal.iconColor = .gray
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
} 