//
//  PetCard.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Shop/Components/PetCard.swift
import SwiftUI

struct PetCard: View {
    let pet: Pet
    let action: () -> Void
    @EnvironmentObject var gameManager: GameManager
    
    private var canAfford: Bool {
        gameManager.player.money >= pet.price
    }
    
    private var alreadyOwned: Bool {
        gameManager.player.pets.contains { $0.name == pet.name }
    }
    
    var body: some View {
        HStack {
            // 펫 아이콘
            VStack {
                Image(systemName: petIcon(for: pet.type))
                    .font(.system(size: 30))
                    .foregroundColor(petColor(for: pet.type))
                
                Text(pet.name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 60)
            
            // 펫 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(pet.specialAbility)
                    .font(.subheadline)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Spacer()
            
            // 가격 및 구매 버튼
            VStack(alignment: .trailing, spacing: 8) {
                Text("\(pet.price.formatted())원")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(canAfford ? .primary : .red)
                
                if alreadyOwned {
                    Text("보유중")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                        .font(.caption)
                } else {
                    Button("구매") {
                        action()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(canAfford ? Color.purple : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(!canAfford)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func petIcon(for type: Pet.PetType) -> String {
        switch type {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .horse: return "hare.fill" // 말 아이콘이 없어서 토끼로 대체
        }
    }
    
    private func petColor(for type: Pet.PetType) -> Color {
        switch type {
        case .dog: return .brown
        case .cat: return .orange
        case .horse: return .green
        }
    }
}