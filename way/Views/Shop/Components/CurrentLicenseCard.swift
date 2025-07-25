//
//  CurrentLicenseCard.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Shop/Components/CurrentLicenseCard.swift
import SwiftUI

struct CurrentLicenseCard: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text("현재 라이센스")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(gameManager.player.currentLicense.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("레벨 \(gameManager.player.currentLicense.rawValue)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 라이센스 혜택
            VStack(spacing: 4) {
                Text("현재 혜택:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("인벤토리 용량: \(gameManager.player.maxInventorySize)개")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// =====================================