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
            VStack(spacing: 24) {
                // 타이틀
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: NavigationIcons.flag)
                            .font(.title2)
                            .foregroundColor(.seaBlue)
                        
                        Text("함대 창설")
                            .font(.navigatorTitle)
                            .foregroundColor(.seaBlue)
                    }
                    
                    Text("새로운 무역왕이 되어보세요")
                        .font(.compassSmall)
                        .foregroundColor(.stormGray)
                }
                
                // 입력 필드들
                VStack(spacing: 20) {
                    // 선장 이름 (플레이어명)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: NavigationIcons.person)
                                .font(.caption)
                                .foregroundColor(.seaBlue)
                            
                            Text("선장 이름")
                                .font(.compassSmall)
                                .foregroundColor(.seaBlue)
                        }
                        
                        TextField("무역왕 홍길동", text: $playerName)
                            .textFieldStyle(NavigatorTextFieldStyle())
                            .focused($focusedField, equals: .playerName)
                            .onSubmit {
                                focusedField = .email
                            }
                        
                        if !playerName.isEmpty && (playerName.count < 2 || playerName.count > 20) {
                            Text("선장 이름은 2-20자 사이여야 합니다")
                                .font(.caption)
                                .foregroundColor(.compass)
                        }
                    }
                    
                    // 이메일 필드
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.caption)
                                .foregroundColor(.seaBlue)
                            
                            Text("함대 본부 연락처")
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
                        
                        if !email.isEmpty && !isValidEmail(email) {
                            Text("올바른 이메일 형식을 입력해주세요")
                                .font(.caption)
                                .foregroundColor(.compass)
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
                                    TextField("최소 6자 이상", text: $password)
                                } else {
                                    SecureField("최소 6자 이상", text: $password)
                                }
                            }
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                focusedField = .confirmPassword
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
                        
                        // 비밀번호 강도 표시
                        if !password.isEmpty {
                            PasswordStrengthIndicator(password: password)
                        }
                    }
                    
                    // 비밀번호 확인 필드
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.shield")
                                .font(.caption)
                                .foregroundColor(.seaBlue)
                            
                            Text("항로 확인")
                                .font(.compassSmall)
                                .foregroundColor(.seaBlue)
                        }
                        
                        HStack {
                            Group {
                                if isConfirmPasswordVisible {
                                    TextField("비밀번호를 다시 입력", text: $confirmPassword)
                                } else {
                                    SecureField("비밀번호를 다시 입력", text: $confirmPassword)
                                }
                            }
                            .focused($focusedField, equals: .confirmPassword)
                            .onSubmit {
                                performRegister()
                            }
                            
                            Button {
                                isConfirmPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isConfirmPasswordVisible ? NavigationIcons.eye : NavigationIcons.eyeSlash)
                                    .font(.body)
                                    .foregroundColor(.stormGray)
                            }
                            .padding(.trailing, 4)
                        }
                        .textFieldStyle(NavigatorTextFieldStyle())
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("비밀번호가 일치하지 않습니다")
                                .font(.caption)
                                .foregroundColor(.compass)
                        }
                    }
                }
                
                // 약관 동의
                HStack(alignment: .top) {
                    Button {
                        acceptTerms.toggle()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(acceptTerms ? Color.treasureGold : Color.mistGray, lineWidth: 2)
                                .frame(width: 20, height: 20)
                            
                            if acceptTerms {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.treasureGold)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("무역 길드 규약에 동의합니다")
                            .font(.merchantBody)
                            .foregroundColor(.seaBlue)
                        
                        Text("개인정보 처리방침 및 이용약관에 동의하며, 공정한 거래를 약속합니다.")
                            .font(.caption)
                            .foregroundColor(.stormGray)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                
                // 회원가입 버튼
                Button {
                    performRegister()
                } label: {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: NavigationIcons.crown)
                                .font(.body)
                            
                            Text("무역왕이 되기")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(TreasureButtonStyle())
                .disabled(isLoading || !isFormValid)
                .opacity(isFormValid ? 1.0 : 0.6)
                
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

// MARK: - Password Strength Indicator
struct PasswordStrengthIndicator: View {
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Rectangle()
                        .fill(strengthColor(for: index))
                        .frame(height: 3)
                        .cornerRadius(1.5)
                }
            }
            
            Text(strength.description)
                .font(.caption)
                .foregroundColor(strength.color)
        }
    }
    
    private func strengthColor(for index: Int) -> Color {
        switch strength {
        case .weak:
            return index == 0 ? .compass : .mistGray
        case .medium:
            return index <= 1 ? .treasureGold : .mistGray
        case .strong:
            return .seaBlue
        }
    }
}

enum PasswordStrength {
    case weak, medium, strong
    
    var description: String {
        switch self {
        case .weak: return "약한 항로 (6자 이상 필요)"
        case .medium: return "괜찮은 항로"
        case .strong: return "안전한 항로"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .compass
        case .medium: return .treasureGold
        case .strong: return .seaBlue
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(GameManager())
        .parchmentCard()
        .padding()
        .background(LinearGradient.oceanWave)
}
