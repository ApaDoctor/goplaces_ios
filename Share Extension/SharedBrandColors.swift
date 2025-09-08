//
//  SharedBrandColors.swift
//  Share Extension
//
//  Brand color system for premium 2025 design (Share Extension)
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
    
    /// Success Green #52C41A - Success states, confirmations
    static let successGreen = Color(hex: "52C41A")
    
    // MARK: - Gradient Support Colors
    
    /// Coral gradient end color #FF8A5B
    static let coralGradientEnd = Color(hex: "FF8A5B")
    
    /// Gold gradient end color #FFA726
    static let goldGradientEnd = Color(hex: "FFA726")
    
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
    
    // MARK: - Helper Functions
    
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

// MARK: - Typography System (Shift Nudge Principles)
//
// Font sizes follow a modular scale (1.25 ratio)
// Weights: Regular (400), Medium (500), Semibold (600), Bold (700)
// Line heights: 1.2x for headings, 1.5x for body text
// Letter spacing: -2% for large text, 0% for body, +1% for small text

extension Font {
    // MARK: Display Fonts (Large, impactful)
    /// Hero headline (34pt Semibold) - For main screen titles
    static let heroHeadline = Font.system(size: 34, weight: .semibold, design: .default)
    
    /// Section headline (28pt Semibold) - For major sections
    static let brandHeadline = Font.system(size: 28, weight: .semibold, design: .default)
    
    // MARK: Text Fonts (Readable, clear)
    /// Title font (22pt Medium) - For card titles, destinations
    static let destinationName = Font.system(size: 22, weight: .medium, design: .default)
    
    /// Subtitle font (20pt Regular) - For secondary headings
    static let brandSubtitle = Font.system(size: 20, weight: .regular, design: .default)
    
    /// Body text (17pt Regular) - Main readable text
    static let brandBody = Font.system(size: 17, weight: .regular, design: .default)
    
    /// Body emphasis (17pt Medium) - For emphasis in body text
    static let brandBodyEmphasis = Font.system(size: 17, weight: .medium, design: .default)
    
    // MARK: Interface Fonts (Functional)
    /// Button font (17pt Medium) - CTA buttons
    static let brandButton = Font.system(size: 17, weight: .medium, design: .default)
    
    /// Label font (15pt Regular) - Form labels, metadata
    static let brandLabel = Font.system(size: 15, weight: .regular, design: .default)
    
    /// Caption font (13pt Regular) - Small text, hints
    static let brandCaption = Font.system(size: 13, weight: .regular, design: .default)
    
    /// Caption emphasis (13pt Medium) - Emphasized small text
    static let brandCaptionEmphasis = Font.system(size: 13, weight: .medium, design: .default)
    
    /// Micro text (11pt Regular) - Smallest readable text
    static let brandMicro = Font.system(size: 11, weight: .regular, design: .default)
}