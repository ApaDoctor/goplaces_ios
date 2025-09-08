//
//  HoursAndPriceCard.swift
//  GoPlaces
//
//  Created by Assistant on 2025-09-06.
//

import SwiftUI

struct HoursAndPriceCard: View {
    let openingHours: [String: String]?
    let priceLevel: Int?
    let averageCost: String?
    @State private var isExpanded = false
    
    private var todayHours: String? {
        guard let hours = openingHours else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let today = formatter.string(from: Date())
        return hours[today]
    }
    
    private var isOpenNow: Bool {
        // Simplified logic - would need actual time parsing
        todayHours != nil && todayHours != "Closed"
    }
    
    private var priceLevelDisplay: String {
        guard let level = priceLevel else { return "" }
        return String(repeating: "$", count: min(level, 4))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hours & Pricing")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let today = todayHours {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isOpenNow ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(isOpenNow ? "Open now" : "Closed")
                                .font(.subheadline)
                                .foregroundColor(isOpenNow ? .green : .red)
                            
                            Text("·")
                                .foregroundColor(.secondary)
                            
                            Text(today)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                        )
                }
            }
            
            // Price information
            if priceLevel != nil || averageCost != nil {
                HStack(spacing: 20) {
                    if !priceLevelDisplay.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Price Level")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(priceLevelDisplay)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let cost = averageCost {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Average Cost")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(cost)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // Expanded hours
            if isExpanded, let hours = openingHours {
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(weekDays, id: \.self) { day in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            // Let the day name take flexible space and keep it on one line
                            Text(day)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .layoutPriority(1)

                            Spacer(minLength: 12)

                            // Align the hours on the trailing edge with monospaced digits for better visual alignment
                            Text(hours[day] ?? "Closed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private var weekDays: [String] {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    }
}

// MARK: - Preview
struct HoursAndPriceCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HoursAndPriceCard(
                openingHours: [
                    "Monday": "9:00 AM - 10:00 PM",
                    "Tuesday": "9:00 AM - 10:00 PM",
                    "Wednesday": "9:00 AM - 10:00 PM",
                    "Thursday": "9:00 AM - 10:00 PM",
                    "Friday": "9:00 AM - 11:00 PM",
                    "Saturday": "10:00 AM - 11:00 PM",
                    "Sunday": "10:00 AM - 9:00 PM"
                ],
                priceLevel: 3,
                averageCost: "$30-50"
            )
            
            HoursAndPriceCard(
                openingHours: nil,
                priceLevel: 2,
                averageCost: "$15-25"
            )
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}