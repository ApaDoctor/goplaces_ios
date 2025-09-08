import SwiftUI

enum PlaceStatus {
    case open
    case closed
    case unknown
    
    var color: Color {
        switch self {
        case .open:
            return Color(hex: "00C853")
        case .closed:
            return Color(hex: "FF1744")
        case .unknown:
            return Color.gray
        }
    }
    
    var text: String {
        switch self {
        case .open:
            return "Open"
        case .closed:
            return "Closed"
        case .unknown:
            return "Unknown"
        }
    }
}

struct StatusBadge: View {
    let status: PlaceStatus
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(status.color.opacity(0.3), lineWidth: status == .open ? 2 : 0)
                        .scaleEffect(isPulsing ? 1.5 : 1.0)
                        .opacity(isPulsing ? 0 : 1)
                        .animation(
                            status == .open ?
                            Animation.easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false) :
                            .default,
                            value: isPulsing
                        )
                )
            
            Text(status.text)
                .font(.system(size: 12))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(status.color.opacity(0.1))
        )
        .onAppear {
            if status == .open {
                isPulsing = true
            }
        }
    }
}