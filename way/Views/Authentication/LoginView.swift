//
//  LoginView.swift
//  way
//
//  Created by 김상훈 on 8/6/25.
//


// 📁 Views/Authentication/LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var rememberMe = true
    @State private var isLoading = false
    @FocusState private var focusedField: LoginField?
    
    enum LoginField {
        case email, password
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 타이틀
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: NavigationIcons.anchor)
                        .font(.title2)
                        .foregroundColor(.seaBlue)
                    
                    Text("항해 준비")
                        .font(.navigatorTitle)
                        .foregroundColor(.seaBlue)
                }
                
                Text("모험이 기다리고 있습니다")
                    .font(.compassSmall)
                    .foregroundColor(.stormGray)
            }
            
            // 입력 필드들
            VStack(spacing: 16) {
                // 이메일 필드
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .font(.caption)
                            .foregroundColor(.seaBlue)
                        
                        Text("선장 이메일")
                            .font(.compassSmall)
                            .foregroundColor(.seaBlue)
                    }
                    
                    TextField("admiral@sailing.com", text: $email)
                        .textFieldStyle(NavigatorTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .email)
                        .onSubmit {
                            focusedField = .password
                        }
                }
                
                // 비밀번호 필드
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: NavigationIcons.lock)
                            .font(.caption)
                            .foregroundColor(.seaBlue)
                        
                        Text("비밀 항로")
                            .font(.compassSmall)
                            .foregroundColor(.seaBlue)
                    }
                    
                    HStack {
                        Group {
                            if isPasswordVisible {
                                TextField("항로를 입력하세요", text: $password)
                            } else {
                                SecureField("항로를 입력하세요", text: $password)
                            }
                        }
                        .focused($focusedField, equals: .password)
                        .onSubmit {
                            performLogin()
                        }
                        
                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? NavigationIcons.eye : NavigationIcons.eyeSlash)
                                .font(.body)
                                .foregroundColor(.stormGray)
                        }
                        .padding(.trailing, 4)
                    }
                    .textFieldStyle(NavigatorTextFieldStyle())
                }
            }
            
            // 자동 로그인 토글
            HStack {
                Button {
                    rememberMe.toggle()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(rememberMe ? Color.treasureGold : Color.mistGray, lineWidth: 2)
                                .frame(width: 20, height: 20)
                            
                            if rememberMe {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.treasureGold)
                            }
                        }
                        
                        Text("다음에도 자동으로 항해 시작")
                            .font(.merchantBody)
                            .foregroundColor(.seaBlue)
                    }
                }
                
                Spacer()
            }
            
            // 로그인 버튼
            Button {
                performLogin()
            } label: {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: NavigationIcons.ship)
                            .font(.body)
                        
                        Text("항해 출발!")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(TreasureButtonStyle())
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
            
            // 에러 메시지 표시
            if let errorMessage = gameManager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.compass)
                    
                    Text(errorMessage)
                        .font(.compassSmall)
                        .foregroundColor(.compass)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.compass.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.compass.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // 게스트 모드 (오프라인)
            VStack(spacing: 12) {
                HStack {
                    Rectangle()
                        .fill(Color.mistGray)
                        .frame(height: 1)
                    
                    Text("또는")
                        .font(.compassSmall)
                        .foregroundColor(.stormGray)
                        .padding(.horizontal, 12)
                    
                    Rectangle()
                        .fill(Color.mistGray)
                        .frame(height: 1)
                }
                
                Button {
                    startOfflineMode()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: NavigationIcons.map)
                            .font(.body)
                        
                        Text("오프라인으로 탐험하기")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SeaButtonStyle())
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameManager.errorMessage)
        .onAppear {
            loadSavedCredentials()
        }
    }
    
    // MARK: - Functions
    private func performLogin() {
        // 키보드 숨기기
        focusedField = nil
        
        // 입력 검증
        guard !email.isEmpty, !password.isEmpty else {
            return
        }
        
        guard isValidEmail(email) else {
            // TODO: 이메일 형식 에러 표시
            return
        }
        
        isLoading = true
        
        Task {
            await gameManager.login(email: email, password: password)
            
            await MainActor.run {
                isLoading = false
                
                // 자동 로그인 설정 저장
                if rememberMe {
                    saveCredentials()
                }
            }
        }
    }
    
    private func startOfflineMode() {
        // 오프라인 모드로 게임 시작
        gameManager.isAuthenticated = false
        gameManager.isOnlineMode = false
        gameManager.connectionStatus = "오프라인 모드"
    }
    
    private func saveCredentials() {
        if rememberMe {
            UserDefaults.standard.set(email, forKey: "saved_email")
            UserDefaults.standard.set(rememberMe, forKey: "auto_login")
            // 보안상 비밀번호는 저장하지 않음
        } else {
            UserDefaults.standard.removeObject(forKey: "saved_email")
            UserDefaults.standard.removeObject(forKey: "auto_login")
        }
    }
    
    private func loadSavedCredentials() {
        if UserDefaults.standard.bool(forKey: "auto_login") {
            email = UserDefaults.standard.string(forKey: "saved_email") ?? ""
            rememberMe = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

#Preview {
    LoginView()
        .environmentObject(GameManager())
        .parchmentCard()
        .padding()
        .background(LinearGradient.oceanWave)
}
