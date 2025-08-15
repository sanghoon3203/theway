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

// MARK: - 동양적 수묵화 스타일

// 수묵화 색상 팔레트
extension Color {
    // 수묵화 기본 색상
    static let inkBlack = Color(red: 0.17, green: 0.24, blue: 0.31) // #2c3e50 - 먹색
    static let paperBeige = Color(red: 0.96, green: 0.96, blue: 0.86) // #f5f5dc - 한지색
    static let mistGray = Color(red: 0.90, green: 0.90, blue: 0.90) // #e6e6e6 - 안개색
    static let subtleGray = Color(red: 0.95, green: 0.95, blue: 0.95) // 은은한 회색
    
    // 음양 색상
    static let yinDark = Color(red: 0.17, green: 0.24, blue: 0.31) // 음(陰)
    static let yangLight = Color(red: 0.98, green: 0.98, blue: 0.95) // 양(陽)
    
    // 투명도 색상
    static let inkMist = Color.black.opacity(0.1) // 먹 번짐 효과
    static let softWhite = Color.white.opacity(0.5) // 부드러운 흰색
    
    // 텍스트 색상
    static let brushText = Color(red: 0.17, green: 0.24, blue: 0.31) // 붓글씨 색
    static let fadeText = Color(red: 0.17, green: 0.24, blue: 0.31).opacity(0.7) // 흐린 텍스트
}

// 수묵화 그라데이션
extension LinearGradient {
    // 한지 배경 그라데이션
    static let paperBackground = LinearGradient(
        colors: [Color.paperBeige, Color.mistGray],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // 은은한 먹 번짐 효과
    static let inkWash = LinearGradient(
        colors: [Color.inkMist, Color.clear],
        startPoint: .center,
        endPoint: .bottom
    )
    
    // 부드러운 음영
    static let softShadow = LinearGradient(
        colors: [Color.inkMist.opacity(0.3), Color.clear],
        startPoint: .top,
        endPoint: .bottom
    )
}

// 수묵화 폰트
extension Font {
    static let chineseTitle = Font.custom("Georgia", size: 56).weight(.ultraLight) // 한자 제목
    static let brushStroke = Font.system(size: 18, weight: .light, design: .serif) // 붓글씨 느낌
    static let inkText = Font.system(size: 16, weight: .regular, design: .serif) // 일반 텍스트
    static let whisperText = Font.system(size: 14, weight: .light, design: .serif) // 작은 텍스트
}

// MARK: - JRPG 스타일 확장

// JRPG 색상 팔레트 확장
extension Color {
    // 캐릭터 스탯 색상
    static let healthRed = Color(red: 0.85, green: 0.23, blue: 0.23)
    static let manaBlue = Color(red: 0.23, green: 0.47, blue: 0.85)
    static let expGreen = Color(red: 0.23, green: 0.70, blue: 0.44)
    static let goldYellow = Color(red: 0.95, green: 0.77, blue: 0.06)
    
    // 대화창 색상
    static let dialogueBackground = Color(red: 0.13, green: 0.08, blue: 0.05) // 어두운 갈색
    static let dialogueBorder = Color(red: 0.70, green: 0.52, blue: 0.20) // 금테두리
    static let dialogueText = Color(red: 0.95, green: 0.92, blue: 0.85) // 밝은 텍스트
    
    // 메뉴 색상
    static let menuBackground = Color(red: 0.08, green: 0.12, blue: 0.20)
    static let menuBorder = Color(red: 0.40, green: 0.50, blue: 0.70)
    static let menuHighlight = Color(red: 0.60, green: 0.75, blue: 0.95)
}

// JRPG 스타일 폰트 확장
extension Font {
    static let dialogueText = Font.system(size: 18, weight: .medium, design: .default)
    static let characterName = Font.system(size: 20, weight: .bold, design: .serif)
    static let statText = Font.system(size: 16, weight: .semibold, design: .monospaced)
    static let menuText = Font.system(size: 16, weight: .medium, design: .default)
    static let questTitle = Font.system(size: 22, weight: .bold, design: .serif)
}

// MARK: - 대화창 스타일
struct DialogueBoxStyle: ViewModifier {
    let characterName: String?
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 캐릭터 이름 탭
            if let name = characterName {
                HStack {
                    Text(name)
                        .font(.characterName)
                        .foregroundColor(.dialogueText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.dialogueBackground.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.dialogueBorder, lineWidth: 2)
                                )
                        )
                    Spacer()
                }
                .padding(.horizontal, 20)
                .offset(y: 10)
                .zIndex(1)
            }
            
            // 메인 대화창
            content
                .font(.dialogueText)
                .foregroundColor(.dialogueText)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.dialogueBackground.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.dialogueBorder, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                )
        }
    }
}

extension View {
    func dialogueBox(characterName: String? = nil) -> some View {
        self.modifier(DialogueBoxStyle(characterName: characterName))
    }
}

// MARK: - 스탯 바 스타일
struct StatBarStyle: ViewModifier {
    let current: Double
    let maximum: Double
    let color: Color
    let backgroundColor: Color
    
    init(current: Double, maximum: Double, color: Color, backgroundColor: Color = Color.gray.opacity(0.3)) {
        self.current = current
        self.maximum = maximum
        self.color = color
        self.backgroundColor = backgroundColor
    }
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content
                .font(.statText)
                .foregroundColor(.dialogueText)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경 바
                    RoundedRectangle(cornerRadius: 6)
                        .fill(backgroundColor)
                        .frame(height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                        )
                    
