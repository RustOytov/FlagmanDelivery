import SwiftUI

struct AuthOTPScreenView: View {
    enum Mode: Equatable {
        case login(phone: String)
        case registration(phone: String, name: String, role: AppRole)
    }

    @Environment(AppSession.self) private var session
    @Environment(\.dependencies) private var dependencies

    let mode: Mode

    @State private var otpFieldText = ""
    @FocusState private var otpFieldFocused: Bool

    @State private var isVerifying = false
    @State private var errorMessage: String?
    @State private var hintPulse = false

    private var code: String {
        String(otpFieldText.filter(\.isNumber).prefix(4))
    }

    private var digits: [Character] {
        Array(code)
    }

    var body: some View {
        AuthFormContainer(
            title: "Код из SMS",
            subtitle: "Введите код:",
            onBack: { session.authBack() }
        ) {
            Text(phoneLabel)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            otpVisualBlock

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.error)
            }

            PrimaryButton(
                title: "Подтвердить",
                isLoading: isVerifying,
                isDisabled: code.count != 4
            ) {
                Task { await verify() }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") {
                    otpFieldFocused = false
                }
                .foregroundStyle(AppTheme.Colors.accent)
            }
        }
        .onAppear {
            otpFieldText = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                otpFieldFocused = true
            }
        }
        .onChange(of: otpFieldText) { _, newValue in
            let filtered = String(newValue.filter(\.isNumber).prefix(4))
            if filtered != newValue {
                otpFieldText = filtered
            }
        }
    }

    private var mockHint: String {
        "Код 1234 всегда подходит"
    }

    private var phoneLabel: String {
        switch mode {
        case .login(let phone), .registration(let phone, _, _):
            return phone
        }
    }

    private var otpVisualBlock: some View {
        ZStack {
            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(0 ..< 4, id: \.self) { index in
                    otpCell(index: index)
                }
            }
            .allowsHitTesting(false)

            TextField("", text: $otpFieldText)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($otpFieldFocused)
                .multilineTextAlignment(.center)
                .font(AppTheme.Typography.title1)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .tint(AppTheme.Colors.accent)
                .frame(maxWidth: .infinity, minHeight: 56)
                .opacity(0.02)
                .accessibilityLabel("Код из SMS, 4 цифры")
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .onTapGesture {
            otpFieldFocused = true
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }

    private func otpCell(index: Int) -> some View {
        let hasDigit = index < digits.count
        let ch = hasDigit ? String(digits[index]) : ""
        let isActive = otpFieldFocused && code.count == index

        return ZStack {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .fill(AppTheme.Colors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                        .stroke(
                            isActive ? AppTheme.Colors.accent : AppTheme.Colors.border,
                            lineWidth: isActive ? 2 : 1
                        )
                )
                .frame(height: 56)

            Text(ch)
                .font(AppTheme.Typography.title1)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private func verify() async {
        guard code.count == 4, !isVerifying else { return }
        errorMessage = nil
        isVerifying = true
        defer { isVerifying = false }
        do {
            let ok = try await dependencies.auth.verifyOTP(code)
            if ok {
                switch mode {
                case .login(let phone):
                    session.finalizeLoginIfRecognized(phone: phone)
                case .registration(let phone, let name, let role):
                    if role == .owner {
                        session.launchOwnerOnboarding(phone: phone, name: name)
                    } else {
                        session.completeRegistration(phone: phone, name: name, role: role)
                    }
                }
            } else {
                errorMessage = "Неверный код"
                otpFieldText = ""
                otpFieldFocused = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AuthOTPScreenView(mode: .login(phone: "+7 900 000-00-00"))
        .environment(AppSession())
        .environment(\.dependencies, PreviewData.dependencies)
}
