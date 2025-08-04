// 📁 Views/Merchant/Components/SellItemsList.swift - 수정된 버전
import SwiftUI

struct SellItemsList: View {
    let merchant: Merchant
    let isEnabled: Bool
    @EnvironmentObject var gameManager: GameManager
    @State private var isLoading = false // 로딩 상태 추가
    @State private var errorMessage: String? // 에러 메시지 추가
    @State private var successMessage: String? // 성공 메시지 추가
    
    private var sellableItems: [TradeItem] {
        gameManager.player.inventory.filter { item in
            item.requiredLicense.rawValue <= merchant.requiredLicense.rawValue
        }
    }
    
    var body: some View {
        VStack {
            // 상태 메시지 표시
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            if let successMessage = successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            if sellableItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bag")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("판매 가능한 상품이 없습니다")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(sellableItems) { item in
                        SellItemRow(item: item, merchant: merchant, isEnabled: isEnabled && !isLoading) {
                            // ✅ Task로 비동기 호출 래핑
                            Task {
                                await sellItem(item)
                            }
                        }
                        .environmentObject(gameManager)
                        .disabled(isLoading) // 로딩 중에는 비활성화
                        .opacity(isLoading ? 0.6 : 1.0)
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            // 로딩 인디케이터
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("판매 중...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
    
    // ✅ async 함수로 분리
    private func sellItem(_ item: TradeItem) async {
        // 상태 초기화
        errorMessage = nil
        successMessage = nil
        isLoading = true
        
        do {
            let success = await gameManager.sellItem(item, to: merchant, at: merchant.coordinate)
            
            await MainActor.run {
                if success {
                    successMessage = "\(item.name) 판매 성공!"
                    
                    // 3초 후 성공 메시지 자동 삭제
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        successMessage = nil
                    }
                } else {
                    errorMessage = gameManager.errorMessage ?? "판매에 실패했습니다."
                    
                    // 5초 후 오류 메시지 자동 삭제
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        errorMessage = nil
                    }
                }
                
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
                
                // 5초 후 오류 메시지 자동 삭제
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    errorMessage = nil
                }
            }
        }
    }
}
