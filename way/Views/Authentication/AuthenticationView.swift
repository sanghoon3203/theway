
// 📁 Views/Authentication/AuthenticationView.swift
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var isShowingLogin = true
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 수묵화 배경 - 한지 그라데이션
                LinearGradient.paperBackground
                    .ignoresSafeArea()
                
                // 배경 산 실루엣
                VStack {
                    Spacer()
                    MountainSilhouette()
                        .frame(height: 150)
                        .opacity(0.2)
                }
                
                // 은은한 먹 점 패턴
                InkDotPattern()
                    .opacity(0.15)
                
                ScrollView {
                    VStack(spacing: 50) {
                        // 상단 로고
                        InkHeaderSection()
                            .padding(.top, geometry.safeAreaInsets.top + 40)
                        
                        // 인증 영역
                        VStack(spacing: 28) {
                            // 탭 선택기
                            InkAuthTabSelector(isShowingLogin: $isShowingLogin)
                            
                            // 인증 폼
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
                        .inkCard()
                        .padding(.horizontal, 24)
                        
                        // 하단 장식
                        InkFooterSection()
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 30)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - 수묵화 Header Section
struct InkHeaderSection: View {
    @State private var breathingAnimation = false
    
    var body: some View {
        VStack(spacing: 25) {
            // 음양 심볼
            YinYangSymbol(size: 80)
                .scaleEffect(breathingAnimation ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: breathingAnimation)
            
            // 메인 타이틀 - 수묵화 스타일
            VStack(spacing: 15) {
                // 한자 제목
                Text("万里")
                    .font(.chineseTitle)
                    .foregroundColor(.brushText)
                    .shadow(color: .inkMist, radius: 2, x: 1, y: 1)
                
                // 한글 부제목
                Text("만리")
                    .font(.brushStroke)
                    .foregroundColor(.fadeText)
                    .tracking(10)
                
                // 영문 부제목
                Text("Ten Thousand Li")
                    .font(.whisperText)
                    .foregroundColor(.fadeText)
                    .tracking(4)
            }
        }
        .onAppear {
            breathingAnimation = true
        }
    }
}

// MARK: - 수묵화 Auth Tab Selector
struct InkAuthTabSelector: View {
    @Binding var isShowingLogin: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // 로그인 탭
            Button {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isShowingLogin = true
                }
            } label: {
                Text("로그인")
                    .font(.brushStroke)
                    .foregroundColor(isShowingLogin ? .brushText : .fadeText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isShowingLogin ? Color.softWhite : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        isShowingLogin ? Color.inkBlack.opacity(0.3) : Color.inkBlack.opacity(0.1), 
                                        lineWidth: isShowingLogin ? 2 : 1
                                    )
                            )
                    )
            }
            
            // 회원가입 탭
            Button {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isShowingLogin = false
                }
            } label: {
                Text("회원가입")
                    .font(.brushStroke)
                    .foregroundColor(!isShowingLogin ? .brushText : .fadeText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(!isShowingLogin ? Color.softWhite : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        !isShowingLogin ? Color.inkBlack.opacity(0.3) : Color.inkBlack.opacity(0.1), 
                                        lineWidth: !isShowingLogin ? 2 : 1
                                    )
                            )
                    )
            }
        }
    }
}

// MARK: - 수묵화 Footer Section
struct InkFooterSection: View {
    var body: some View {
        VStack(spacing: 20) {
            // 장식 구분선 - 수묵화 스타일
            HStack {
                Rectangle()
                    .fill(Color.inkMist)
                    .frame(height: 1)
                
                Circle()
                    .fill(Color.inkBlack.opacity(0.4))
                    .frame(width: 6, height: 6)
                
                Rectangle()
                    .fill(Color.inkMist)
                    .frame(height: 1)
            }
            .padding(.horizontal, 50)
            
            // 동양적 철학 문구
            Text("천 리 길도 한 걸음부터\n千里之行 始於足下")
                .font(.whisperText)
                .foregroundColor(.fadeText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(GameManager())
}
