//
//  SellItemRow.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Merchant/Components/SellItemRow.swift
import SwiftUI

struct SellItemRow: View {
    let item: TradeItem
    let merchant: Merchant
    let isEnabled: Bool
    let onSell: () -> Void
    @EnvironmentObject var gameManager: GameManager
    
    private var estimatedPrice: Int {
        // 간단한 보너스 계산 (실제로는 거리 기반)
        Int(Double(item.currentPrice) * 1.3)
    }
    
    private var profit: Int {
        estimatedPrice - item.currentPrice
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
                
                Text("구매가: \(item.currentPrice.formatted())원")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("예상 수익: +\(profit.formatted())원")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(estimatedPrice.formatted())원")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Button("판매") {
                    onSell()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isEnabled ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(6)
                .disabled(!isEnabled)
            }
        }
        .padding(.vertical, 4)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}