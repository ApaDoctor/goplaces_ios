//
//  MainTabView.swift
//  GoPlaces
//
//  Created by Volodymyr Piskun on 03.09.2025.
//

import SwiftUI
import Combine

struct MainTabView: View {
    
    @State private var selectedTab: Tab = .collections
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Collections Tab
            CollectionsView()
                .tabItem {
                    Image(systemName: selectedTab == .collections ?
                          "square.stack.3d.up.fill" :
                          "square.stack.3d.up")
                    Text(AppConstants.UI.TabView.collectionsTitle)
                }
                .tag(Tab.collections)
            
            // Plan Tab (placeholder for now)
            PlaceholderScreen(title: AppConstants.UI.TabView.planTitle)
                .tabItem {
                    Image(systemName: selectedTab == .plan ?
                          AppConstants.UI.TabView.planIcon :
                          "map")
                    Text(AppConstants.UI.TabView.planTitle)
                }
                .tag(Tab.plan)

            // My Trips Tab (placeholder for now)
            PlaceholderScreen(title: AppConstants.UI.TabView.myTripsTitle)
                .tabItem {
                    Image(systemName: selectedTab == .myTrips ?
                          AppConstants.UI.TabView.myTripsIcon :
                          "location.north.circle")
                    Text(AppConstants.UI.TabView.myTripsTitle)
                }
                .tag(Tab.myTrips)
        }
        .tint(DesignSystem.Colors.coralHeart)
        .onChange(of: selectedTab) { _, newValue in
            HapticManager.shared.trigger(.tabSwitch)
        }
        .onReceive(deepLinkManager.$pendingRoute.compactMap { $0 }) { route in
            switch route {
            case .collections:
                selectedTab = .collections
                // Trigger a refresh of collections when deep linked into this tab
                NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
            case .plan:
                selectedTab = .plan
            case .myTrips:
                selectedTab = .myTrips
            }
            // Clear the pending route after handling so repeated URLs can re-trigger
            deepLinkManager.pendingRoute = nil
        }
    }
}

// MARK: - Tab Enumeration
private enum Tab: CaseIterable {
    case collections
    case plan
    case myTrips
    
    var title: String {
        switch self {
        case .collections:
            return AppConstants.UI.TabView.collectionsTitle
        case .plan:
            return AppConstants.UI.TabView.planTitle
        case .myTrips:
            return AppConstants.UI.TabView.myTripsTitle
        }
    }
    
    var icon: String {
        switch self {
        case .collections:
            return "square.stack.3d.up"
        case .plan:
            return AppConstants.UI.TabView.planIcon
        case .myTrips:
            return AppConstants.UI.TabView.myTripsIcon
        }
    }
}

// MARK: - Placeholder Screen
private struct PlaceholderScreen: View {
    let title: String
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveCardBackground.ignoresSafeArea()
                Text(title)
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(Color.adaptivePrimaryText)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(SwiftDataStack.shared.container)
}