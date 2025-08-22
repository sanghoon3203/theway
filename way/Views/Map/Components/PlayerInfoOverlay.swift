// 📁 Views/Map/Components/PlayerInfoOverlay.swift
import SwiftUI

struct PlayerInfoOverlayMoneyInfo: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack(spacing: 12) {
            // 자금 표시
            MoneyInfoCard()
        
        }
    }
}
struct PlayerInfoOverlayLisenceInfo: View {
    @EnvironmentObject var gameManager: GameManager
    var body: some View {
        HStack(spacing: 12) {
            // 자금 표시
            LicenseInfoCard()
        }
    }
    
    
}
struct MoneyInfoCard: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        ZStack {
            // 배경 버튼 이미지
            Image("rengtangle_button")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 45)
            
            // 텍스트 내용
            VStack(spacing: 2) {
                Text("소지금")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
                
                Text("\(formatMoney(gameManager.player.money))원")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
            }
        }
    }
    
    private func formatMoney(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

struct LicenseInfoCard: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        ZStack {
            // 배경 버튼 이미지
            Image("rengtangle_button")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 45)
            
            // 텍스트 내용
            VStack(spacing: 2) {
                Text("상인등급")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
                
                Text(gameManager.player.currentLicense.displayName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
            }
        }
    }
}

