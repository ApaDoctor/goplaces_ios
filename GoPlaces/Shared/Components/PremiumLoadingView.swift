//
//  PremiumLoadingView.swift
//  GoPlaces
//
//  Premium loading screen with Discovery Pulse animation
//  Created by Volodymyr Piskun on 05.09.2025.
//

import SwiftUI

// MARK: - Main Loading View

struct PremiumLoadingView: View {
    let title: String
    let subtitle: String?
    let progress: Double? // 0.0 to 1.0, nil for indeterminate
    let estimatedSeconds: Int?
    
    // Animation states
    @State private var pulseAnimation = false
    @State private var pinHeartbeat = false
    @State private var particles: [DiscoveryParticle] = []
    @State private var showContent = false
    @State private var discoveredPlaces: [DiscoveredPlace] = []
    
    // Timer for particle generation
    @State private var particleTimer: Timer?
    @State private var heartbeatTimer: Timer?
    
    init(
        title: String,
        subtitle: String? = nil,
        progress: Double? = nil,
        estimatedSeconds: Int? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.estimatedSeconds = estimatedSeconds
    }
    
    var body: some View {
        ZStack {
            // 1. Premium Gradient Background
            LinearGradient(
                colors: [
                    Color(hex: "1B2B4D"), // Deep Navy
                    Color(hex: "2A3A5C")  // Lighter Navy
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .overlay(
                // Subtle noise texture
                NoiseTextureView()
                    .opacity(0.03)
                    .blendMode(.overlay)
            )
            
            VStack(spacing: 0) {
                Spacer()
                
                // 2. Central Discovery Animation Group
                ZStack {
                    // Progress Ring (behind pulses)
                    if let progress = progress {
                        ProgressRingView(progress: CGFloat(progress))
                            .frame(width: 200, height: 200)
                    }
                    
                    // Discovery Pulse Animation
                    DiscoveryPulseView()
                        .frame(width: 180, height: 180)
                    
                    // Discovery Particles
                    ForEach(particles) { particle in
                        DiscoveryParticleView(particle: particle)
                    }
                    
                    // Central Pin Icon
                    CentralPinView(heartbeat: $pinHeartbeat)
                }
                .frame(width: 200, height: 200)
                .scaleEffect(pulseAnimation ? 1.0 : 0.8)
                .opacity(showContent ? 1 : 0)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        pulseAnimation = true
                        showContent = true
                    }
                    startHeartbeat()
                    generateParticles()
                }
                
                // 3. Typography Stack
                VStack(spacing: 16) {
                    Text(title)
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundColor(Color(hex: "FAFAFA"))
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(
                            .easeOut(duration: 0.5).delay(0.3),
                            value: showContent
                        )
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(hex: "FAFAFA").opacity(0.7))
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.5).delay(0.5),
                                value: showContent
                            )
                    }
                    
                    // Estimated time (if provided)
                    if let estimatedSeconds = estimatedSeconds {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text("~\(estimatedSeconds)s")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(Color(hex: "FAFAFA").opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                        )
                        .opacity(showContent ? 1 : 0)
                        .animation(
                            .easeOut(duration: 0.5).delay(0.6),
                            value: showContent
                        )
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 4. Discovery Preview Card (only shows when we have places)
                if !discoveredPlaces.isEmpty {
                    DiscoveryPreviewCard(discoveredPlaces: discoveredPlaces)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.6).delay(0.4),
                            value: showContent
                        )
                }
            }
        }
        .onAppear {
            // Initial haptic
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
        .onDisappear {
            // Clean up timers
            particleTimer?.invalidate()
            heartbeatTimer?.invalidate()
        }
    }
    
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                pinHeartbeat = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pinHeartbeat = false
            }
        }
    }
    
    private func generateParticles() {
        particleTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            if particles.count < 5 {
                let newParticle = DiscoveryParticle()
                particles.append(newParticle)
                
                // Remove particle after lifetime
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    particles.removeAll { $0.id == newParticle.id }
                }
                
                // Light haptic for discovery
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        }
    }
}

