// 📁 Views/Launch/StartView.swift
import SwiftUI

struct StartView: View {
    @State private var showWelcome = false
    @State private var logoScale: CGFloat = 0.9
    @State private var logoOpacity: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 배경 그라데이션 (한국 전통 색상)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.91), // 한지색
                    Color(red: 0.94, green: 0.91, blue: 0.85)  // 약간 어두운 한지색
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // 만리 로고
                Image("GameLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320, maxHeight: 500)
                    .scaleEffect(logoScale * pulseScale)
                    .opacity(logoOpacity)
                    .animation(
                        .easeInOut(duration: 1.0),
                        value: logoScale
                    )
                    .animation(
                        .easeInOut(duration: 1.0),
                        value: logoOpacity
                    )
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: pulseScale
                    )
                    .onTapGesture {
                        // 탭하면 다음 화면으로 이동
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showWelcome = true
                        }
                    }
                
                Spacer()
                
                // 하단 안내 텍스트
                VStack(spacing: 8) {
                    Text("화면을 터치하여 시작하세요")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.black.opacity(0.6))
                        .opacity(logoOpacity)
                    
                    // 터치 표시 점들
                    HStack(spacing: 12) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .scaleEffect(pulseScale)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.3),
                                    value: pulseScale
                                )
                        }
                    }
                    .opacity(logoOpacity)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // 로고 나타나기 애니메이션
            withAnimation(.easeInOut(duration: 1.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // 펄스 애니메이션 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    pulseScale = 1.05
                }
            }
        }
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView()
        }
    }
}

#Preview {
    StartView()
}