//
//  SharedUIComponents.swift
//  Share Extension
//
//  Premium UI components for Share Extension
//  Created by Volodymyr Piskun on 05.09.2025.
//

import SwiftUI

// MARK: - Premium Button

struct PremiumButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case compact
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && isEnabled {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .medium))
                }
                
                Text(title)
                    .font(textFont)
                    .fontWeight(.medium)
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            .opacity(isEnabled && !isLoading ? 1.0 : 0.6)
            .scaleEffect(isEnabled ? 1.0 : 0.98)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
        }
        .disabled(!isEnabled || isLoading)
    }
    
    // MARK: - Style Properties
    
    private var backgroundColor: Color {
        switch style {
        case .primary, .compact:
            return Color.coralHeart
        case .secondary:
            return Color.oceanTeal.opacity(0.1)
        case .destructive:
            return Color.red
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .destructive, .compact:
            return .white
        case .secondary:
            return Color.oceanTeal
        }
    }
    
    private var strokeColor: Color {
        switch style {
        case .primary, .destructive, .compact:
            return .clear
        case .secondary:
            return Color.oceanTeal
        }
    }
    
    private var strokeWidth: CGFloat {
        style == .secondary ? 1 : 0
    }
    
    private var buttonHeight: CGFloat {
        style == .compact ? 44 : 56
    }
    
    private var cornerRadius: CGFloat {
        style == .compact ? 12 : 16
    }
    
    private var textFont: Font {
        style == .compact ? .system(size: 15, weight: .medium) : .system(size: 17, weight: .semibold)
    }
    
    private var iconSize: CGFloat {
        style == .compact ? 16 : 18
    }
}

// MARK: - Compact Premium Button

struct CompactPremiumButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        PremiumButton(
            title,
            icon: icon,
            style: .compact,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }
}

// MARK: - Premium Loading View

struct PremiumLoadingView: View {
    let title: String
    let subtitle: String?
    let style: LoadingStyle
    
    enum LoadingStyle {
        case inline
        case fullscreen
        case compact
    }
    
    init(
        title: String = "Loading...",
        subtitle: String? = nil,
        style: LoadingStyle = .inline
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            // Premium spinner with coral gradient
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: strokeWidth)
                    .frame(width: spinnerSize, height: spinnerSize)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        Color.coralHeart,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .frame(width: spinnerSize, height: spinnerSize)
                    .rotationEffect(.degrees(-90))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                            // Animation handled by SwiftUI
                        }
                    }
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(titleFont)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(subtitleFont)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: style == .fullscreen ? .infinity : nil)
        .frame(maxHeight: style == .fullscreen ? .infinity : nil)
    }
    
    // MARK: - Style Properties
    
    private var spinnerSize: CGFloat {
        switch style {
        case .fullscreen: return 60
        case .inline: return 40
        case .compact: return 24
        }
    }
    
    private var strokeWidth: CGFloat {
        switch style {
        case .fullscreen: return 4
        case .inline: return 3
        case .compact: return 2
        }
    }
    
    private var spacing: CGFloat {
        switch style {
        case .fullscreen: return 24
        case .inline: return 16
        case .compact: return 8
        }
    }
    
    private var titleFont: Font {
        switch style {
        case .fullscreen: return .system(size: 22, weight: .medium)
        case .inline: return .system(size: 17, weight: .medium)
        case .compact: return .system(size: 15, weight: .medium)
        }
    }
    
    private var subtitleFont: Font {
        switch style {
        case .fullscreen: return .system(size: 15, weight: .regular)
        case .inline: return .system(size: 13, weight: .regular)
        case .compact: return .system(size: 11, weight: .regular)
        }
    }
}

// MARK: - Place Selection Card

struct PlaceSelectionCard: View {
    let place: PlaceWithSelection
    let isSelected: Bool
    let onToggle: () -> Void
    
    @State private var isPressed = false
    @State private var showSelection = false
    
    var body: some View {
        Button(action: {
            // Heavy impact for selection
            let impact = UIImpactFeedbackGenerator(style: isSelected ? .light : .medium)
            impact.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showSelection = !isSelected
            }
            onToggle()
        }) {
            HStack(spacing: 16) {
                // Premium location icon with animation
                ZStack {
                    // Animated background circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected 
                                    ? [Color.coralHeart.opacity(0.2), Color.coralHeart.opacity(0.1)]
                                    : [Color.oceanTeal.opacity(0.15), Color.oceanTeal.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                    
                    // Icon with color animation
                    // Use icon fallback here; selection row now prefers image when provided
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? Color.coralHeart : Color.oceanTeal)
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }
                
                // Rich place details
                VStack(alignment: .leading, spacing: 4) {
                    // Place name with proper weight
                    Text(place.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.deepNavy)
                        .lineLimit(1)
                    
                    // Location context with icon
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text(place.displayAddress)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Confidence score as visual indicator
                    if place.confidenceScore > 0 {
                        HStack(spacing: 4) {
                            // Confidence dots
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(
                                        index < Int(place.confidenceScore * 3) 
                                            ? Color.sunsetGold 
                                            : Color.gray.opacity(0.2)
                                    )
                                    .frame(width: 4, height: 4)
                            }
                            
                            Text("\(Int(place.confidenceScore * 100))% match")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.sunsetGold)
                        }
                    }
                }
                
                Spacer()
                
