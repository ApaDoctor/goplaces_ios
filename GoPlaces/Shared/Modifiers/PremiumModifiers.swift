//
//  PremiumModifiers.swift
//  GoPlaces
//
//  Premium view modifiers for glassmorphism, parallax, and animations
//  Created by Volodymyr Piskun on 06.09.2025.
//

import SwiftUI

// MARK: - Glassmorphic Card Modifier

struct GlassmorphicCardModifier: ViewModifier {
    var cornerRadius: CGFloat = DesignSystem.Radii.card
    var shadowRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base blur layer
                    Color.white.opacity(0.15)
                    
                    // Visual effect blur
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                        .opacity(0.9)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(0.1),
                radius: shadowRadius,
                x: 0,
                y: 10
            )
    }
}

// MARK: - Parallax Scroll Modifier

struct ParallaxScrollModifier: ViewModifier {
    @Binding var scrollOffset: CGFloat
    var parallaxFactor: CGFloat = 0.3
    var scaleFactor: CGFloat = 0.0002
    
    func body(content: Content) -> some View {
        content
            .offset(y: scrollOffset * parallaxFactor)
            .scaleEffect(1 + (max(0, scrollOffset) * scaleFactor))
    }
}

// MARK: - Press Animation Modifier

struct PressAnimationModifier: ViewModifier {
    @State private var isPressed = false
    var scale: CGFloat = 0.96
    var duration: Double = 0.2
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .infinity,
                pressing: { pressing in
                    if pressing != isPressed {
                        if pressing {
                            let impact = UIImpactFeedbackGenerator(style: hapticStyle)
                            impact.impactOccurred()
                        }
                        isPressed = pressing
                    }
                },
                perform: {}
            )
    }
}

// MARK: - Card Shadow Modifier

struct CardShadowModifier: ViewModifier {
    var elevation: ShadowElevation = .medium
    
    enum ShadowElevation {
        case small, medium, large, elevated
        
        var shadow: DesignSystem.Shadows.Shadow {
            switch self {
            case .small:
                return DesignSystem.Shadows.small
            case .medium:
                return DesignSystem.Shadows.medium
            case .large:
                return DesignSystem.Shadows.large
            case .elevated:
                return DesignSystem.Shadows.elevated
            }
        }
    }
    
    func body(content: Content) -> some View {
        let shadow = elevation.shadow
        return content
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// MARK: - Accessibility Card Modifier

struct AccessibilityCardModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits
    
    init(label: String, hint: String? = nil, traits: AccessibilityTraits = .isButton) {
        self.label = label
        self.hint = hint
        self.traits = traits
    }
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Double tap to open")
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Dynamic Type Support Modifier

struct DynamicTypeSupportModifier: ViewModifier {
    var minimumScaleFactor: CGFloat = 0.8
    var lineLimit: Int? = nil
    
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .minimumScaleFactor(minimumScaleFactor)
            .lineLimit(lineLimit)
    }
}

// MARK: - Shimmer Loading Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 1.5
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

// MARK: - Hero Transition Modifier

struct HeroTransitionModifier: ViewModifier {
    let id: String
    let namespace: Namespace.ID
    
    func body(content: Content) -> some View {
        content
            .matchedGeometryEffect(id: id, in: namespace)
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Scroll Tracking Modifier

struct ScrollTrackingModifier: ViewModifier {
    @Binding var offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .global).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                offset = value
            }
    }
}

// MARK: - View Extension for Easy Access

extension View {
    
    /// Applies glassmorphic card styling
    func glassmorphicCard(cornerRadius: CGFloat = DesignSystem.Radii.card) -> some View {
        modifier(GlassmorphicCardModifier(cornerRadius: cornerRadius))
    }
    
    /// Applies parallax scrolling effect
    func parallaxScroll(offset: Binding<CGFloat>, factor: CGFloat = 0.3) -> some View {
        modifier(ParallaxScrollModifier(scrollOffset: offset, parallaxFactor: factor))
    }
    
    /// Applies press animation with haptic feedback
    func pressAnimation(scale: CGFloat = 0.96, haptic: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        modifier(PressAnimationModifier(scale: scale, hapticStyle: haptic))
    }
    
    /// Applies card shadow
    func cardShadow(_ elevation: CardShadowModifier.ShadowElevation = .medium) -> some View {
        modifier(CardShadowModifier(elevation: elevation))
    }
    
    /// Makes view accessible as a card
    func accessibleCard(label: String, hint: String? = nil) -> some View {
        modifier(AccessibilityCardModifier(label: label, hint: hint))
    }
    
    /// Adds dynamic type support
    func dynamicTypeSupport(minimumScale: CGFloat = 0.8, lineLimit: Int? = nil) -> some View {
        modifier(DynamicTypeSupportModifier(minimumScaleFactor: minimumScale, lineLimit: lineLimit))
    }
    
    /// Adds shimmer loading effect
    func shimmer(duration: Double = 1.5) -> some View {
        modifier(ShimmerModifier(duration: duration))
    }
    
    /// Adds hero transition
    func heroTransition(id: String, in namespace: Namespace.ID) -> some View {
        modifier(HeroTransitionModifier(id: id, namespace: namespace))
    }
    
    /// Tracks scroll offset
    func trackScrollOffset(_ offset: Binding<CGFloat>) -> some View {
        modifier(ScrollTrackingModifier(offset: offset))
    }
}

// MARK: - Preview

#if DEBUG
struct PremiumModifiersPreview: View {
    @State private var scrollOffset: CGFloat = 0
    @Namespace private var namespace
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                
                // Glassmorphic Card
                Text("Glassmorphic Card")
                    .font(DesignSystem.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .glassmorphicCard()
                    .padding(.horizontal)
                
                // Press Animation Card
                Text("Press Me")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color.coralHeart)
                    .cornerRadius(DesignSystem.Radii.button)
                    .pressAnimation()
                    .padding(.horizontal)
                
                // Card with Shadow
                VStack {
                    Text("Elevated Card")
                        .font(DesignSystem.Typography.headline)
                    Text("With premium shadow")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(DesignSystem.Radii.card)
                .cardShadow(.elevated)
                .padding(.horizontal)
                
                // Shimmer Loading
                RoundedRectangle(cornerRadius: DesignSystem.Radii.card)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 100)
                    .shimmer()
                    .padding(.horizontal)
                
                // Multiple cards for scroll testing
                ForEach(0..<5) { index in
                    Text("Card \(index + 1)")
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Color.oceanTeal.opacity(0.2))
                        .cornerRadius(DesignSystem.Radii.card)
                        .cardShadow(.medium)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .trackScrollOffset($scrollOffset)
        }
        .overlay(
            Text("Scroll Offset: \(Int(scrollOffset))")
                .font(DesignSystem.Typography.caption)
                .padding()
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(),
            alignment: .topTrailing
        )
    }
}

#Preview("Premium Modifiers") {
    PremiumModifiersPreview()
}
#endif