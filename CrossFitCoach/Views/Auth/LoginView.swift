import SwiftUI

/// Povinná přihlašovací brána — appka se nedá použít bez platné session.
/// Stejný Worker backend obsluhuje přihlašování i Strava export, proto appka
/// žádá i adresu serveru (jen při prvním přihlášení/registraci).
struct LoginView: View {
    @EnvironmentObject var store: AppStore
    @State private var mode: Mode = .login
    @State private var serverUrl: String = ""
    @State private var username: String = ""
    @State private var password: String = ""

    private enum Mode: Hashable {
        case login, register
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CrossFit Coach")
                        .font(DF.display(28))
                        .foregroundColor(DT.fg)
                    Text(mode == .login ? "Přihlas se ke svému účtu" : "Vytvoř si nový účet")
                        .font(.system(size: 13))
                        .foregroundColor(DT.fgMuted)
                }
                .padding(.top, 24)

                SegmentedPicker(options: [(Mode.login, "Přihlásit"), (Mode.register, "Registrovat")], selection: $mode)

                VStack(alignment: .leading, spacing: 12) {
                    field(label: "Adresa serveru", text: $serverUrl, placeholder: "https://crossfit-coach-strava-proxy.xxx.workers.dev", keyboard: .URL)
                    field(label: "Uživatelské jméno", text: $username, placeholder: "admin")
                    secureField(label: "Heslo", text: $password)
                }
                .cardStyle()

                if let error = store.authError {
                    Text(error)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DT.danger)
                }

                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if store.authInFlight { ProgressView().tint(DT.accentInk) }
                        Text(mode == .login ? "Přihlásit se" : "Vytvořit účet")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.dtPrimary)
                .disabled(!canSubmit || store.authInFlight)
            }
            .padding(16)
        }
        .background(DT.bg)
        .onAppear { serverUrl = store.authServerUrl }
    }

    private var canSubmit: Bool {
        !serverUrl.trimmingCharacters(in: .whitespaces).isEmpty
            && !username.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
    }

    private func submit() async {
        let server = serverUrl.trimmingCharacters(in: .whitespaces)
        let user = username.trimmingCharacters(in: .whitespaces)
        switch mode {
        case .login:
            await store.login(serverUrl: server, username: user, password: password)
        case .register:
            await store.register(serverUrl: server, username: user, password: password)
        }
    }

    private func field(label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 11, weight: .heavy)).trackedUppercase(0.2).foregroundColor(DT.fgMuted)
            TextField(placeholder, text: text)
                .foregroundColor(DT.fg)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(keyboard)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(DT.surface)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(DT.line, lineWidth: 1))
        }
    }

    private func secureField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 11, weight: .heavy)).trackedUppercase(0.2).foregroundColor(DT.fgMuted)
            SecureField("", text: text)
                .foregroundColor(DT.fg)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(DT.surface)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(DT.line, lineWidth: 1))
        }
    }
}
