import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            UIColor(red: 0.965, green: 0.690, blue: 0.815, alpha: 1.0)
        } else {
            UIColor(red: 0.478, green: 0.184, blue: 0.309, alpha: 1.0)
        }
    })

    static let accentSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            UIColor(red: 0.235, green: 0.120, blue: 0.180, alpha: 1.0)
        } else {
            UIColor(red: 0.957, green: 0.894, blue: 0.925, alpha: 1.0)
        }
    })

    static let screenBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedBackground = Color(uiColor: .tertiarySystemGroupedBackground)
    static let brandBackground = Color(red: 0.118, green: 0.118, blue: 0.110)

    static let cream = screenBackground
}
