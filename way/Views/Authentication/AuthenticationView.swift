
// 📁 Views/Authentication/AuthenticationView.swift
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var isShowingLogin = true
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경 - 바다 그라데이션
                LinearGradient.oceanWave
                    .ignoresSafeArea()
                
                // 파도 애니메이션 배경
                WaveBackground()
                    .opacity(0.3)
                
                // 메인 컨텐츠
                VStack(spacing: 0) {
                    // 상단 로고 및 타이틀 영역
                    HeaderSection()
                        .padding(.top, geometry.safeAreaInsets.top + 20)
                    
                    Spacer()
                    
                    // 인증 카드 영역
                    VStack(spacing: 20) {
                        // 탭 선택기 (로그인/회원가입)
                        AuthTabSelector(isShowingLogin: $isShowingLogin)
                        
                        // 인증 폼 영역
                        if isShowingLogin {
                            LoginView()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        } else {
                            RegisterView()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .parchmentCard()
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // 하단 장식 요소
                    FooterSection()
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    @State private var compassRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // 앱 아이콘 (나침반)
            ZStack {
                Circle()
                    .fill(LinearGradient.treasureShine)
                    .frame(width: 80, height: 80)
                    .shadow(color: .treasureGold.opacity(0.5), radius: 10, x: 0, y: 5)
                
                Image(systemName: NavigationIcons.compass)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(compassRotation))
                    .onAppear {
                        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                            compassRotation = 360
                        }
                    }
            }
            
            // 앱 제목
            VStack(spacing: 4) {
                Text("서울 대무역상")
                    .font(.pirateTitle)
                    .foregroundColor(.waveWhite)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("Seoul Trading Master")
                    .font(.compassSmall)
                    .foregroundColor(.waveWhite.opacity(0.8))
                    .tracking(2)
            }
        }
    }
}

// MARK: - Auth Tab Selector
struct AuthTabSelector: View {
    @Binding var isShowingLogin: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // 로그인 탭
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowingLogin = true
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: NavigationIcons.anchor)
                        .font(.title2)
                    
                    Text("항해 시작")
                        .font(.merchantBody)
                }
                .foregroundColor(isShowingLogin ? .treasureGold : .stormGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            
            // 구분선
            Rectangle()
                .fill(Color.mistGray)
                .frame(width: 1, height: 40)
            
            // 회원가입 탭
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowingLogin = false
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: NavigationIcons.flag)
                        .font(.title2)
                    
                    Text("함대 결성")
                        .font(.merchantBody)
                }
                .foregroundColor(!isShowingLogin ? .treasureGold : .stormGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
        .background(
            // 선택 표시기
            HStack {
                if isShowingLogin {
                    Rectangle()
                        .fill(Color.treasureGold.opacity(0.2))
                        .cornerRadius(10)
                    Spacer()
                } else {
                    Spacer()
                    Rectangle()
                        .fill(Color.treasureGold.opacity(0.2))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        )
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.waveWhite.opacity(0.1))
        )
    }
}

// MARK: - Footer Section
struct FooterSection: View {
    var body: some View {
        VStack(spacing: 12) {
            // 장식 요소들
            HStack(spacing: 20) {
                Image(systemName: NavigationIcons.ship)
                    .font(.title2)
                    .foregroundColor(.waveWhite.opacity(0.6))
                
                Image(systemName: NavigationIcons.treasure)
                    .font(.title2)
                    .foregroundColor(.treasureGold.opacity(0.8))
                
                Image(systemName: NavigationIcons.crown)
                    .font(.title2)
                    .foregroundColor(.waveWhite.opacity(0.6))
            }
            
            Text("새로운 무역의 시대가 시작됩니다")
                .font(.treasureCaption)
                .foregroundColor(.waveWhite.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Wave Background Animation
struct WaveBackground: View {
    @State private var waveOffset = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height * 0.5
                let wavelength = width / 3
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for x in stride(from: 0, through: width, by: 1) {
                    let relativeX = x / wavelength
                    let sine = sin(relativeX + waveOffset) * 20
                    let y = midHeight + sine
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.waveWhite.opacity(0.3), lineWidth: 2)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    waveOffset = .pi * 2
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(GameManager())
}
