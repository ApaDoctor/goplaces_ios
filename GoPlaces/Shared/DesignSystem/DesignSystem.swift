//
//  DesignSystem.swift
//  GoPlaces
//
//  Core design system with tokens for colors, typography, spacing, and styling
//  Created by Volodymyr Piskun on 06.09.2025.
//

import SwiftUI

// MARK: - Design System

enum DesignSystem {
    
    // MARK: - Colors
    
    enum Colors {
        // Primary Colors
        static let coralHeart = Color(hex: "FF6B7A")  // Primary brand color - main UI elements
        static let deepNavy = Color(hex: "1B2B4D")
        static let warmWhite = Color(hex: "FAFAFA")
        
        // Secondary Colors
        static let sunsetGold = Color(hex: "FFB84D")
        static let oceanTeal = Color(hex: "4ECDC4")   // Secondary brand color - CTAs & accents
        static let sageGreen = Color(hex: "8FBC8F")
        
        // MARK: Brand Color Usage Guidelines
        // Coral (Primary): Navigation selection, favorite hearts, primary buttons,
        //                  selection indicators, main brand elements
        // Teal (Secondary): Add/create buttons, FABs, secondary CTAs, links,
        //                   supporting icons, accent elements
        
        // Semantic Colors
        static let cardBackground = warmWhite
        static let primaryText = deepNavy
        static let secondaryText = deepNavy.opacity(0.6)
        static let tertiaryText = deepNavy.opacity(0.4)
        static let divider = deepNavy.opacity(0.08)
        
        // Status Colors
        static let success = sageGreen
        static let warning = sunsetGold
        static let error = coralHeart
        static let info = oceanTeal
        
        // Dark Mode Variants
        static let darkCardBackground = Color(hex: "1C1C1E")
        static let darkPrimaryText = Color.white
        static let darkSecondaryText = Color.white.opacity(0.7)
        static let darkDivider = Color.white.opacity(0.1)
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
        
        // Specific spacing
        static let cardPadding: CGFloat = 16
        static let screenMargin: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
        static let gridSpacing: CGFloat = 16
    }
    
    // MARK: - Corner Radius
    
    enum Radii {
        static let button: CGFloat = 16
        static let card: CGFloat = 20
        static let sheet: CGFloat = 28
        static let image: CGFloat = 16
        static let pill: CGFloat = 100
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 24
    }
    
    // MARK: - Shadows
    
    enum Shadows {
        static let small = Shadow(
            color: Color.black.opacity(0.04),
            radius: 8,
            x: 0,
            y: 2
        )
        
        static let medium = Shadow(
            color: Color.black.opacity(0.08),
            radius: 12,
            x: 0,
            y: 4
        )
        
        static let large = Shadow(
            color: Color.black.opacity(0.1),
            radius: 16,
            x: 0,
            y: 8
        )
        
        static let elevated = Shadow(
            color: Color.black.opacity(0.1),
            radius: 20,
            x: 0,
            y: 10
        )
        
        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Typography
    
    enum Typography {
        // Display
        static let largeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
        static let title = Font.system(.title, design: .default, weight: .semibold)
        static let title2 = Font.system(.title2, design: .default, weight: .semibold)
        static let title3 = Font.system(.title3, design: .default, weight: .semibold)
        
        // Body
        static let headline = Font.system(.headline, design: .default, weight: .semibold)
        static let subheadline = Font.system(.subheadline, design: .default, weight: .medium)
        static let body = Font.system(.body, design: .default, weight: .regular)
        static let callout = Font.system(.callout, design: .default, weight: .regular)
        
        // Support
        static let caption = Font.system(.caption, design: .default, weight: .regular)
        static let caption2 = Font.system(.caption2, design: .default, weight: .regular)
        static let footnote = Font.system(.footnote, design: .default, weight: .regular)
        
        // Custom
        static let brandTitle = Font.system(size: 28, weight: .bold, design: .default)
        static let brandHeadline = Font.system(size: 20, weight: .semibold, design: .default)
        static let brandBody = Font.system(size: 16, weight: .regular, design: .default)
        static let brandCaption = Font.system(size: 12, weight: .medium, design: .default)
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let springDefault = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let springQuick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)
        static let easeDefault = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let easeFast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let easeSlow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
    
    // MARK: - Layout
    
    enum Layout {
        static let heroImageHeight: CGFloat = UIScreen.main.bounds.height * 0.4
        static let collectionCardLargeHeight: CGFloat = 220
        static let collectionCardSmallHeight: CGFloat = 160
        static let placeRowHeight: CGFloat = 80
        static let tabBarHeight: CGFloat = 44
        static let minTouchTarget: CGFloat = 44
        static let maxContentWidth: CGFloat = 428 // Max width for iPad
    }
    
