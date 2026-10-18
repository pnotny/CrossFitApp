import SwiftUI

/// Povinná přihlašovací brána — appka se nedá použít bez platné session.
/// Adresa Workeru má pevně danou výchozí hodnotu (AuthService.defaultServerURL),
/// takže ji běžně nikdo nezadává — jde změnit jen přes skryté „Pokročilé" pro
/// případ, že by se Worker musel někdy přesunout na jinou adresu.
struct LoginView: View {
    @EnvironmentObject var store: AppStore
    @State private var mode: Mode = .login
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showServerField = false

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
                    Text(mode == .login ? store.t("login_subtitle") : store.t("register_subtitle"))
                        .font(.system(size: 13))
                        .foregroundColor(DT.fgMuted)
                }
                .padding(.top, 24)

                SegmentedPicker(options: [(Mode.login, store.t("login_tab")), (Mode.register, store.t("register_tab"))], selection: $mode)

                VStack(alignment: .leading, spacing: 12) {
                    field(label: store.t("username"), text: $username, placeholder: "admin")
                    secureField(label: store.t("password"), text: $password)
                }
                .cardStyle()

                advancedServerSection
                languagePicker

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
                        Text(mode == .login ? store.t("login_button") : store.t("register_button"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.dtPrimary)
                .disabled(!canSubmit || store.authInFlight)
            }
            .padding(16)
        }
        .background(DT.bg)
    }

    private var advancedServerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { showServerField.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(store.t("advanced_server"))
                    Image(systemName: showServerField ? "chevron.up" : "chevron.down")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DT.fgMuted)
            }
            .buttonStyle(.plain)

            if showServerField {
                field(label: store.t("server_address"), text: $store.authServerUrl, placeholder: "https://crossfit-coach-strava-proxy.xxx.workers.dev", keyboard: .URL)
            }
        }
    }

    private var languagePicker: some View {
        HStack(spacing: 4) {
            Text(store.t("language") + ":")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DT.fgMuted)
            Button(store.language.label) { store.cycleLanguage() }
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(DT.accentText)
        }
    }

    private var canSubmit: Bool {
        !store.authServerUrl.trimmingCharacters(in: .whitespaces).isEmpty
            && !username.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
    }

    private func submit() async {
        let server = store.authServerUrl.trimmingCharacters(in: .whitespaces)
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
