//
//  PetShopView.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Shop/Components/PetShopView.swift
import SwiftUI

struct PetShopView: View {
    @EnvironmentObject var gameManager: GameManager
    
    // 구매 가능한 펫들
    private let pets = [
        Pet(name: "강아지", type: .dog, price: 30000, specialAbility: "위험 감지 +10%"),
        Pet(name: "고양이", type: .cat, price: 25000, specialAbility: "운 +5%"),
        Pet(name: "말", type: .horse, price: 100000, specialAbility: "이동속도 +20%")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 안내 문구
                VStack(spacing: 8) {
                    Text("🐾 펫 상점")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("펫은 특별한 능력으로 무역을 도와줍니다!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // 펫 리스트
                ForEach(pets, id: \.id) { pet in
                    PetCard(pet: pet) {
                        purchasePet(pet)
                    }
                    .environmentObject(gameManager)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func purchasePet(_ pet: Pet) {
        guard gameManager.player.money >= pet.price else { return }
        
        gameManager.player.money -= pet.price
        gameManager.player.pets.append(pet)
    }
}