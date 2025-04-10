import UIKit
import SwiftUI

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupAppearance()
    }
    
    private func setupViewControllers() {
        // Language Settings View
        let languageView = LanguageSelectionView()
        let languageHostingController = UIHostingController(rootView: languageView)
        languageHostingController.tabBarItem = UITabBarItem(
            title: "Languages",
            image: UIImage(systemName: "globe"),
            selectedImage: UIImage(systemName: "globe.fill")
        )
        
        // Record View - Load from storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let recordVC = storyboard.instantiateViewController(withIdentifier: "ViewController")
        let recordNav = UINavigationController(rootViewController: recordVC)
        recordNav.tabBarItem = UITabBarItem(
            title: "Record",
            image: UIImage(systemName: "mic"),
            selectedImage: UIImage(systemName: "mic.fill")
        )
        
        // Library View
        let libraryView = LibraryView()
        let libraryHostingController = UIHostingController(rootView: libraryView)
        libraryHostingController.tabBarItem = UITabBarItem(
            title: "Library",
            image: UIImage(systemName: "book"),
            selectedImage: UIImage(systemName: "book.fill")
        )
        
        viewControllers = [languageHostingController, recordNav, libraryHostingController]
    }
    
    private func setupAppearance() {
        tabBar.tintColor = AppTheme.accentColorUI
        tabBar.backgroundColor = AppTheme.backgroundColorUI
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = AppTheme.backgroundColorUI
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }
} 