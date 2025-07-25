//
//  QuickInfoCard.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Map/Components/QuickInfoCard.swift
import SwiftUI

struct QuickInfoCard: View {
    let itemName: String
    let district: SeoulDistrict
    let price: Int
    let rank: Int
    
    var body: some View {
        VStack(spacing: 4) {
            // 순위 표시
            Text("\(rank)위")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Text(itemName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(district.rawValue)
                .font(.caption2)
                .foregroundColor(.blue)
            
            Text("\(price.formatted())원")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: 100, height: 80)
        .background(Color.white.opacity(0.9))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}