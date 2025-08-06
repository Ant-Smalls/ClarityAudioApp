import SwiftUI
import UIKit

public enum AppTheme {
    // MARK: - SwiftUI Colors
    public static let backgroundColor = Color(red: 0.11, green: 0.11, blue: 0.12)
    public static let secondaryColor = Color(red: 0.18, green: 0.18, blue: 0.2)
    public static let accentColor = Color(red: 0.0, green: 0.48, blue: 1.0)
    public static let textColor = Color.white
    public static let secondaryTextColor = Color.white.opacity(0.7)
    
    // MARK: - UIKit Colors
    public static let backgroundColorUI = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
    public static let secondaryColorUI = UIColor(red: 0.18, green: 0.18, blue: 0.2, alpha: 1.0)
    public static let accentColorUI = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
    public static let textColorUI = UIColor.white
    public static let secondaryTextColorUI = UIColor.white.withAlphaComponent(0.7)
} 