// 📁 App/ContentView.swift - 새로운 시작 플로우
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showSplash = true
    
    var body: some View {
        Group {
            if showSplash {
                // 새로운 시작 플로우: SplashView -> StartView -> WelcomeView -> Login/Register
                SplashView()
                    .onAppear {
                        // 기존 로그인 상태 체크
                        checkExistingAuthStatus()
                    }
            } else if gameManager.isAuthenticated {
                // 로그인 완료 시 메인 게임 화면
                MainTabView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.8)))
            } else {
                // 로그인이 필요한 경우 - 새로운 시작 화면부터 시작
                SplashView()
            }
        }
        .onChange(of: gameManager.isAuthenticated) { isAuth in
            // 로그인 성공시 스플래시 화면 숨김
            if isAuth {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showSplash = false
                }
            }
        }
    }
    
    private func checkExistingAuthStatus() {
        // 기존에 로그인된 상태인지 확인
        Task {
            // 자동 로그인 체크 (기존 로직 유지)
            if let token = UserDefaults.standard.string(forKey: "auth_token"),
               !token.isEmpty {
                
                // 토큰이 있으면 자동 로그인 시도
                await MainActor.run {
                    gameManager.isAuthenticated = true
                    showSplash = false
                }
            }
            // 토큰이 없으면 새로운 시작 플로우 계속 진행
        }
    }
}

#Preview {
    ContentView()
}