// MARK: - Discovery Pulse Animation

struct DiscoveryPulseView: View {
    @State private var pulseScale1: CGFloat = 0.8
    @State private var pulseOpacity1: Double = 1.0
    @State private var pulseScale2: CGFloat = 0.8
    @State private var pulseOpacity2: Double = 1.0
    @State private var pulseScale3: CGFloat = 0.8
    @State private var pulseOpacity3: Double = 1.0
    
    var body: some View {
        ZStack {
            // Pulse Ring 1 (innermost)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.coralHeart,
                            Color.oceanTeal.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 80, height: 80)
                .scaleEffect(pulseScale1)
                .opacity(pulseOpacity1)
                .onAppear {
                    withAnimation(
                        .easeOut(duration: 2.4)
                        .repeatForever(autoreverses: false)
                    ) {
                        pulseScale1 = 1.8
                        pulseOpacity1 = 0
                    }
                }
            
            // Pulse Ring 2 (middle)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.coralHeart.opacity(0.8),
                            Color.oceanTeal.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
                .frame(width: 120, height: 120)
                .scaleEffect(pulseScale2)
                .opacity(pulseOpacity2)
                .onAppear {
                    withAnimation(
                        .easeOut(duration: 2.4)
                        .repeatForever(autoreverses: false)
                        .delay(0.4)
                    ) {
                        pulseScale2 = 1.5
                        pulseOpacity2 = 0
                    }
                }
            
            // Pulse Ring 3 (outermost)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.coralHeart.opacity(0.6),
                            Color.oceanTeal.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
                .frame(width: 180, height: 180)
                .scaleEffect(pulseScale3)
                .opacity(pulseOpacity3)
                .onAppear {
                    withAnimation(
                        .easeOut(duration: 2.4)
                        .repeatForever(autoreverses: false)
                        .delay(0.8)
                    ) {
                        pulseScale3 = 1.3
                        pulseOpacity3 = 0
                    }
                }
        }
    }
}

// MARK: - Central Pin

struct CentralPinView: View {
    @Binding var heartbeat: Bool
    
    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.coralHeart.opacity(0.3),
                            Color.coralHeart.opacity(0)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 8)
            
            // Pin icon with gradient
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 56, weight: .medium))
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FF6B7A"), Color(hex: "FF8A95")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    Color.white.opacity(0.9)
                )
                .scaleEffect(heartbeat ? 1.15 : 1.0)
                .shadow(color: .coralHeart.opacity(0.3), radius: 12, x: 0, y: 4)
        }
    }
}

// MARK: - Progress Ring

struct ProgressRingView: View {
    let progress: CGFloat
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: 3
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "FF6B7A"),
                            Color(hex: "FFB84D")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: .coralHeart.opacity(0.3), radius: 8, x: 0, y: 0)
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Glow effect at progress end
            if progress > 0 && progress < 1 {
                Circle()
                    .fill(Color.sunsetGold)
                    .frame(width: 8, height: 8)
                    .offset(y: -100)
                    .rotationEffect(.degrees(360 * Double(progress) - 90))
                    .shadow(color: .sunsetGold, radius: 4)
            }
        }
    }
}

// MARK: - Discovery Particles

struct DiscoveryParticle: Identifiable {
    let id = UUID()
    let position: CGPoint = {
        let angle = Double.random(in: 0...(2 * .pi))
        let radius = Double.random(in: 40...80)
        return CGPoint(
            x: cos(angle) * radius,
            y: sin(angle) * radius
        )
    }()
}

struct DiscoveryParticleView: View {
    let particle: DiscoveryParticle
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(Color.coralHeart)
            .frame(width: 4, height: 4)
            .scaleEffect(scale)
            .opacity(opacity)
            .shadow(color: .coralHeart, radius: 6)
            .offset(x: particle.position.x, y: particle.position.y)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
                
                withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Discovery Preview Card

struct DiscoveredPlace: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

struct DiscoveryPreviewCard: View {
    let discoveredPlaces: [DiscoveredPlace]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !discoveredPlaces.isEmpty {
                Text("Discovered")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            HStack(spacing: 12) {
                ForEach(discoveredPlaces) { place in
                    MicroPlaceCard(place: place)
                        .transition(
                            .asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                }
                
                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            // Glassmorphic background
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            }
        )
    }
}

struct MicroPlaceCard: View {
    let place: DiscoveredPlace
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Image(systemName: place.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(place.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
        }
        .frame(width: 80, height: 80)
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - Noise Texture

struct NoiseTextureView: View {
    var body: some View {
        // Simple noise simulation with random dots
        GeometryReader { geometry in
            Canvas { context, size in
                for _ in 0..<500 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let opacity = Double.random(in: 0.02...0.08)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
        }
    }
}

// MARK: - Compact Loading View (Preserved for compatibility)

struct CompactLoadingView: View {
    let message: String
    let progress: Double?
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Spinner
            if let progress = progress {
                ZStack {
                    Circle()
                        .stroke(Color.coralHeart.opacity(0.2), lineWidth: 3)
                        .frame(width: 24)
                    
                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(
                            Color.coralHeart,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 24)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            } else {
                ZStack {
                    Circle()
                        .stroke(Color.coralHeart.opacity(0.2), lineWidth: 3)
                        .frame(width: 24)
                    
                    Circle()
                        .trim(from: 0.0, to: 0.25)
                        .stroke(
                            Color.coralHeart,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 24)
                        .rotationEffect(.degrees(rotationAngle))
                }
            }
            
            Text(message)
                .font(.brandBody)
                .foregroundColor(.secondary)
        }
        .onAppear {
            if progress == nil {
                withAnimation(
                    .linear(duration: 1.0)
                    .repeatForever(autoreverses: false)
                ) {
                    rotationAngle = 360
                }
            }
        }
    }
}

// MARK: - Success View (Preserved for compatibility)

struct PremiumSuccessView: View {
    let title: String
    let message: String
    let onDone: () -> Void
    
    @State private var showCheckmark = false
    @State private var celebrationScale = 0.5
    
    var body: some View {
        VStack(spacing: 32) {
            // Success Animation
            ZStack {
                // Celebration rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            Color.successGreen.opacity(0.2 - Double(index) * 0.05),
                            lineWidth: 2
                        )
                        .frame(width: 80 + CGFloat(index * 30))
                        .scaleEffect(celebrationScale + Double(index) * 0.1)
                        .opacity(showCheckmark ? 1.0 : 0.0)
                        .animation(
                            .easeOut(duration: 0.8 + Double(index) * 0.2)
                            .delay(Double(index) * 0.1),
                            value: showCheckmark
                        )
                }
                
                // Success checkmark
                ZStack {
                    Circle()
                        .fill(Color.successGreen)
                        .frame(width: 60)
                        .shadow(color: .successGreen.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1.0 : 0.0)
                }
                .scaleEffect(showCheckmark ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showCheckmark)
            }
            
            // Success Message
            VStack(spacing: 12) {
                Text(title)
                    .font(.brandHeadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.brandBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showCheckmark ? 1.0 : 0.0)
            .offset(y: showCheckmark ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: showCheckmark)
            
            // Done Button
            PremiumButton("Done", style: .primary) {
                onDone()
            }
            .opacity(showCheckmark ? 1.0 : 0.0)
            .offset(y: showCheckmark ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.5), value: showCheckmark)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            // Add haptic feedback
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            // Start animations
            withAnimation {
                showCheckmark = true
                celebrationScale = 1.2
            }
        }
    }
}

// MARK: - Preview

#Preview("Loading States") {
    VStack(spacing: 40) {
        PremiumLoadingView(
            title: "Discovering travel moments",
            subtitle: "AI is mapping your journey",
            progress: 0.65,
            estimatedSeconds: 12
        )
        .frame(height: 500)
        
        CompactLoadingView(message: "Saving places...", progress: nil)
        
        PremiumSuccessView(
            title: "Success!",
            message: "Added 3 places to 2 collections"
        ) {}
        .frame(height: 400)
    }
    .background(Color.warmWhite)
}