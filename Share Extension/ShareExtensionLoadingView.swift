//
//  ShareExtensionLoadingView.swift
//  Share Extension
//
//  Premium loading views optimized for Share Extension
//  Created by Volodymyr Piskun on 05.09.2025.
//

import SwiftUI
import Foundation

// MARK: - Share Extension Loading Manager

@MainActor
class ShareExtensionLoadingManager: ObservableObject {
    @Published var title: String = "Finding travel moments"
    @Published var stageMessage: String = "Connecting to AI"
    @Published var progress: Double? = nil
    @Published var isLoading: Bool = false
    
    func startLoading(title: String) {
        self.title = title
        self.isLoading = true
        self.progress = nil
    }
    
    func updateFromTaskResponse(_ response: TaskResponse) {
        self.stageMessage = response.stageMessage
        self.progress = response.progress.map { Double($0) }
    }
    
    func updateFromProcessingStatus(_ status: ProcessingStatusResponse) {
        self.stageMessage = status.stageMessage
        self.progress = status.progress.map { Double($0) }
    }
    
    func stopLoading() {
        self.isLoading = false
    }
    
    func reset() {
        self.title = "Finding travel moments"
        self.stageMessage = "Connecting to AI"
        self.progress = nil
        self.isLoading = false
    }
}

// MARK: - Premium Discovery Loading View

struct ShareExtensionLoadingView: View {
    let title: String
    let stageMessage: String?
    let progress: Double?
    let showProgress: Bool
    
    @State private var pinScale: CGFloat = 0
    @State private var pulseRings: [PulseRing] = []
    @State private var particles: [DiscoveryParticle] = []
    @State private var heartbeatScale: CGFloat = 1.0
    @State private var progressValue: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    private let heartbeatTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    private let particleTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()
    
    init(
        title: String,
        stageMessage: String? = nil,
        progress: Double? = nil,
        showProgress: Bool = true
    ) {
        self.title = title
        self.stageMessage = stageMessage
        self.progress = progress
        self.showProgress = showProgress
    }
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white
                .ignoresSafeArea()
            
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.white,
                    Color.gray.opacity(0.03)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Central Discovery Animation
                ZStack {
                    // Pulse rings - alternating coral and teal
                    ForEach(Array(pulseRings.enumerated()), id: \.element.id) { index, ring in
                        Circle()
                            .stroke(
                                index % 2 == 0 ? Color.coralHeart.opacity(ring.opacity * 0.6) : Color.oceanTeal.opacity(ring.opacity * 0.4),
                                lineWidth: ring.lineWidth
                            )
                            .frame(width: ring.size, height: ring.size)
                    }
                    
                    // Progress ring
                    if showProgress {
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 3)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: progressValue)
                            .stroke(
                                Color.coralHeart,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: progressValue)
                    }
                    
                    // Discovery particles - teal accents
                    ForEach(particles) { particle in
                        Circle()
                            .fill(Color.oceanTeal.opacity(0.8))
                            .frame(width: particle.size, height: particle.size)
                            .opacity(particle.opacity)
                            .blur(radius: 1)
                            .position(particle.position)
                    }
                    
                    // Central pin with heartbeat - solid coral
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Color.coralHeart)
                        .scaleEffect(pinScale * heartbeatScale)
                        .shadow(color: Color.coralHeart.opacity(0.3), radius: 20, x: 0, y: 0)
                }
                .frame(width: 250, height: 250)
                
                Spacer()
                    .frame(height: 40)
                
                // Text content
                VStack(spacing: 16) {
                    Text(title)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.deepNavy)
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                    
                    if let stageMessage = stageMessage {
                        Text(stageMessage)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color.deepNavy.opacity(0.6))
                            .opacity(textOpacity)
                            .offset(y: textOffset)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Bottom glassmorphic preview (placeholder for discovered places)
                GlassmorphicCard()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            startAnimations()
            if let progress = progress {
                progressValue = progress / 100.0
            }
        }
        .onChange(of: progress) { newValue in
            if let newValue = newValue {
                withAnimation(.easeInOut(duration: 0.5)) {
                    progressValue = newValue / 100.0
                }
            }
        }
        .onReceive(timer) { _ in
            createPulseRing()
        }
        .onReceive(heartbeatTimer) { _ in
            heartbeat()
        }
        .onReceive(particleTimer) { _ in
            createParticle()
        }
    }
    
    private func startAnimations() {
        // Pin entrance animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            pinScale = 1.0
        }
        
        // Text fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOpacity = 1.0
            textOffset = 0
        }
    }
    
    private func createPulseRing() {
        let ring = PulseRing()
        pulseRings.append(ring)
        
        // Animate the ring
        withAnimation(.easeOut(duration: 2.4)) {
            if let index = pulseRings.firstIndex(where: { $0.id == ring.id }) {
                pulseRings[index].size = 300
                pulseRings[index].opacity = 0
            }
        }
        
        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            pulseRings.removeAll { $0.id == ring.id }
        }
    }
    
    private func heartbeat() {
        withAnimation(.easeInOut(duration: 0.3)) {
            heartbeatScale = 1.15
        }
        
        withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
            heartbeatScale = 1.0
        }
    }
    
    private func createParticle() {
        guard particles.count < 5 else { return }
        
        let angle = Double.random(in: 0...(2 * .pi))
        let radius = Double.random(in: 60...100)
        let x = 125 + CGFloat(cos(angle) * radius)
        let y = 125 + CGFloat(sin(angle) * radius)
        
        var particle = DiscoveryParticle(position: CGPoint(x: x, y: y))
        particles.append(particle)
        
        // Animate particle
        withAnimation(.easeIn(duration: 0.5)) {
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                particles[index].opacity = 1.0
                particles[index].size = 6
            }
        }
        
        withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                particles[index].opacity = 0
            }
        }
        
        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            particles.removeAll { $0.id == particle.id }
        }
    }
}

// MARK: - Supporting Views and Models

struct PulseRing: Identifiable {
    let id = UUID()
    var size: CGFloat = 80
    var opacity: Double = 0.6
    var lineWidth: CGFloat = 1.5
}

struct DiscoveryParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat = 0
    var opacity: Double = 0
}

struct GlassmorphicCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .frame(height: 100)
            .shadow(color: Color.gray.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .overlay(
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.05), Color.gray.opacity(0.02)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .shimmer()
                    }
                }
                .padding()
            )
    }
}

struct NoiseTextureView: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for _ in 0..<500 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let opacity = Double.random(in: 0.02...0.05)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
        }
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .animation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                phase = 1
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

