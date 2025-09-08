//
//  PremiumButton.swift
//  GoPlaces
//
//  Premium button component with brand styling and animations
//  Created by Volodymyr Piskun on 05.09.2025.
//

import SwiftUI

struct PremiumButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    let isEnabled: Bool
    let isLoading: Bool
    
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive
        case gold
        case teal
        case sage
        
        var gradient: LinearGradient {
            switch self {
            case .primary:
                return Color.coralGradient
            case .secondary:
                return LinearGradient(colors: [Color.oceanTeal], startPoint: .leading, endPoint: .trailing)
            case .tertiary:
                return LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
            case .destructive:
                return LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
            case .gold:
                return Color.goldGradient
            case .teal:
                return Color.tealGradient
            case .sage:
                return Color.sageGradient
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .gold, .teal, .sage, .secondary:
                return .white
            case .tertiary:
                return Color.deepNavy
            case .destructive:
                return Color.errorCoral
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .tertiary:
                return Color.deepNavy.opacity(0.15)
            case .destructive:
                return Color.errorCoral.opacity(0.3)
            default:
                return nil
            }
        }
        
        var height: CGFloat {
            switch self {
            case .primary:
                return 56  // Larger for primary CTAs
            case .secondary:
                return 48
            case .tertiary, .destructive:
                return 44
            case .gold, .teal, .sage:
                return 52
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .primary:
                return 17
            case .secondary, .gold, .teal, .sage:
                return 16
            case .tertiary, .destructive:
                return 15
            }
        }
        
        var fontWeight: Font.Weight {
            switch self {
            case .primary:
                return .semibold
            case .secondary, .gold, .teal, .sage:
                return .medium
            case .tertiary, .destructive:
                return .regular
            }
        }
    }
    
    init(
        _ title: String,
        style: ButtonStyle = .primary,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard isEnabled && !isLoading else { return }
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                        .scaleEffect(0.8)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    Text(title)
                        .font(.system(size: style.fontSize, weight: style.fontWeight, design: .default))
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .foregroundColor(style.textColor)
            .frame(maxWidth: .infinity)
            .frame(height: style.height)
            .background(
                Group {
                    if style == .tertiary || style == .destructive {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.warmWhite)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(style.borderColor ?? Color.clear, lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(style.gradient)
                            .shadow(color: style == .primary ? Color.coralHeart.opacity(0.3) : Color.clear,
                                   radius: style == .primary ? 8 : 0, x: 0, y: 4)
                    }
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .animation(.easeInOut(duration: 0.3), value: isLoading)
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PlainButtonStyle()) // Disable default button styling
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Compact Button Variant

struct CompactPremiumButton: View {
    let title: String
    let action: () -> Void
    let style: PremiumButton.ButtonStyle
    let isEnabled: Bool
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        style: PremiumButton.ButtonStyle = .primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            action()
        }) {
            Text(title)
                .font(.brandCaption)
                .fontWeight(.medium)
                .foregroundColor(style.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(style.gradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style.borderColor ?? Color.clear, lineWidth: 1)
                        )
                )
                .scaleEffect(isPressed ? 0.94 : 1.0)
                .opacity(isEnabled ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .disabled(!isEnabled)
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview

#Preview("Primary Button") {
    VStack(spacing: 16) {
        PremiumButton("Add to Collection") {}
        PremiumButton("Add (3)", style: .primary) {}
        PremiumButton("Loading...", isLoading: true) {}
        PremiumButton("Disabled", isEnabled: false) {}
        
        HStack {
            CompactPremiumButton("Select All") {}
            CompactPremiumButton("Clear All", style: .tertiary) {}
        }
    }
    .padding()
}

#Preview("Button Styles") {
    VStack(spacing: 16) {
        PremiumButton("Primary", style: .primary) {}
        PremiumButton("Secondary", style: .secondary) {}
        PremiumButton("Tertiary", style: .tertiary) {}
        PremiumButton("Gold Premium", style: .gold) {}
        PremiumButton("Teal Accent", style: .teal) {}
        PremiumButton("Sage Natural", style: .sage) {}
    }
    .padding()
}