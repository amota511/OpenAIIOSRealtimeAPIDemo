import UIKit

extension UIColor {
    // Simple hex-based initializer
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let length = hexSanitized.count
        switch length {
        case 6:
            let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: 1.0)
        default:
            return nil
        }
    }
}

struct GlobalColors {
    // Backgrounds
    static let mainBackground = UIColor(hex: "#FFFFFF") ?? .white
    static let accentBackground = UIColor(hex: "#F9F9F9") ?? .lightGray

    // Text
    static let primaryText = UIColor(hex: "#000000") ?? .black
    static let secondaryText = UIColor(hex: "#6D6D6D") ?? .darkGray
    static let highlightText = UIColor(hex: "#212121") ?? .black

    // Buttons and highlights
    static let primaryButton = UIColor(hex: "#000000") ?? .black
    // You can pick either #007BFF or #FF9500 or define both
    static let secondaryButton = UIColor(hex: "#007BFF") ?? .systemBlue

    // Borders and dividers
    static let divider = UIColor(hex: "#E0E0E0") ?? .lightGray

    // Interactive elements
    static let selectedOptionBackground = UIColor(hex: "#2E2E2E") ?? .darkGray
    static let unselectedOptionBackground = UIColor(hex: "#FFFFFF") ?? .white
} 