    // MARK: - Icons
    
    enum Icons {
        static let collections = "square.grid.2x2"
        static let places = "mappin.circle"
        static let add = "plus.circle.fill"
        static let favorite = "heart.fill"
        static let unfavorite = "heart"
        static let share = "square.and.arrow.up"
        static let map = "map"
        static let list = "list.bullet"
        static let filter = "line.3.horizontal.decrease.circle"
        static let search = "magnifyingglass"
        static let close = "xmark"
        static let chevronRight = "chevron.right"
        static let location = "location.fill"
        static let clock = "clock"
        static let dollarSign = "dollarsign.circle"
        static let star = "star.fill"
        static let camera = "camera"
        static let checkmark = "checkmark"
    }
}

// MARK: - Helper Extensions

// Color hex initializer is defined in Color+Brand.swift

// MARK: - Environment Values

extension EnvironmentValues {
    var designSystem: DesignSystem.Type {
        return DesignSystem.self
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct DesignSystemPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Colors Section
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Colors")
                        .font(DesignSystem.Typography.title2)
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ColorSwatch(color: DesignSystem.Colors.coralHeart, name: "Coral")
                        ColorSwatch(color: DesignSystem.Colors.deepNavy, name: "Navy")
                        ColorSwatch(color: DesignSystem.Colors.warmWhite, name: "White")
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ColorSwatch(color: DesignSystem.Colors.sunsetGold, name: "Gold")
                        ColorSwatch(color: DesignSystem.Colors.oceanTeal, name: "Teal")
                        ColorSwatch(color: DesignSystem.Colors.sageGreen, name: "Sage")
                    }
                }
                
                Divider()
                
                // Typography Section
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Typography")
                        .font(DesignSystem.Typography.title2)
                    
                    Text("Large Title")
                        .font(DesignSystem.Typography.largeTitle)
                    Text("Title")
                        .font(DesignSystem.Typography.title)
                    Text("Headline")
                        .font(DesignSystem.Typography.headline)
                    Text("Body")
                        .font(DesignSystem.Typography.body)
                    Text("Caption")
                        .font(DesignSystem.Typography.caption)
                }
                
                Divider()
                
                // Spacing Section
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Spacing")
                        .font(DesignSystem.Typography.title2)
                    
                    SpacingRow(size: DesignSystem.Spacing.xs, name: "xs (4pt)")
                    SpacingRow(size: DesignSystem.Spacing.sm, name: "sm (8pt)")
                    SpacingRow(size: DesignSystem.Spacing.md, name: "md (16pt)")
                    SpacingRow(size: DesignSystem.Spacing.lg, name: "lg (24pt)")
                    SpacingRow(size: DesignSystem.Spacing.xl, name: "xl (32pt)")
                }
                
                Divider()
                
                // Shadows Section
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Shadows")
                        .font(DesignSystem.Typography.title2)
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ShadowBox(shadow: DesignSystem.Shadows.small, name: "Small")
                        ShadowBox(shadow: DesignSystem.Shadows.medium, name: "Medium")
                        ShadowBox(shadow: DesignSystem.Shadows.large, name: "Large")
                    }
                }
            }
            .padding(DesignSystem.Spacing.screenMargin)
        }
    }
    
    struct ColorSwatch: View {
        let color: Color
        let name: String
        
        var body: some View {
            VStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radii.small)
                    .fill(color)
                    .frame(width: 80, height: 80)
                Text(name)
                    .font(DesignSystem.Typography.caption)
            }
        }
    }
    
    struct SpacingRow: View {
        let size: CGFloat
        let name: String
        
        var body: some View {
            HStack {
                Text(name)
                    .font(DesignSystem.Typography.caption)
                    .frame(width: 80, alignment: .leading)
                Rectangle()
                    .fill(DesignSystem.Colors.oceanTeal)
                    .frame(width: size, height: size)
            }
        }
    }
    
    struct ShadowBox: View {
        let shadow: DesignSystem.Shadows.Shadow
        let name: String
        
        var body: some View {
            VStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radii.small)
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: shadow.color,
                        radius: shadow.radius,
                        x: shadow.x,
                        y: shadow.y
                    )
                Text(name)
                    .font(DesignSystem.Typography.caption)
            }
        }
    }
}

#Preview("Design System") {
    DesignSystemPreview()
}
#endif

