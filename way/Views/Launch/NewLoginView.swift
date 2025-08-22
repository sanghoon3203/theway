// 📁 Views/Launch/NewLoginView.swift
import SwiftUI

struct NewLoginView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @FocusState private var focusedField: LoginField?
    
    enum LoginField {
        case email, password
    }
    
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // 상단 만리 로고
                Image("GameLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 220)
                
                Spacer()
                
                // 입력 필드들
                VStack(spacing: 30) {
                    // 아이디 (이메일) 입력
                    VStack(alignment: .leading, spacing: 10) {
                        Text("아이디")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.leading, 5)
                        
                        TextField("이메일을 입력하세요", text: $email)
                            .font(.system(size: 16))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(
                                                focusedField == .email ? 
                                                Color.black.opacity(0.4) : Color.black.opacity(0.2),
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
                    
                    // 비밀번호 입력
                    VStack(alignment: .leading, spacing: 10) {
                        Text("비밀번호")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.leading, 5)
                        
                        SecureField("비밀번호를 입력하세요", text: $password)
                            .font(.system(size: 16))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(
                                                focusedField == .password ? 
                                                Color.black.opacity(0.4) : Color.black.opacity(0.2),
                                                lineWidth: focusedField == .password ? 2 : 1
                                            )
                                    )
                            )
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                performLogin()
                            }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // 버튼들
                HStack(spacing: 20) {
                    // 로그인 버튼
                    Button(action: {
                        performLogin()
                    }) {
                        Image("Logn_reg_button")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 55)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    // 뒤로가기 버튼
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("back_reg_button")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 55)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                
                // 에러 메시지 표시
                if let errorMessage = gameManager.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 30)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // 로딩 오버레이
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(1.2)
                    
                    Text("로그인 중...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.95))
                        .shadow(radius: 10)
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameManager.errorMessage)
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .onTapGesture {
            // 화면 터치시 키보드 숨김
            focusedField = nil
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email) && password.count >= 6
    }
    
    // MARK: - Functions
    private func performLogin() {
        // 키보드 숨기기
        focusedField = nil
        
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            await gameManager.login(email: email, password: password)
            
            await MainActor.run {
                isLoading = false
                
                // 로그인 성공시 메인 앱으로 이동
                if gameManager.isAuthenticated {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

#Preview {
    NewLoginView()
        .environmentObject(GameManager())
}