//
//  MerchantDetailSheet.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Merchant/MerchantDetailSheet.swift
import SwiftUI

struct MerchantDetailSheet: View {
    let merchant: Merchant
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    @State private var showDialogue = false
    
    private var canTrade: Bool {
        gameManager.player.currentLicense.rawValue >= merchant.requiredLicense.rawValue
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상인 정보 헤더
                MerchantHeader(merchant: merchant, canTrade: canTrade)
                
                // 라이센스 경고
                if !canTrade {
                    LicenseWarning(requiredLicense: merchant.requiredLicense)
                }
                
                // 대화/거래 선택 버튼들
                HStack(spacing: 12) {
                    // 대화 버튼
                    Button("대화하기") {
                        showDialogue = true
                    }
                    .buttonStyle(TreasureButtonStyle())
                    
                    // 거래 유형 선택
                    Picker("거래 유형", selection: $selectedTab) {
                        Text("구매").tag(0)
                        Text("판매").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(!canTrade)
                }
                .padding()
                
                // 탭 내용
                if selectedTab == 0 {
                    BuyItemsList(merchant: merchant, isEnabled: canTrade)
                        .environmentObject(gameManager)
                } else {
                    SellItemsList(merchant: merchant, isEnabled: canTrade)
                        .environmentObject(gameManager)
                }
                
                Spacer()
            }
            .navigationTitle(merchant.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("닫기") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showDialogue) {
            MerchantDialogueView(merchant: merchant)
        }
    }
}

// =====================================