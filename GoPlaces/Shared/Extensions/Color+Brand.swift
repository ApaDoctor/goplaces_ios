//
//  Color+Brand.swift
//  GoPlaces
//
//  Brand color system for premium 2025 design
//  Created by Volodymyr Piskun on 05.09.2025.
//

import SwiftUI

extension Color {
    
    // MARK: - Primary Brand Palette
    
    /// Coral Heart #FF6B7A - Primary CTA color, psychologically perfect for travel inspiration
    static let coralHeart = Color(hex: "FF6B7A")
    
    /// Deep Navy #1B2B4D - Primary text color, builds trust for bookings
    static let deepNavy = Color(hex: "1B2B4D")
    
    /// Warm White #FAFAFA - Backgrounds, reduces eye strain
    static let warmWhite = Color(hex: "FAFAFA")
    
    // MARK: - Secondary Palette
    
    /// Sunset Gold #FFB84D - Premium features, deals (28% higher perceived value)
    static let sunsetGold = Color(hex: "FFB84D")
    
    /// Ocean Teal #4ECDC4 - Saved/wishlisted items, calming
    static let oceanTeal = Color(hex: "4ECDC4")
    
    /// Sage Green #8FBC8F - Eco-friendly options, appeals to Gen Z
    static let sageGreen = Color(hex: "8FBC8F")
    
    // MARK: - Gradient Support Colors
    
    /// Coral gradient end color #FF8A5B
    static let coralGradientEnd = Color(hex: "FF8A5B")
    
    /// Gold gradient end color #FFA726
    static let goldGradientEnd = Color(hex: "FFA726")
    
    // MARK: - Category Colors (for place types)
    
    /// Restaurant/Cafe coral variant
    static let restaurantCoral = Color(hex: "FF8A5B")
    
    /// Museum purple
    static let museumPurple = Color(hex: "9B59B6")
    
    /// Nature/Park green
    static let natureGreen = Color(hex: "27AE60")
    
    /// Shopping red
    static let shoppingRed = Color(hex: "E74C3C")
    
    /// Transport blue
    static let transportBlue = Color(hex: "3498DB")
    
    // MARK: - Gradient Definitions
    
    /// Primary CTA gradient (coral to coral-orange)
    static let coralGradient = LinearGradient(
        colors: [coralHeart, coralGradientEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Premium feature gradient (gold to orange-gold)
    static let goldGradient = LinearGradient(
        colors: [sunsetGold, goldGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Teal accent gradient
    static let tealGradient = LinearGradient(
        colors: [oceanTeal, Color(hex: "2ECC71")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Sage green gradient
    static let sageGradient = LinearGradient(
        colors: [sageGreen, Color(hex: "27AE60")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Semantic Colors
    
    /// Success color (matches sage green family)
    static let successGreen = Color(hex: "27AE60")
    
    /// Warning color (matches gold family)
    static let warningGold = Color(hex: "F39C12")
    
    /// Error color (matches coral family but darker)
    static let errorCoral = Color(hex: "E74C3C")
    
    /// Info color (matches teal family)
    static let infoTeal = Color(hex: "3498DB")
    
    // MARK: - Helper Functions
    
    /// Get category color for place type
    static func categoryColor(for placeType: String) -> Color {
        switch placeType.lowercased() {
        case "restaurant", "cafe", "bar":
            return restaurantCoral
        case "hotel", "lodging":
            return oceanTeal
        case "tourist_attraction", "museum":
            return museumPurple
        case "park", "natural_feature", "national_park":
            return natureGreen
        case "shopping_mall":
            return shoppingRed
        case "airport", "train_station":
            return transportBlue
        default:
            return deepNavy
        }
    }
    
    /// Get theme gradient for collection color theme
    static func themeGradient(for theme: String) -> LinearGradient {
        switch theme.lowercased() {
        case "coral":
            return coralGradient
        case "gold", "sunset":
            return goldGradient
        case "teal", "ocean":
            return tealGradient
        case "sage", "green":
            return sageGradient
        default:
            return coralGradient
        }
    }
}

// MARK: - Color from Hex String

extension Color {
    /// Create Color from hex string (e.g., "FF6B7A" or "#FF6B7A")
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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// Brand headline font (SF Pro Display Semibold 28pt)
    static let brandHeadline = Font.system(.title, design: .default, weight: .semibold)
    
    /// Destination name font (SF Pro Display Medium 22pt)
    static let destinationName = Font.system(.title2, design: .default, weight: .medium)
    
    /// Body text font (SF Pro Text Regular 17pt - iOS standard)
    static let brandBody = Font.system(.body, design: .default, weight: .regular)
    
    /// Caption font (SF Pro Text Regular 13pt)
    static let brandCaption = Font.system(.caption, design: .default, weight: .regular)
    
    /// Button font (SF Pro Display Medium 17pt)
    static let brandButton = Font.system(.body, design: .default, weight: .medium)
}