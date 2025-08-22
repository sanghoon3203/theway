// 📁 Views/Launch/SplashView.swift
import SwiftUI
import AVFoundation

struct SplashView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.9),
                    Color(red: 0.9, green: 0.9, blue: 0.85)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // 팀 로고
                Image("teamlogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .animation(
                        .easeInOut(duration: 1.2)
                        .delay(0.3),
                        value: logoScale
                    )
                    .animation(
                        .easeInOut(duration: 1.0)
                        .delay(0.3),
                        value: logoOpacity
                    )
                
                Spacer()
                
                // 하단 로딩 인디케이터 (선택사항)
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(logoScale)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: logoScale
                            )
                    }
                }
                .padding(.bottom, 50)
                .opacity(logoOpacity)
            }
        }
        .onAppear {
            // 로고 애니메이션 시작
            withAnimation {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // 음악 재생 (선택사항 - 음원 파일이 있다면)
            playLaunchSound()
            
            // 3초 후 다음 화면으로 이동
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            StartView()
        }
    }
    
    private func playLaunchSound() {
        // 음원 파일이 있다면 여기에 추가
        // 예: guard let soundURL = Bundle.main.url(forResource: "launch_sound", withExtension: "mp3") else { return }
        // try? audioPlayer = AVAudioPlayer(contentsOf: soundURL)
        // audioPlayer?.play()
    }
}

#Preview {
    SplashView()
}