                // Premium selection indicator
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            isSelected 
                                ? Color.coralHeart 
                                : Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 2.5 : 1.5
                        )
                        .frame(width: 28, height: 28)
                        .scaleEffect(isSelected ? 1.0 : 0.95)
                    
                    // Inner fill with animation
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.coralHeart, Color(hex: "FF8A5B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 20, height: 20)
                            .transition(.scale.combined(with: .opacity))
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected 
                            ? Color.coralHeart.opacity(0.05)
                            : Color.white
                    )
                    .shadow(
                        color: isSelected 
                            ? Color.coralHeart.opacity(0.15)
                            : Color.black.opacity(0.05),
                        radius: isSelected ? 12 : 8,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected 
                            ? Color.coralHeart.opacity(0.3)
                            : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Collection Cards

struct GridPlaceCollectionCard: View {
    let collection: PlaceCollection
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var imageLoaded = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 0) {
                // Cover Image container
                GeometryReader { geometry in
                    ZStack {
                        // Background gradient
                        Rectangle()
                            .fill(Color.themeGradient(for: collection.themeColor))
                        
                        // Actual image
                        if let imageUrl = collection.coverImageUrl {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            imageLoaded = true
                                        }
                                    }
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.themeGradient(for: collection.themeColor))
                            }
                        } else {
                            Rectangle()
                                .fill(Color.themeGradient(for: collection.themeColor))
                        }
                        
                        // Enhanced gradient overlay for premium text readability
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.15), Color.black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Premium selection badge with gradient and proper overlap
                        if isSelected {
                            VStack {
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "FF6B7A"), Color(hex: "FF8A5B")],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 28, height: 28)
                                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.trailing, -8) // Overlaps corner by 8pt
                                .padding(.top, -8)
                                Spacer()
                            }
                            .scaleEffect(isSelected ? 1.0 : 0.5)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isSelected)
                        }
                    }
                }
                .frame(height: 120)
                .clipShape(
                    .rect(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 20
                    )
                )
                
                // Collection Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "1B2B4D")) // Deep Navy for primary text
                        .lineLimit(1)
                    
                    Text(collection.placeCountText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(UIColor.secondaryLabel)) // iOS standard secondary
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: isSelected ? Color(hex: "FF6B7A").opacity(0.2) : Color.black.opacity(0.08),
                        radius: isSelected ? 20 : 12,
                        x: 0,
                        y: 4
                    )
            )
            .scaleEffect(isPressed ? 0.96 : (isSelected ? 1.02 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct NewPlaceCollectionCard: View {
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 0) {
                // Image-based layout matching other cards
                ZStack {
                    // Subtle gradient background instead of plain color
                    LinearGradient(
                        colors: [
                            Color(UIColor.systemGray6),
                            Color(UIColor.systemGray5).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Center icon with coral color
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(Color(hex: "FF6B7A")) // Coral Heart, not pink
                    }
                    
                    // Gradient overlay for consistency
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.1), Color.black.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(height: 120)
                .clipShape(
                    .rect(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 20
                    )
                )
                
                // Bottom section matching collection cards
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Collection")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "1B2B4D")) // Deep Navy
                    Text("Create new")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Section Headers

struct PlaceSectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    
    init(_ title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.coralHeart)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - Selection Toggle Buttons

struct SelectionToggleButtons: View {
    let totalCount: Int
    let selectedCount: Int
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelectAll) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 13, weight: .medium))
                    Text("Select All")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.coralHeart)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.coralHeart.opacity(0.1))
                )
            }
            
            Button(action: onDeselectAll) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 13, weight: .medium))
                    Text("Deselect All")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
            
            Spacer()
            
            Text("\(selectedCount)/\(totalCount)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - New Collection Sheet

struct NewPlaceCollectionSheet: View {
    @Binding var isPresented: Bool
    let onCreate: (String, String?, String?) -> Void
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedTheme = "coral"
    @State private var isCreating = false
    
    private let themes = ["coral", "gold", "teal", "sage"]
    
    var body: some View {
        // WARNING: NO NavigationView in Share Extensions!
        // iOS provides the navigation container automatically
        ScrollView {
            VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Collection Name")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        
                        TextField("Enter collection name", text: $name)
                            .textFieldStyle(.plain)
                            .premiumTextFieldStyle()
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Description (Optional)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        
                        TextField("Describe your collection", text: $description, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(3...6)
                            .premiumTextFieldStyle(isMultiline: true)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Theme")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(themes, id: \.self) { theme in
                                Button(action: { selectedTheme = theme }) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.themeGradient(for: theme))
                                        .frame(height: 60)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedTheme == theme ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                        .overlay(
                                            Text(theme.capitalized)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            // Create button only - iOS provides Cancel in the nav bar
            PremiumButton(
                "Create Collection",
                isLoading: isCreating,
                isEnabled: !name.isEmpty && !isCreating
            ) {
                isCreating = true
                onCreate(name, description.isEmpty ? nil : description, selectedTheme)
                isCreating = false
                isPresented = false
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Custom Text Field Style

struct PremiumTextFieldStyle: ViewModifier {
    let isMultiline: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: isMultiline ? 88 : 48)
            .background(Color(hex: "F2F2F7"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.clear, lineWidth: 0)
            )
    }
}

extension View {
    func premiumTextFieldStyle(isMultiline: Bool = false) -> some View {
        modifier(PremiumTextFieldStyle(isMultiline: isMultiline))
    }
}