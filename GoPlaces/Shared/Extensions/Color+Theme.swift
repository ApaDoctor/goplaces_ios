//
//  Color+Theme.swift
//  GoPlaces
//
//  Extended color theme helpers and utilities
//  Created by Volodymyr Piskun on 06.09.2025.
//

import SwiftUI

extension Color {
    
    // MARK: - Adaptive Colors
    
    /// Returns appropriate color based on color scheme
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    /// Card background that adapts to color scheme
    static var adaptiveCardBackground: Color {
        adaptive(
            light: DesignSystem.Colors.cardBackground,
            dark: DesignSystem.Colors.darkCardBackground
        )
    }
    
    /// Primary text that adapts to color scheme
    static var adaptivePrimaryText: Color {
        adaptive(
            light: DesignSystem.Colors.primaryText,
            dark: DesignSystem.Colors.darkPrimaryText
        )
    }
    
    /// Secondary text that adapts to color scheme
    static var adaptiveSecondaryText: Color {
        adaptive(
            light: DesignSystem.Colors.secondaryText,
            dark: DesignSystem.Colors.darkSecondaryText
        )
    }
    
    /// Divider that adapts to color scheme
    static var adaptiveDivider: Color {
        adaptive(
            light: DesignSystem.Colors.divider,
            dark: DesignSystem.Colors.darkDivider
        )
    }
    
    // MARK: - Gradient Helpers
    
    /// Creates a card gradient overlay for images
    static func cardGradientOverlay(startOpacity: Double = 0, endOpacity: Double = 0.5) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.black.opacity(startOpacity),
                Color.black.opacity(endOpacity)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Creates a shimmer gradient for loading states
    static func shimmerGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    /// Creates a glassmorphic gradient
    static func glassmorphicGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.6),
                Color.white.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Color Interpolation
    
    /// Interpolates between two colors
    func interpolated(to color: Color, amount: Double) -> Color {
        let clampedAmount = min(max(amount, 0), 1)
        
        let c1 = UIColor(self).cgColor
        let c2 = UIColor(color).cgColor
        
        guard let components1 = c1.components,
              let components2 = c2.components,
              components1.count == 4,
              components2.count == 4 else {
            return self
        }
        
        let r = components1[0] + (components2[0] - components1[0]) * clampedAmount
        let g = components1[1] + (components2[1] - components1[1]) * clampedAmount
        let b = components1[2] + (components2[2] - components1[2]) * clampedAmount
        let a = components1[3] + (components2[3] - components1[3]) * clampedAmount
        
        return Color(red: r, green: g, blue: b, opacity: a)
    }
    
    /// Returns a lighter version of the color
    func lighter(by amount: Double = 0.2) -> Color {
        return self.interpolated(to: .white, amount: amount)
    }
    
    /// Returns a darker version of the color
    func darker(by amount: Double = 0.2) -> Color {
        return self.interpolated(to: .black, amount: amount)
    }
    
    // MARK: - Random Theme Colors
    
    /// Returns a random theme color for new collections
    static func randomThemeColor() -> String {
        let themes = ["coral", "gold", "teal", "sage", "purple", "blue"]
        return themes.randomElement() ?? "coral"
    }
    
    /// Returns collection theme color based on string
    static func collectionThemeColor(_ theme: String?) -> Color {
        guard let theme = theme else { return coralHeart }
        
        switch theme.lowercased() {
        case "coral":
            return coralHeart
        case "gold", "sunset":
            return sunsetGold
        case "teal", "ocean":
            return oceanTeal
        case "sage", "green":
            return sageGreen
        case "purple":
            return museumPurple
        case "blue":
            return transportBlue
        default:
            return coralHeart
        }
    }
}

// MARK: - Gradient Extensions

extension LinearGradient {
    
    /// Creates a diagonal gradient
    static func diagonal(colors: [Color]) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Creates a vertical gradient
    static func vertical(colors: [Color]) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Creates a horizontal gradient
    static func horizontal(colors: [Color]) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Visual Effect Blur

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct ColorThemePreview: View {
    @State private var selectedTheme = "coral"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Color Theme Helpers")
                .font(DesignSystem.Typography.title2)
            
            // Theme selector
            Picker("Theme", selection: $selectedTheme) {
                Text("Coral").tag("coral")
                Text("Gold").tag("gold")
                Text("Teal").tag("teal")
                Text("Sage").tag("sage")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Theme gradient preview
            RoundedRectangle(cornerRadius: DesignSystem.Radii.card)
                .fill(Color.themeGradient(for: selectedTheme))
                .frame(height: 100)
                .padding(.horizontal)
            
            // Adaptive colors
            VStack(spacing: 10) {
                Text("Adaptive Colors")
                    .font(DesignSystem.Typography.headline)
                
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.adaptiveCardBackground)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("Card")
                                .foregroundColor(Color.adaptivePrimaryText)
                        )
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.adaptiveDivider, lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("Border")
                                .foregroundColor(Color.adaptiveSecondaryText)
                        )
                }
            }
            
            // Color modifications
            HStack(spacing: 10) {
                VStack {
                    Circle()
                        .fill(Color.coralHeart)
                        .frame(width: 60, height: 60)
                    Text("Original")
                        .font(.caption)
                }
                
                VStack {
                    Circle()
                        .fill(Color.coralHeart.lighter())
                        .frame(width: 60, height: 60)
                    Text("Lighter")
                        .font(.caption)
                }
                
                VStack {
                    Circle()
                        .fill(Color.coralHeart.darker())
                        .frame(width: 60, height: 60)
                    Text("Darker")
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview("Color Theme") {
    ColorThemePreview()
        .preferredColorScheme(.light)
}

#Preview("Color Theme Dark") {
    ColorThemePreview()
        .preferredColorScheme(.dark)
}
#endif