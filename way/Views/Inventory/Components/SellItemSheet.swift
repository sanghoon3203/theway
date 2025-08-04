//
//  SellItemSheet.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Inventory/Components/SellItemSheet.swift
import SwiftUI

struct SellItemSheet: View {
    let item: TradeItem
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMerchant: Merchant?
    
    private var nearbyMerchants: [Merchant] {
        // 현재 라이센스로 거래 가능한 상인들만 필터링
        gameManager.merchants.filter { merchant in
            merchant.requiredLicense.rawValue <= gameManager.player.currentLicense.rawValue
        }.prefix(5).map { $0 }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 아이템 정보 카드
                ItemDetailCard(item: item)
                
                // 판매 안내
                Text("판매할 상인 선택")
                    .font(.headline)
                    .fontWeight(.bold)
                
                // 상인 리스트
                if nearbyMerchants.isEmpty {
                    Text("거래 가능한 상인이 없습니다")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(nearbyMerchants), id: \.id) { merchant in
                                MerchantSellCard(merchant: merchant, item: item) {
                                    Task{
                                        await sellToMerchant(merchant)}
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("상품 판매")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("취소") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func sellToMerchant(_ merchant: Merchant) async {
        let success = await gameManager.sellItem(item, to: merchant, at: merchant.coordinate)
        if success {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
