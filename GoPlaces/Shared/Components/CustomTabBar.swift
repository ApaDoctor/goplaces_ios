//
//  CustomTabBar.swift
//  GoPlaces
//
//  Created by Assistant on 2025-09-06.
//

import SwiftUI
import UIKit

enum CollectionTab: String, CaseIterable {
    case list = "List"
    case map = "Map"
    
    var icon: String {
        switch self {
        case .list:
            return "list.bullet"
        case .map:
            return "map"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: CollectionTab
    
    var body: some View {
        PremiumSegmentedControl(selected: $selectedTab)
            .frame(height: 48)
    }
}

// MARK: - Native UISegmentedControl with brand styling
private struct PremiumSegmentedControl: UIViewRepresentable {
    @Binding var selected: CollectionTab
    
    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: CollectionTab.allCases.map { $0.rawValue })
        control.selectedSegmentIndex = selected == .list ? 0 : 1
        
        // Colors
        control.selectedSegmentTintColor = UIColor(DesignSystem.Colors.coralHeart)
        control.backgroundColor = UIColor.secondarySystemFill
        
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
        control.setTitleTextAttributes(normalAttrs, for: .normal)
        
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
        control.setTitleTextAttributes(selectedAttrs, for: .selected)
        
        // Rounded outer corners only; inner dividers remain square by default
        control.layer.cornerRadius = 12
        control.layer.masksToBounds = true
        control.translatesAutoresizingMaskIntoConstraints = false
        control.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        control.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return control
    }
    
    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        let index = selected == .list ? 0 : 1
        if uiView.selectedSegmentIndex != index {
            uiView.selectedSegmentIndex = index
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(selected: $selected) }
    
    class Coordinator: NSObject {
        var selected: Binding<CollectionTab>
        init(selected: Binding<CollectionTab>) { self.selected = selected }
        @objc func valueChanged(_ sender: UISegmentedControl) {
            selected.wrappedValue = sender.selectedSegmentIndex == 0 ? .list : .map
            HapticManager.shared.impact(intensity: 0.5)
        }
    }
}

// MARK: - Preview
struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomTabBar(selectedTab: .constant(.list))
            CustomTabBar(selectedTab: .constant(.map))
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}