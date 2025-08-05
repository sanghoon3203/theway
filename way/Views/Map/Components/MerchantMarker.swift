// 📁 Views/Map/Components/MerchantMarker.swift
import SwiftUI

struct MerchantMarker: View {
    let merchant: Merchant
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
                
                // 마커 아이콘
                Image(systemName: iconForMerchantType(merchant.type))
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.2), value: merchant.id)
        }
    }
    
    private func colorForMerchantType(_ type: MerchantType) -> Color {
        switch type {
        case .retail: return .green
        case .artisan: return .blue
        case .collector: return .purple
        case .mystic: return .orange
        }
    }
    
    private func iconForMerchantType(_ type: MerchantType) -> String {
        switch type {
        case .retail: return "cart"
        case .artisan: return "hammer"
        case .collector: return "eye"
        case .mystic: return "sparkles"
        }
    }
}
