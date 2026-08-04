import Foundation
import SwiftUI

// Color scheme matching Android colors.xml
extension Color {
    // Primary Theme Colors
    static let primaryColor = Color(hex: "#2D7A7E")
    static let primaryDarkColor = Color(hex: "#205559")
    static let primaryColorLight = Color(hex: "#E0F7F4")
    
    // Accent + Buttons
    static let accentColor = Color(hex: "#4DB6AC")
    static let bgColor = Color(hex: "#328587")
    static let buttonColor = Color(hex: "#00897B")
    
    // Text + Fields
    static let fieldBackgroundColor = Color(hex: "#F0FBFB")
    static let fieldTextColor = Color(hex: "#000000")
    static let fieldHintColor = Color(hex: "#888888")
    
    // Card Backgrounds
    static let cardLightBackgroundColor = Color(hex: "#E2F1EF")
    static let cardMediumBackgroundColor = Color(hex: "#E8F1F1")
    static let cardDarkBackgroundColor = Color(hex: "#DDEAEA")
    
    // Zone Colors
    static let greenZone = Color(hex: "#4CAF50")
    static let yellowZone = Color(hex: "#FBC02D")
    static let redZone = Color(hex: "#F44336")
    
    // Zone Backgrounds (Light/Pastel)
    static let zoneGreenLight = Color(hex: "#DFF5E3")
    static let zoneYellowLight = Color(hex: "#FFF7D1")
    static let zoneRedLight = Color(hex: "#FFD6D6")
    
    // Basic
    static let graphUnifiedBg = Color(hex: "#DEE9E8")
    static let primaryTextColor = Color(hex: "#333333")
    static let overlay = Color(hex: "#80000000")
    
    // Helper initializer for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
