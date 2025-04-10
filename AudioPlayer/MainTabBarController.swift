import UIKit
import SwiftUI

class MainTabBarController: UITabBarController {
    
    var inputLanguage: String = "en-US"
    var outputLanguage: String = "es-ES"
    
    init(inputLanguage: String, outputLanguage: String) {
        self.inputLanguage = inputLanguage
        self.outputLanguage = outputLanguage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupAppearance()
    }
    
    private func setupViewControllers() {
        // Settings Tab
        let settingsView = LanguageSelectionView(
            initialInputLanguage: inputLanguage,
            initialOutputLanguage: outputLanguage
        )
        let settingsHostingController = UIHostingController(rootView: settingsView)
        settingsHostingController.tabBarItem = UITabBarItem(
            title: "Languages",
            image: UIImage(systemName: "globe"),
            selectedImage: UIImage(systemName: "globe.fill")
        )
        
        // Record Tab
        let recordView = RecordView(inputLanguage: inputLanguage, outputLanguage: outputLanguage)
        let recordHostingController = UIHostingController(rootView: recordView)
        recordHostingController.tabBarItem = UITabBarItem(
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
        viewControllers = [settingsHostingController, recordHostingController, libraryHostingController]
        
        // Set the initial tab
        selectedIndex = 0
    }
    
    private func setupAppearance() {
        // Set tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppTheme.backgroundColorUI
        
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