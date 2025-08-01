//
//  MerchantMarkerSimple.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Map/Components/MerchantMarkerSimple.swift - 단순한 마커
import SwiftUI

struct MerchantMarkerSimple: View {
    let merchant: Merchant
    let number: Int
    let action: () -> Void
    @EnvironmentObject var gameManager: GameManager
    
    private var canTrade: Bool {
        gameManager.player.currentLicense.rawValue >= merchant.requiredLicense.rawValue
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 마커 배경
                Circle()
                    .fill(colorForMerchantType(merchant.type))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(canTrade ? Color.green : Color.red, lineWidth: 2)
                    )
                
                // 마커 번호 또는 아이콘
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
    
    private func colorForMerchantType(_ type: Merchant.MerchantType) -> Color {
        switch type {
        case .retail: return .green
        case .wholesale: return .blue  
        case .premium: return .purple
        }
    }
}
