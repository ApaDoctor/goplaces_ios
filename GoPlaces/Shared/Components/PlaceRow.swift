import SwiftUI

struct PlaceRow: View {
    let place: Place
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    let onFavorite: (() -> Void)?
    
    @State private var isPressed = false
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var isHorizontalSwipe = false
    @State private var isFavorite = false
    
    private let thumbnailSize: CGFloat = 80
    private let swipeThreshold: CGFloat = 100
    
    init(
        place: Place,
        onTap: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        onFavorite: (() -> Void)? = nil
    ) {
        self.place = place
        self.onTap = onTap
        self.onDelete = onDelete
        self.onFavorite = onFavorite
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Swipe actions background
            HStack(spacing: 0) {
                if onFavorite != nil {
                    favoriteAction
                }
                if onDelete != nil {
                    deleteAction
                }
            }
            
            // Main content
            Group {
                if onFavorite != nil || onDelete != nil {
                    mainContent
                        .offset(x: offset)
                        .gesture(swipeGesture)
                } else {
                    // No swipe actions configured → do not attach drag gesture to avoid blocking vertical scroll
                    mainContent
                        .offset(x: 0)
                }
            }
        }
        .background(Color(hex: "FFFFFF"))
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
    }
    
    private var mainContent: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: URL(string: place.photoURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_), .empty:
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(Color.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "F5F5F5"))
                @unknown default:
                    ProgressView()
                }
            }
            .frame(width: thumbnailSize, height: thumbnailSize)
            .cornerRadius(8)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(place.displayName)
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(Color.black)
                    .lineLimit(1)
                
                // Address
                Text(place.displayAddress)
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray)
                    .lineLimit(1)
                
                // Bottom row
                HStack(spacing: 8) {
                    // Rating
                    if place.rating > 0 {
                        RatingBadge(rating: place.rating, reviewCount: nil, showReviewCount: false)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.gray.opacity(0.5))
        }
        .padding(12)
        .background(Color(hex: "FFFFFF"))
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            HapticManager.shared.impact(intensity: 0.5)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
                onTap()
            }
        }
    }
    
    private var deleteAction: some View {
        Button(action: {
            HapticManager.shared.impact(intensity: 0.8)
            onDelete?()
        }) {
            VStack {
                Image(systemName: "trash.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .frame(width: swipeThreshold)
            .frame(maxHeight: .infinity)
            .background(Color.red)
        }
    }
    
    private var favoriteAction: some View {
        Button(action: {
            HapticManager.shared.impact(intensity: 0.7)
            onFavorite?()
        }) {
            VStack {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .frame(width: swipeThreshold)
            .frame(maxHeight: .infinity)
            .background(Color(hex: "007AFF"))
        }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Decide if this drag is horizontal enough; otherwise let vertical scroll win
                if !isDragging {
                    isDragging = true
                    let dx = abs(value.translation.width)
                    let dy = abs(value.translation.height)
                    isHorizontalSwipe = dx > (dy + 6) // favor vertical scroll unless clearly horizontal
                    if isHorizontalSwipe {
                        HapticManager.shared.impact(intensity: 0.4)
                    }
                }
                guard isHorizontalSwipe else { return }
                let translation = value.translation.width
                if translation < 0 { // Swiping left
                    offset = max(translation, -swipeThreshold * 2)
                }
            }
            .onEnded { value in
                let wasHorizontal = isHorizontalSwipe
                isDragging = false
                isHorizontalSwipe = false
                guard wasHorizontal else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if value.translation.width < -swipeThreshold {
                        offset = -swipeThreshold * (onFavorite != nil && onDelete != nil ? 2 : 1)
                    } else {
                        offset = 0
                    }
                }
            }
    }
}