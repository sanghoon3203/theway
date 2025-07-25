//
//  BuyItemRow.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Merchant/Components/BuyItemRow.swift
import SwiftUI

struct BuyItemRow: View {
    let item: TradeItem
    let isEnabled: Bool
    let onPurchase: () -> Void
    @EnvironmentObject var gameManager: GameManager
    
    private var canAfford: Bool {
        gameManager.player.money >= item.currentPrice
    }
    
    private var hasSpace: Bool {
        gameManager.player.inventory.count < gameManager.player.maxInventorySize
    }
    
    private var canPurchase: Bool {
        isEnabled && canAfford && hasSpace
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(item.grade.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.grade.color)
                        .cornerRadius(4)
                }
                
                Text(item.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !canAfford {
                    Text("자금 부족")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if !hasSpace {
                    Text("인벤토리 가득참")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.currentPrice.formatted())원")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(canAfford ? .green : .red)
                
                Button("구매") {
                    onPurchase()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(canPurchase ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(6)
                .disabled(!canPurchase)
            }
        }
        .padding(.vertical, 4)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}
