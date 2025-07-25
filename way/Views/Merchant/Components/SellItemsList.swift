//
//  SellItemsList.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Merchant/Components/SellItemsList.swift
import SwiftUI

struct SellItemsList: View {
    let merchant: Merchant
    let isEnabled: Bool
    @EnvironmentObject var gameManager: GameManager
    
    private var sellableItems: [TradeItem] {
        gameManager.player.inventory.filter { item in
            item.requiredLicense.rawValue <= merchant.requiredLicense.rawValue
        }
    }
    
    var body: some View {
        if sellableItems.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "bag")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                
                Text("판매 가능한 상품이 없습니다")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
        } else {
            List {
                ForEach(sellableItems) { item in
                    SellItemRow(item: item, merchant: merchant, isEnabled: isEnabled) {
                        let success = gameManager.sellItem(item, to: merchant, at: merchant.coordinate)
                        if success {
                            // 판매 성공 피드백
                        }
                    }
                    .environmentObject(gameManager)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}