                    // 진행률 바
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * min(current / maximum, 1.0),
                            height: 12
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .animation(.easeInOut(duration: 0.5), value: current)
                }
            }
            .frame(height: 12)
        }
    }
}

extension View {
    func statBar(current: Double, maximum: Double, color: Color) -> some View {
        self.modifier(StatBarStyle(current: current, maximum: maximum, color: color))
    }
}

// MARK: - JRPG 메뉴 버튼 스타일
struct JRPGMenuButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.menuText)
            .foregroundColor(isSelected ? Color.treasureGold : Color.dialogueText)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ? 
                        Color.menuHighlight.opacity(0.2) : 
                        Color.menuBackground.opacity(0.7)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.treasureGold : Color.menuBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 선택지 버튼 스타일
struct DialogueOptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: "chevron.right")
                .foregroundColor(.treasureGold)
                .font(.system(size: 14, weight: .bold))
            
            configuration.label
                .font(.menuText)
                .foregroundColor(.dialogueText)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.dialogueBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            configuration.isPressed ? Color.treasureGold : Color.dialogueBorder.opacity(0.5),
                            lineWidth: configuration.isPressed ? 2 : 1
                        )
                )
        )
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 캐릭터 포트레이트 스타일
struct CharacterPortraitStyle: ViewModifier {
    let size: CGFloat
    let borderColor: Color
    
    init(size: CGFloat = 80, borderColor: Color = .dialogueBorder) {
        self.size = size
        self.borderColor = borderColor
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

extension View {
    func characterPortrait(size: CGFloat = 80, borderColor: Color = .dialogueBorder) -> some View {
        self.modifier(CharacterPortraitStyle(size: size, borderColor: borderColor))
    }
}

// MARK: - 아이템 툴팁 스타일
struct ItemTooltipStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.compassSmall)
            .foregroundColor(.dialogueText)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.dialogueBackground.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.dialogueBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 2)
            )
    }
}

extension View {
    func itemTooltip() -> some View {
        self.modifier(ItemTooltipStyle())
    }
}

// MARK: - 동양적 수묵화 컴포넌트

// 음양(태극) 심볼
struct YinYangSymbol: View {
    let size: CGFloat
    @State private var rotation: Double = 0
    
    init(size: CGFloat = 120) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // 외부 원
            Circle()
                .stroke(Color.inkBlack, lineWidth: 3)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color.softWhite)
                        .frame(width: size, height: size)
                )
            
            // 음양 패턴
            ZStack {
                // 어두운 반원 (음)
                Path { path in
                    let center = CGPoint(x: size/2, y: size/2)
                    let radius = size/2
                    
                    path.move(to: CGPoint(x: center.x, y: 0))
                    path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                    path.addArc(center: CGPoint(x: center.x, y: center.y - radius/2), radius: radius/2, startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: true)
                    path.addArc(center: CGPoint(x: center.x, y: center.y + radius/2), radius: radius/2, startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: false)
                    path.closeSubpath()
                }
                .fill(Color.yinDark)
                
                // 밝은 원 (양 안의 음)
                Circle()
                    .fill(Color.yangLight)
                    .frame(width: size/6, height: size/6)
                    .offset(y: -size/4)
                
                // 어두운 원 (음 안의 양)
                Circle()
                    .fill(Color.yinDark)
                    .frame(width: size/6, height: size/6)
                    .offset(y: size/4)
            }
            .frame(width: size, height: size)
            .clipped()
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// 수묵화 산 실루엣
struct MountainSilhouette: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let baseHeight = height * 0.6
                
                path.move(to: CGPoint(x: 0, y: height))
                
                // 산봉우리들
                let peaks = [
                    (x: width * 0.1, y: baseHeight * 0.7),
                    (x: width * 0.25, y: baseHeight * 0.4),
                    (x: width * 0.4, y: baseHeight * 0.6),
                    (x: width * 0.55, y: baseHeight * 0.2),
                    (x: width * 0.7, y: baseHeight * 0.5),
                    (x: width * 0.85, y: baseHeight * 0.3),
                    (x: width, y: baseHeight * 0.4)
                ]
                
                for peak in peaks {
                    path.addLine(to: CGPoint(x: peak.x, y: peak.y))
                }
                
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(Color.inkMist)
        }
    }
}

// 수묵화 점 패턴
struct InkDotPattern: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<30, id: \.self) { index in
                    Circle()
                        .fill(Color.inkMist)
                        .frame(
                            width: CGFloat.random(in: 2...6),
                            height: CGFloat.random(in: 2...6)
                        )
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
    }
}

// 수묵화 카드 스타일
struct InkCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.softWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.inkBlack.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.inkMist.opacity(0.5), radius: 8, x: 0, y: 4)
            )
    }
}

extension View {
    func inkCard() -> some View {
        self.modifier(InkCardStyle())
    }
}

// 수묵화 버튼 스타일
struct InkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.brushStroke)
            .foregroundColor(.inkBlack)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.softWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.inkBlack.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.inkMist.opacity(0.3), radius: configuration.isPressed ? 2 : 6, x: 0, y: configuration.isPressed ? 1 : 3)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
