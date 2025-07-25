//
//  PlayerStatusBar.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Map/Components/PlayerStatusBar.swift
import SwiftUI

struct PlayerStatusBar: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack {
            // 왼쪽: 돈과 신뢰도
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "wonsign.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("\(gameManager.player.money.formatted())원")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    
                    Text("신뢰도: \(gameManager.player.trustPoints)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 오른쪽: 라이센스와 인벤토리
            VStack(alignment: .trailing, spacing: 4) {
                Text(gameManager.player.currentLicense.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("인벤토리: \(gameManager.player.inventory.count)/\(gameManager.player.maxInventorySize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// =====================================
