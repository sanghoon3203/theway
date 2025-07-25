//
//  BuyItemsList.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Merchant/Components/BuyItemsList.swift
import SwiftUI

struct BuyItemsList: View {
    let merchant: Merchant
    let isEnabled: Bool
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        List {
            ForEach(merchant.inventory) { item in
                BuyItemRow(item: item, isEnabled: isEnabled) {
                    let success = gameManager.buyItem(item, from: merchant)
                    if success {
                        // 구매 성공 피드백
                    }
                }
                .environmentObject(gameManager)
            }
        }
        .listStyle(PlainListStyle())
    }
}
