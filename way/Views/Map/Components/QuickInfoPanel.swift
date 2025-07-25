//
//  QuickInfoPanel.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Map/Components/QuickInfoPanel.swift
import SwiftUI

struct QuickInfoPanel: View {
    @EnvironmentObject var gameManager: GameManager
    
    // 상위 5개 인기 상품
    private var topItems: [(String, (district: SeoulDistrict, price: Int))] {
        Array(gameManager.priceBoard.sorted { $0.value.price > $1.value.price }.prefix(5))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🔥 인기 상품")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("최고가 지역")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(topItems.enumerated()), id: \.offset) { index, item in
                        QuickInfoCard(
                            itemName: item.0,
                            district: item.1.district,
                            price: item.1.price,
                            rank: index + 1
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(12)
    }
}

// =====================================
