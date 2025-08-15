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
        VStack(spacing: 30) {
            // 수묵화 스타일 타이틀
            VStack(spacing: 16) {
                Text("로그인")
                    .font(.brushStroke)
                    .fontWeight(.semibold)
                    .foregroundColor(.brushText)
                
                Text("계정에 접속하여 여행을 시작하세요")
                    .font(.inkText)
                    .foregroundColor(.fadeText)
                    .multilineTextAlignment(.center)
            }
            
            // 수묵화 스타일 입력 필드들
            VStack(spacing: 24) {
                // 이메일 필드
                VStack(alignment: .leading, spacing: 10) {
                    Text("이메일")
                        .font(.inkText)
                        .foregroundColor(.brushText)
                    
                    TextField("이메일을 입력하세요", text: $email)
                        .font(.inkText)
                        .foregroundColor(.brushText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.softWhite)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            focusedField == .email ? Color.inkBlack.opacity(0.4) : Color.inkBlack.opacity(0.2), 
                                            lineWidth: focusedField == .email ? 2 : 1
                                        )
                                )
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .email)
                        .onSubmit {
                            focusedField = .password
                        }
                }
                
                // 비밀번호 필드
                VStack(alignment: .leading, spacing: 10) {
                    Text("비밀번호")
                        .font(.inkText)
                        .foregroundColor(.brushText)
                    
                    HStack {
                        Group {
                            if isPasswordVisible {
                                TextField("비밀번호를 입력하세요", text: $password)
                            } else {
                                SecureField("비밀번호를 입력하세요", text: $password)
                            }
                        }
                        .font(.inkText)
                        .foregroundColor(.brushText)
                        .focused($focusedField, equals: .password)
                        .onSubmit {
                            performLogin()
                        }
                        
                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? NavigationIcons.eye : NavigationIcons.eyeSlash)
                                .font(.body)
                                .foregroundColor(.fadeText)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.softWhite)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        focusedField == .password ? Color.inkBlack.opacity(0.4) : Color.inkBlack.opacity(0.2), 
                                        lineWidth: focusedField == .password ? 2 : 1
                                    )
                            )
                    )
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
                                .stroke(rememberMe ? Color.brushText : Color.fadeText, lineWidth: 2)
                                .frame(width: 18, height: 18)
                            
                            if rememberMe {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.brushText)
                            }
                        }
                        
                        Text("자동 로그인")
                            .font(.inkText)
                            .foregroundColor(.brushText)
                    }
                }
                
                Spacer()
            }
            
            // 로그인 버튼 - 수묵화 스타일
            Button {
                performLogin()
            } label: {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .brushText))
                            .scaleEffect(0.9)
                    }
                    
                    Text("여행 시작")
                        .font(.brushStroke)
                        .fontWeight(.medium)
                }
            }
            .buttonStyle(InkButtonStyle())
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.5 : 1.0)
            
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
