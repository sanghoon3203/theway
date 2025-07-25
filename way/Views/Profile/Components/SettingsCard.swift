//
//  SettingsCard.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Profile/Components/SettingsCard.swift
import SwiftUI

struct SettingsCard: View {
    @State private var showingAlert = false
    @State private var alertType: AlertType = .about
    
    enum AlertType {
        case about, contact, help
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("설정")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                SettingRow(title: "알림 설정", icon: "bell.fill", color: .red) {
                    // TODO: 알림 설정 화면 이동
                }
                
                SettingRow(title: "게임 가이드", icon: "questionmark.circle.fill", color: .blue) {
                    alertType = .help
                    showingAlert = true
                }
                
                SettingRow(title: "문의하기", icon: "envelope.fill", color: .green) {
                    alertType = .contact
                    showingAlert = true
                }
                
                SettingRow(title: "앱 정보", icon: "info.circle.fill", color: .gray) {
                    alertType = .about
                    showingAlert = true
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .alert(isPresented: $showingAlert) {
            switch alertType {
            case .about:
                return Alert(
                    title: Text("서울 대무역상"),
                    message: Text("버전 1.0.0\n\n마비노기 무역 시스템과 포켓몬GO를 결합한 위치기반 무역 게임"),
                    dismissButton: .default(Text("확인"))
                )
            case .contact:
                return Alert(
                    title: Text("문의하기"),
                    message: Text("개발자에게 문의사항이 있으시면\nemail@example.com 으로 연락주세요!"),
                    dismissButton: .default(Text("확인"))
                )
            case .help:
                return Alert(
                    title: Text("게임 가이드"),
                    message: Text("1. 지도에서 상인을 찾아보세요\n2. 상품을 구매하고 다른 지역에서 판매하세요\n3. 수익으로 차량과 부동산을 구매하세요\n4. 라이센스를 업그레이드하세요!"),
                    dismissButton: .default(Text("확인"))
                )
            }
        }
    }
}
