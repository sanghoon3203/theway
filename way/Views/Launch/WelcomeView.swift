// 📁 Views/Launch/WelcomeView.swift
import SwiftUI

struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var logoOpacity: Double = 0.0
    @State private var welcomeOpacity: Double = 0.0
    @State private var buttonsOpacity: Double = 0.0
    @State private var buttonsOffset: CGFloat = 30
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.91),
                    Color(red: 0.94, green: 0.91, blue: 0.85)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 50) {
                Spacer()
                
                // 상단 만리 로고 (작게)
                Image("GameLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 240)
                    .opacity(logoOpacity)
                    .animation(.easeInOut(duration: 1.0), value: logoOpacity)
                
                // 환영 메시지
                VStack(spacing: 16) {
                    Text("만리에 오신걸")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.black.opacity(0.8))
                    
                    Text("환영합니다")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.black.opacity(0.8))
                }
                .opacity(welcomeOpacity)
                .animation(.easeInOut(duration: 1.0).delay(0.5), value: welcomeOpacity)
                
                Spacer()
                
                // 로그인/회원가입 버튼들
                VStack(spacing: 20) {
                    // 로그인 버튼
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showLogin = true
                        }
                    }) {
                        Image("Logn_reg_button")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 55)
                    }
                    .scaleEffect(0.95)
                    .onTapGesture {
                        // 버튼 터치 피드백
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                    
                    // 회원가입 버튼
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showRegister = true
                        }
                    }) {
                        Image("register_reg_button")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 55)
                    }
                    .scaleEffect(0.95)
                    .onTapGesture {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                }
                .opacity(buttonsOpacity)
                .offset(y: buttonsOffset)
                .animation(.easeInOut(duration: 1.0).delay(1.0), value: buttonsOpacity)
                .animation(.easeInOut(duration: 1.0).delay(1.0), value: buttonsOffset)
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            // 순차적 애니메이션
            withAnimation {
                logoOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    welcomeOpacity = 1.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    buttonsOpacity = 1.0
                    buttonsOffset = 0
                }
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            NewLoginView()
        }
        .fullScreenCover(isPresented: $showRegister) {
            NewRegisterView()
        }
    }
}

#Preview {
    WelcomeView()
}