import SwiftUI

struct HeroImageCarousel: View {
    let images: [String]
    @State private var currentPage = 0
    @Namespace private var animationNamespace
    
    private let imageHeight: CGFloat = UIScreen.main.bounds.height * 0.4
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if images.isEmpty {
                emptyState
            } else {
                carousel
                pageIndicator
            }
        }
        .frame(height: imageHeight)
        .background(Color.black)
    }
    
    private var carousel: some View {
        TabView(selection: $currentPage) {
            ForEach(images.indices, id: \.self) { index in
                AsyncImage(url: URL(string: images[index])) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(hex: "FFFFFF"))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: imageHeight)
                            .clipped()
                    case .failure(_):
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(Color.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(hex: "FFFFFF"))
                    @unknown default:
                        EmptyView()
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(Color.gray)
            
            Text("No Images")
                .font(.system(size: 17))
                .foregroundColor(Color.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "FFFFFF"))
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 4) {
            ForEach(images.indices, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.white : Color.white.opacity(0.5))
                    .frame(width: currentPage == index ? 8 : 6,
                           height: currentPage == index ? 8 : 6)
                    .scaleEffect(currentPage == index ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    .onTapGesture {
                        withAnimation {
                            currentPage = index
                        }
                    }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
                .background(
                    .ultraThinMaterial,
                    in: Capsule()
                )
        )
        .padding(.bottom, 20)
    }
}