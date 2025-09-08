//
//  HapticManager.swift
//  GoPlaces
//
//  Centralized haptic feedback manager for consistent tactile responses
//  Created by Volodymyr Piskun on 06.09.2025.
//

import UIKit
import CoreHaptics

/// Manages all haptic feedback throughout the app
final class HapticManager {
    
    // MARK: - Singleton
    
    static let shared = HapticManager()
    
    // MARK: - Properties
    
    private var engine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    /// Controls whether haptics are enabled (respects system settings)
    private var hapticsEnabled: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // MARK: - Initialization
    
    private init() {
        prepareGenerators()
        setupHapticEngine()
    }
    
    // MARK: - Setup
    
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine creation error: \(error)")
        }
    }
    
    // MARK: - Haptic Feedback Types
    
    enum HapticMoment {
        // UI Interactions
        case selection      // Light tap for selections
        case buttonTap      // Medium tap for buttons
        case toggle         // Light tap for toggles
        case tabSwitch      // Selection changed feedback
        
        // Content Actions
        case swipeAction    // Medium feedback for swipe
        case longPress      // Heavy feedback for long press
        case dragStart      // Soft feedback for drag start
        case dragEnd        // Rigid feedback for drag end
        
        // Status Feedback
        case success        // Success notification
        case warning        // Warning notification
        case error          // Error notification
        
        // Navigation
        case pageTransition // Light feedback for page changes
        case pullToRefresh  // Medium feedback for refresh
        case reachedEnd     // Soft feedback for scroll end
        
        // Custom Patterns
        case favorite       // Double tap pattern for favoriting
        case delete         // Strong feedback for destructive actions
    }
    
    // MARK: - Public Methods
    
    /// Triggers haptic feedback for the specified moment
    func trigger(_ moment: HapticMoment) {
        guard hapticsEnabled else { return }
        
        switch moment {
        case .selection:
            impactLight.impactOccurred()
            
        case .buttonTap:
            impactMedium.impactOccurred()
            
        case .toggle:
            impactLight.impactOccurred()
            
        case .tabSwitch:
            selectionFeedback.selectionChanged()
            
        case .swipeAction:
            impactMedium.impactOccurred()
            
        case .longPress:
            impactHeavy.impactOccurred()
            
        case .dragStart:
            impactSoft.impactOccurred()
            
        case .dragEnd:
            impactRigid.impactOccurred()
            
        case .success:
            notificationFeedback.notificationOccurred(.success)
            
        case .warning:
            notificationFeedback.notificationOccurred(.warning)
            
        case .error:
            notificationFeedback.notificationOccurred(.error)
            
        case .pageTransition:
            impactLight.impactOccurred()
            
        case .pullToRefresh:
            impactMedium.impactOccurred()
            
        case .reachedEnd:
            impactSoft.impactOccurred()
            
        case .favorite:
            performDoubleTap()
            
        case .delete:
            impactHeavy.impactOccurred()
        }
    }
    
    /// Triggers custom intensity impact
    func impact(intensity: CGFloat) {
        guard hapticsEnabled else { return }
        
        let clampedIntensity = max(0, min(1, intensity))
        
        if clampedIntensity < 0.3 {
            impactLight.impactOccurred(intensity: clampedIntensity * 3)
        } else if clampedIntensity < 0.6 {
            impactMedium.impactOccurred(intensity: clampedIntensity * 1.5)
        } else {
            impactHeavy.impactOccurred(intensity: clampedIntensity)
        }
    }
    
    // MARK: - Custom Patterns
    
    private func performDoubleTap() {
        impactLight.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactMedium.impactOccurred()
        }
    }
    
    /// Creates a custom haptic pattern using Core Haptics
    func playCustomPattern(intensity: Float = 1.0, sharpness: Float = 0.5, duration: TimeInterval = 0.1) {
        guard let engine = engine else {
            // Fallback to simple impact if Core Haptics unavailable
            impactMedium.impactOccurred()
            return
        }
        
        let intensityParam = CHHapticEventParameter(
            parameterID: .hapticIntensity,
            value: intensity
        )
        
        let sharpnessParam = CHHapticEventParameter(
            parameterID: .hapticSharpness,
            value: sharpness
        )
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0,
            duration: duration
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // Fallback to simple impact
            impactMedium.impactOccurred()
        }
    }
    
    /// Plays a continuous haptic for drag operations
    func startContinuousHaptic() {
        guard let engine = engine else { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
        
        let continuous = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 100
        )
        
        do {
            let pattern = try CHHapticPattern(events: [continuous], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            
            // Store player reference if needed for stopping
        } catch {
            print("Failed to play continuous haptic: \(error)")
        }
    }
    
    /// Stops any continuous haptic feedback
    func stopContinuousHaptic() {
        engine?.stop()
        setupHapticEngine() // Restart engine for next use
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

struct HapticModifier: ViewModifier {
    let moment: HapticManager.HapticMoment
    let onTrigger: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                HapticManager.shared.trigger(moment)
                onTrigger()
            }
    }
}

extension View {
    /// Adds haptic feedback to tap gestures
    func hapticTap(_ moment: HapticManager.HapticMoment = .selection, perform: @escaping () -> Void) -> some View {
        modifier(HapticModifier(moment: moment, onTrigger: perform))
    }
    
    /// Triggers haptic feedback immediately
    func haptic(_ moment: HapticManager.HapticMoment) -> some View {
        self.onAppear {
            HapticManager.shared.trigger(moment)
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
struct HapticManagerPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Haptic Feedback Test")
                    .font(DesignSystem.Typography.title)
                
                // UI Interactions
                Group {
                    Text("UI Interactions")
                        .font(DesignSystem.Typography.headline)
                    
                    Button("Selection (Light)") {
                        HapticManager.shared.trigger(.selection)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Button Tap (Medium)") {
                        HapticManager.shared.trigger(.buttonTap)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Tab Switch") {
                        HapticManager.shared.trigger(.tabSwitch)
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // Status Feedback
                Group {
                    Text("Status Feedback")
                        .font(DesignSystem.Typography.headline)
                    
                    Button("Success") {
                        HapticManager.shared.trigger(.success)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    
                    Button("Warning") {
                        HapticManager.shared.trigger(.warning)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    
                    Button("Error") {
                        HapticManager.shared.trigger(.error)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                
                Divider()
                
                // Custom Patterns
                Group {
                    Text("Custom Patterns")
                        .font(DesignSystem.Typography.headline)
                    
                    Button("Favorite (Double Tap)") {
                        HapticManager.shared.trigger(.favorite)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Delete (Heavy)") {
                        HapticManager.shared.trigger(.delete)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Button("Custom Pattern") {
                        HapticManager.shared.playCustomPattern(
                            intensity: 0.8,
                            sharpness: 0.7,
                            duration: 0.2
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}

#Preview("Haptic Manager") {
    HapticManagerPreview()
}
#endif