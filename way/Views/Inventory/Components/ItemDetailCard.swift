//
//  ItemDetailCard.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Inventory/Components/ItemDetailCard.swift
import SwiftUI

struct ItemDetailCard: View {
    let item: TradeItem
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(item.rarity.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(item.rarity.color))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            Text(item.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(item.category.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("구매가: \(item.currentPrice.formatted())원")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
