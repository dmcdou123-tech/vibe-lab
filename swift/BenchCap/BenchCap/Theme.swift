import SwiftUI

enum Theme {
    static let formBackground = Color(white: 0.97)
    static let sectionHeaderColor = Color(white: 0.4)
    static let labelColor = Color(white: 0.25)
    static let helpColor = Color(white: 0.55)

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16

    static let labelFont = Font.system(size: 14, weight: .semibold)
    static let valueFont = Font.system(size: 16)
    static let sectionHeaderFont = Font.system(size: 12, weight: .semibold)
    static let labelColumnMinWidth: CGFloat = 150
    static let controlColumnWidth: CGFloat = 260
    static let bannerHeight: CGFloat = 60
    static let bannerWidth: CGFloat = 220
    static let entryCornerRadius: CGFloat = 10
    static let entryBorderColor = Color.gray.opacity(0.25)

    static let statusIncomplete = Color(white: 0.85)
    static let statusComplete = Color(red: 0.75, green: 0.88, blue: 0.75)
    static let statusDeviation = Color(red: 0.95, green: 0.86, blue: 0.68)
}
