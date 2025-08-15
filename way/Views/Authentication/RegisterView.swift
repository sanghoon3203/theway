// 📁 Views/Authentication/RegisterView.swift
import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var playerName = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var isLoading = false
    @State private var acceptTerms = false
    @FocusState private var focusedField: RegisterField?
    
    enum RegisterField {
        case email, password, confirmPassword, playerName
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 수묵화 스타일 타이틀
                VStack(spacing: 16) {
                    Text("회원가입")
                        .font(.brushStroke)
                        .fontWeight(.semibold)
                        .foregroundColor(.brushText)
                    
                    Text("새로운 여행자가 되어 만리길을 시작하세요")
                        .font(.inkText)
                        .foregroundColor(.fadeText)
                        .multilineTextAlignment(.center)
                }
                
                // 수묵화 스타일 입력 필드들
                VStack(spacing: 24) {
                    // 여행자 이름 (플레이어명)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("여행자 이름")
                            .font(.inkText)
                            .foregroundColor(.brushText)
                        
                        TextField("홍길동", text: $playerName)
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
                                                focusedField == .playerName ? Color.inkBlack.opacity(0.4) : Color.inkBlack.opacity(0.2), 
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
                                .font(.whisperText)
                                .foregroundColor(.fadeText)
                        }
                    }
                    
                    // 이메일 필드
                    VStack(alignment: .leading, spacing: 10) {
                        Text("이메일")
                            .font(.inkText)
                            .foregroundColor(.brushText)
                        
                        TextField("example@email.com", text: $email)
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
                        
                        if !email.isEmpty && !isValidEmail(email) {
                            Text("올바른 이메일 형식을 입력해주세요")
                                .font(.whisperText)
                                .foregroundColor(.fadeText)
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
                                    TextField("최소 6자 이상", text: $password)
                                } else {
                                    SecureField("최소 6자 이상", text: $password)
                                }
                            }
                            .font(.inkText)
                            .foregroundColor(.brushText)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                focusedField = .confirmPassword
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
                        
                        // 비밀번호 강도 표시
                        if !password.isEmpty {
                            InkPasswordStrengthIndicator(password: password)
                        }
                    }
                    
                    // 비밀번호 확인 필드
                    VStack(alignment: .leading, spacing: 10) {
                        Text("비밀번호 확인")
                            .font(.inkText)
                            .foregroundColor(.brushText)
                        
                        HStack {
                            Group {
                                if isConfirmPasswordVisible {
                                    TextField("비밀번호를 다시 입력하세요", text: $confirmPassword)
                                } else {
                                    SecureField("비밀번호를 다시 입력하세요", text: $confirmPassword)
                                }
                            }
                            .font(.inkText)
                            .foregroundColor(.brushText)
                            .focused($focusedField, equals: .confirmPassword)
                            .onSubmit {
                                performRegister()
                            }
                            
                            Button {
                                isConfirmPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isConfirmPasswordVisible ? NavigationIcons.eye : NavigationIcons.eyeSlash)
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
                                            focusedField == .confirmPassword ? Color.inkBlack.opacity(0.4) : Color.inkBlack.opacity(0.2), 
                                            lineWidth: focusedField == .confirmPassword ? 2 : 1
                                        )
                                )
                        )
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("비밀번호가 일치하지 않습니다")
                                .font(.whisperText)
                                .foregroundColor(.fadeText)
                        }
                    }
                }
                
                // 약관 동의 - 수묵화 스타일
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        acceptTerms.toggle()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(acceptTerms ? Color.brushText : Color.fadeText, lineWidth: 2)
                                .frame(width: 18, height: 18)
                            
                            if acceptTerms {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.brushText)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("서비스 이용약관에 동의합니다")
                            .font(.inkText)
                            .foregroundColor(.brushText)
                        
                        Text("개인정보 처리방침 및 이용약관에 동의하며, 좋은 여행을 약속합니다.")
                            .font(.whisperText)
                            .foregroundColor(.fadeText)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                
                // 회원가입 버튼 - 수묵화 스타일
                Button {
                    performRegister()
                } label: {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .brushText))
                                .scaleEffect(0.9)
                        }
                        
                        Text("여행 시작하기")
                            .font(.brushStroke)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(InkButtonStyle())
                .disabled(isLoading || !isFormValid)
                .opacity(isFormValid ? 1.0 : 0.5)
                
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
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameManager.errorMessage)
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
        
        // 최종 검증
        guard isFormValid else {
            return
        }
        
        isLoading = true
        
        Task {
            await gameManager.register(
                email: email,
                password: password,
                playerName: playerName
            )
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

// MARK: - 수묵화 스타일 비밀번호 강도 표시
struct InkPasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        if password.count < 6 {
            return .weak
        } else if password.count < 8 {
            return .medium
        } else if password.count >= 8 && hasSpecialCharacters {
            return .strong
        } else {
            return .medium
        }
    }
    
    private var hasSpecialCharacters: Bool {
        let regex = ".*[!&^%$#@()/]+.*"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(strengthColor(for: index))
                        .frame(width: 6, height: 6)
                }
            }
            
            Text(strength.description)
                .font(.whisperText)
                .foregroundColor(strength.inkColor)
        }
    }
    
    private func strengthColor(for index: Int) -> Color {
        switch strength {
        case .weak:
            return index == 0 ? .fadeText : .inkMist
        case .medium:
            return index <= 1 ? .brushText.opacity(0.6) : .inkMist
        case .strong:
            return .brushText
        }
    }
}

enum PasswordStrength {
    case weak, medium, strong
    
    var description: String {
        switch self {
        case .weak: return "보안이 약합니다 (6자 이상 필요)"
        case .medium: return "적절한 보안입니다"
        case .strong: return "안전한 보안입니다"
        }
    }
    
    var inkColor: Color {
        switch self {
        case .weak: return .fadeText
        case .medium: return .brushText.opacity(0.6)
        case .strong: return .brushText
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(GameManager())
        .inkCard()
        .padding()
        .background(LinearGradient.paperBackground)
}
