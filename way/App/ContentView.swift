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
    @State private var compassRotation: Double = 0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 배경
            LinearGradient.oceanWave
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 로고 애니메이션
                ZStack {
                    Circle()
                        .fill(LinearGradient.treasureShine)
                        .frame(width: 120, height: 120)
                        .shadow(color: .treasureGold.opacity(0.5), radius: 20, x: 0, y: 10)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.7)
                    
                    Image(systemName: NavigationIcons.compass)
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(compassRotation))
                }
                
                // 앱 제목
                VStack(spacing: 8) {
                    Text("서울 대무역상")
                        .font(.pirateTitle)
                        .foregroundColor(.waveWhite)
                        .opacity(isAnimating ? 1.0 : 0.0)
                    
                    Text("Seoul Trading Master")
                        .font(.treasureCaption)
                        .foregroundColor(.waveWhite.opacity(0.8))
                        .tracking(3)
                        .opacity(isAnimating ? 1.0 : 0.0)
                }
                
                // 로딩 인디케이터
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .treasureGold))
                        .scaleEffect(1.2)
                        .opacity(isAnimating ? 1.0 : 0.0)
                    
                    Text("항해 준비 중...")
                        .font(.merchantBody)
                        .foregroundColor(.waveWhite.opacity(0.8))
                        .opacity(isAnimating ? 1.0 : 0.0)
                }
            }
        }
        .onAppear {
            // 애니메이션 시작
            withAnimation(.easeOut(duration: 1.0)) {
                isAnimating = true
            }
            
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                compassRotation = 360
            }
        }
    }
}

#Preview {
    ContentView()
}
