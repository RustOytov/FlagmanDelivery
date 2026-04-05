import SwiftUI

enum AppTheme {
    enum Colors {
        static let background = Color(red: 0.06, green: 0.07, blue: 0.10)
        static let surface = Color(red: 0.11, green: 0.13, blue: 0.18)
        static let surfaceElevated = Color(red: 0.15, green: 0.17, blue: 0.24)
        static let accent = Color(red: 0.25, green: 0.55, blue: 1.0)
        static let accentSecondary = Color(red: 0.45, green: 0.72, blue: 1.0)
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.65)
        static let textTertiary = Color.white.opacity(0.4)
        static let border = Color.white.opacity(0.08)
        static let success = Color(red: 0.2, green: 0.78, blue: 0.45)
        static let warning = Color(red: 1.0, green: 0.76, blue: 0.28)
        static let error = Color(red: 1.0, green: 0.35, blue: 0.4)
    }

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .medium, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
    }

    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 22
        static let pill: CGFloat = 999
    }
}

extension OrderStatus {
    var tint: Color {
        switch self {
        case .created: return AppTheme.Colors.textSecondary
        case .searchingCourier: return AppTheme.Colors.warning
        case .courierAssigned, .inDelivery: return AppTheme.Colors.accent
        case .delivered: return AppTheme.Colors.success
        case .cancelled: return AppTheme.Colors.error
        }
    }
}
