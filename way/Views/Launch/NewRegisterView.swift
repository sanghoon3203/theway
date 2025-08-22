// 📁 Views/Launch/NewRegisterView.swift
import SwiftUI

struct NewRegisterView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.presentationMode) var presentationMode
    @State private var playerName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var acceptTerms = false
    @State private var isLoading = false
    @FocusState private var focusedField: RegisterField?
    
    enum RegisterField {
        case playerName, email, password, confirmPassword
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
            
            ScrollView {
                VStack(spacing: 30) {
                    // 상단 만리 로고
                    Image("GameLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 200)
                        .padding(.top, 40)
                    
                    // 입력 필드들
                    VStack(spacing: 25) {
                        // 여행자 이름
                        VStack(alignment: .leading, spacing: 10) {
                            Text("여행자 이름")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                                .padding(.leading, 5)
                            
                            TextField("게임에서 사용할 이름을 입력하세요", text: $playerName)
                                .font(.system(size: 16))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(
                                                    focusedField == .playerName ? 
                                                    Color.black.opacity(0.4) : Color.black.opacity(0.2),
                                                    lineWidth: focusedField == .playerName ? 2 : 1
                                                )
                                        )
                                )
                                .focused($focusedField, equals: .playerName)
                                .onSubmit {
                                    focusedField = .email
                                }
                            
                            if !playerName.isEmpty && (playerName.count < 2 || playerName.count > 20) {
                                Text("여행자 이름은 2-20자 사이여야 합니다")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(.leading, 5)
                            }
                        }
                        
                        // 이메일
                        VStack(alignment: .leading, spacing: 10) {
                            Text("이메일")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                                .padding(.leading, 5)
                            
                            TextField("이메일 주소를 입력하세요", text: $email)
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
                            
                            if !email.isEmpty && !isValidEmail(email) {
                                Text("올바른 이메일 형식을 입력해주세요")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(.leading, 5)
                            }
                        }
                        
                        // 비밀번호
                        VStack(alignment: .leading, spacing: 10) {
                            Text("비밀번호")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                                .padding(.leading, 5)
                            
                            SecureField("6자 이상의 비밀번호를 입력하세요", text: $password)
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
                                    focusedField = .confirmPassword
                                }
                            
                            if !password.isEmpty && password.count < 6 {
                                Text("비밀번호는 6자 이상이어야 합니다")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(.leading, 5)
                            }
                        }
                        
                        // 비밀번호 확인
                        VStack(alignment: .leading, spacing: 10) {
                            Text("비밀번호 확인")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                                .padding(.leading, 5)
                            
                            SecureField("비밀번호를 다시 입력하세요", text: $confirmPassword)
                                .font(.system(size: 16))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(
                                                    focusedField == .confirmPassword ? 
                                                    Color.black.opacity(0.4) : Color.black.opacity(0.2),
                                                    lineWidth: focusedField == .confirmPassword ? 2 : 1
                                                )
                                        )
                                )
                                .focused($focusedField, equals: .confirmPassword)
                                .onSubmit {
                                    performRegister()
                                }
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("비밀번호가 일치하지 않습니다")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(.leading, 5)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // 약관 동의
                    HStack(alignment: .top, spacing: 12) {
                        Button {
                            acceptTerms.toggle()
                        } label: {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(acceptTerms ? Color.black : Color.black.opacity(0.3), lineWidth: 2)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(acceptTerms ? .black : .clear)
                                )
                        }
                        
                        Text("모든 약관을 확인하고 동의 동의합니다.")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    
                    // 버튼들
                    HStack(spacing: 20) {
                        // 회원가입 버튼
                        Button(action: {
                            performRegister()
                        }) {
                            Image("register_reg_button")
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
                    .padding(.bottom, 40)
                    
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
            }
            
            // 로딩 오버레이
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(1.2)
                    
                    Text("회원가입 중...")
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
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !playerName.isEmpty &&
        isValidEmail(email) &&
        password.count >= 6 &&
        password == confirmPassword &&
        playerName.count >= 2 &&
        playerName.count <= 20 &&
        acceptTerms
    }
    
    // MARK: - Functions
    private func performRegister() {
        // 키보드 숨기기
        focusedField = nil
        
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            await gameManager.register(
                email: email,
                password: password,
                playerName: playerName
            )
            
            await MainActor.run {
                isLoading = false
                
                // 회원가입 성공시 메인 앱으로 이동
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
    NewRegisterView()
        .environmentObject(GameManager())
}