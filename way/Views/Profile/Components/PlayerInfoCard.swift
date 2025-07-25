//
//  PlayerInfoCard.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Profile/Components/PlayerInfoCard.swift
import SwiftUI

struct PlayerInfoCard: View {
    let player: Player
    
    var body: some View {
        VStack(spacing: 16) {
            // 프로필 이미지
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                )
            
            Text(player.name.isEmpty ? "무명의 상인" : player.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(player.currentLicense.title)
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
