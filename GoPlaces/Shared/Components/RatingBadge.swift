import SwiftUI

struct RatingBadge: View {
    let rating: Double
    let reviewCount: Int?
    var showReviewCount: Bool = true
    
    private var formattedRating: String {
        String(format: "%.1f", rating)
    }
    
    private var starCount: Int {
        Int(rating.rounded())
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Stars
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= starCount ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(
                            index <= starCount ?
                            Color(hex: "FFB800") :
                            Color.gray.opacity(0.3)
                        )
                }
            }
            
            // Rating number
            Text(formattedRating)
                .font(.system(size: 12))
                .fontWeight(.semibold)
                .foregroundColor(Color.black)
            
            // Review count
            if showReviewCount, let count = reviewCount {
                Text("(\(count))")
                    .font(.system(size: 10))
                    .foregroundColor(Color.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "FFFFFF"))
        )
    }
}