// 📁 App/ContentView.swift - 수정된 버전
import SwiftUI

struct ContentView: View {
    @StateObject private var gameManager = GameManager()
    @State private var isCheckingAuth = true
    
    var body: some View {
        Group {
            if isCheckingAuth {
                // 로딩 화면 (앱 시작시)
                SplashScreenView()
            } else if gameManager.isAuthenticated {
                // 로그인 완료 시 메인 게임 화면
                MainTabView()
                    .environmentObject(gameManager)
            } else {
                // 로그인 필요시 인증 화면
                AuthenticationView()
                    .environmentObject(gameManager)
            }
        }
        .onAppear {
            checkAuthenticationStatus()
        }
        .onChange(of: gameManager.isAuthenticated) { _ in
            // 인증 상태 변경시 애니메이션
            withAnimation(.easeInOut(duration: 0.5)) {
                // 상태 변경 처리
            }
        }
    }
    
    private func checkAuthenticationStatus() {
        Task {
            // 자동 로그인 체크
            if let token = UserDefaults.standard.string(forKey: "auth_token"),
               !token.isEmpty,
               UserDefaults.standard.bool(forKey: "auto_login") {
                
                // 토큰 유효성 검사 및 자동 로그인 시도
                await attemptAutoLogin(with: token)
            } else {
                // 토큰이 없거나 자동 로그인이 비활성화된 경우
                await MainActor.run {
                    isCheckingAuth = false
                }
            }
        }
    }
    
    private func attemptAutoLogin(with token: String) async {
        // TODO: 서버에 토큰 유효성 검증 요청
        // 지금은 간단히 토큰만 확인
        
        await MainActor.run {
            // 유효한 토큰이 있다면 자동 로그인
            gameManager.isAuthenticated = true
            isCheckingAuth = false
        }
    }
}

// MARK: - 스플래시 스크린
struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var yinYangAnimation = false
    
    var body: some View {
        ZStack {
            // 수묵화 배경 - 한지 그라데이션
            LinearGradient.paperBackground
                .ignoresSafeArea()
            
            // 배경 산 실루엣
            VStack {
                Spacer()
                MountainSilhouette()
                    .frame(height: 200)
                    .opacity(0.3)
            }
            
            // 은은한 먹 번짐 패턴
            InkDotPattern()
                .opacity(0.2)
            
            VStack(spacing: 60) {
                Spacer()
                
                // 메인 로고 - 만리 万里 (동양적 스타일)
                VStack(spacing: 20) {
                    // 한자 제목 - 수묵화 스타일
                    Text("万里")
                        .font(.chineseTitle)
                        .foregroundColor(.brushText)
                        .shadow(color: .inkMist, radius: 3, x: 2, y: 2)
                        .scaleEffect(isAnimating ? 1.0 : 0.9)
                        .opacity(isAnimating ? 1.0 : 0.0)
                    
                    // 한글 부제목
                    Text("만리")
                        .font(.brushStroke)
                        .foregroundColor(.fadeText)
                        .tracking(12)
                        .opacity(isAnimating ? 1.0 : 0.0)
                    
                    // 영문 부제목
                    Text("Ten Thousand Li")
                        .font(.whisperText)
                        .foregroundColor(.fadeText)
                        .tracking(6)
                        .opacity(isAnimating ? 0.8 : 0.0)
                }
                
                // 음양 심볼
                YinYangSymbol(size: 100)
                    .scaleEffect(yinYangAnimation ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                Spacer()
                
                // 은은한 로딩 표시
                VStack(spacing: 16) {
                    // 수묵화 스타일 로딩 점들
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.inkBlack.opacity(0.4))
                                .frame(width: 6, height: 6)
                                .opacity(isAnimating ? 1.0 : 0.3)
                                .animation(
                                    .easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                    
                    Text("천 리 길을 준비하는 중...")
                        .font(.whisperText)
                        .foregroundColor(.fadeText)
                        .opacity(isAnimating ? 1.0 : 0.0)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // 은은한 페이드인 애니메이션
            withAnimation(.easeOut(duration: 2.0)) {
                isAnimating = true
            }
            
            // 음양 심볼 애니메이션
            withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
                yinYangAnimation = true
            }
        }
    }
}

#Preview {
    ContentView()
}
