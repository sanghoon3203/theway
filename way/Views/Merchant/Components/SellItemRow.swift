// 📁 Views/Merchant/Components/SellItemRow.swift
import SwiftUI

struct SellItemRow: View {
    let item: TradeItem
    let merchant: Merchant
    let isEnabled: Bool
    let onSell: () -> Void
    @EnvironmentObject var gameManager: GameManager
    
    private var estimatedPrice: Int {
        // 상인의 가격 계산 메서드 사용 (판매 시에는 더 낮은 가격으로)
        let buyPrice = merchant.getFinalPrice(for: item, player: gameManager.player)
        return Int(Double(buyPrice) * 0.7) // 구매가의 70%로 판매
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
                    
                    // grade → rarity로 변경
                    Text(item.rarity.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.rarity.color.color)
                        .cornerRadius(4)
                }
                
                Text("구매가: \(item.currentPrice.formatted())원")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("예상 수익: +\(profit.formatted())원")
                    .font(.caption)
                    .foregroundColor(profit > 0 ? .green : .red)
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
