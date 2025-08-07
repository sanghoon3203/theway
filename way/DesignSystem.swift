//
//  DesignSystem.swift
//  way
//
//  Created by 김상훈 on 8/6/25.
//

// 📁 Utils/DesignSystem.swift - 대항해시대 테마 디자인 시스템
import SwiftUI

// MARK: - 색상 시스템
extension Color {
    // 대항해시대 메인 색상 팔레트
    static let seaBlue = Color(red: 0.12, green: 0.27, blue: 0.49) // 깊은 바다색
    static let oceanTeal = Color(red: 0.0, green: 0.50, blue: 0.63) // 바다 틸색
    static let treasureGold = Color(red: 0.85, green: 0.65, blue: 0.13) // 보물 금색
    static let shipBrown = Color(red: 0.40, green: 0.26, blue: 0.13) // 배 나무색
    static let parchment = Color(red: 0.96, green: 0.93, blue: 0.84) // 양피지색
    static let compass = Color(red: 0.70, green: 0.13, blue: 0.13) // 나침반 빨간색
    
    // 그라데이션용 보조색
    static let lightSeaBlue = Color(red: 0.20, green: 0.40, blue: 0.70)
    static let darkSeaBlue = Color(red: 0.05, green: 0.15, blue: 0.35)
    static let lightTreasureGold = Color(red: 0.95, green: 0.80, blue: 0.30)
    
    // UI 상태 색상
    static let waveWhite = Color(red: 0.98, green: 0.98, blue: 1.0)
    static let mistGray = Color(red: 0.85, green: 0.85, blue: 0.87)
    static let stormGray = Color(red: 0.55, green: 0.55, blue: 0.58)
}

// MARK: - 그라데이션 시스템
extension LinearGradient {
    // 바다 그라데이션 (메인 배경)
    static let oceanWave = LinearGradient(
        colors: [Color.seaBlue, Color.oceanTeal, Color.lightSeaBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // 보물 그라데이션 (버튼, 액센트)
    static let treasureShine = LinearGradient(
        colors: [Color.treasureGold, Color.lightTreasureGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // 카드 배경 그라데이션
    static let parchmentGlow = LinearGradient(
        colors: [Color.parchment, Color.waveWhite],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // 어두운 오버레이
    static let deepSea = LinearGradient(
        colors: [Color.darkSeaBlue.opacity(0.3), Color.seaBlue.opacity(0.1)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - 타이포그래피 시스템
extension Font {
    // 대항해시대 스타일 폰트
    static let pirateTitle = Font.custom("Georgia", size: 28).weight(.bold) // 제목
    static let navigatorTitle = Font.system(size: 24, weight: .bold, design: .serif) // 부제목
    static let merchantBody = Font.system(size: 16, weight: .medium, design: .default) // 본문
    static let treasureCaption = Font.system(size: 14, weight: .regular, design: .monospaced) // 숫자/가격
    static let compassSmall = Font.system(size: 12, weight: .medium, design: .default) // 작은 텍스트
}

// MARK: - 아이콘 시스템
struct NavigationIcons {
    static let anchor = "anchor"
    static let compass = "location.north"
    static let treasure = "case.fill"
    static let ship = "ferry"
    static let coin = "dollarsign.circle.fill"
    static let map = "map.fill"
    static let flag = "flag.fill"
    static let wind = "wind"
    static let wave = "waveform.path"
    static let star = "star.fill"
    static let crown = "crown.fill"
    static let person = "person.crop.circle"
    static let lock = "lock.shield"
    static let eye = "eye"
    static let eyeSlash = "eye.slash"
}

// MARK: - 커스텀 버튼 스타일
struct TreasureButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.merchantBody)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(LinearGradient.treasureShine)
                    .shadow(
                        color: Color.treasureGold.opacity(0.4),
                        radius: configuration.isPressed ? 2 : 8,
                        x: 0,
                        y: configuration.isPressed ? 1 : 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SeaButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.merchantBody)
            .foregroundColor(.seaBlue)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.waveWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.seaBlue.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - 커스텀 텍스트필드 스타일
struct NavigatorTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.merchantBody)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.waveWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.mistGray, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
    }
}

// MARK: - 카드 스타일
struct ParchmentCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient.parchmentGlow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.treasureGold.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

extension View {
    func parchmentCard() -> some View {
        self.modifier(ParchmentCardStyle())
    }
}
