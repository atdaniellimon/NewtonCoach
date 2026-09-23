import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var notificationManager = NotificationManager.shared
    
    // Estados para Login con Newton Labs (/auth/login)
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    @State private var isLoggingIn: Bool = false
    @State private var loginError: String?
    @State private var loginSuccessMessage: String?
    
    // Estado de cuenta Newton
    @State private var userCredits: Double?
    @State private var userTierName: String?
    @State private var userEmail: String?
    
    // Clave manual de fallback
    @State private var manualApiKey: String = ""
    @State private var hasSavedKey = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                // Sección de Autenticación Oficial Newton Labs (/auth/login y /auth/me)
                Section(header: Text("Cuenta Newton Labs (Autenticación Oficial)"), footer: Text("Inicia sesión con tu cuenta de Newton Labs para sincronizar tu cuota y autorizar peticiones.")) {
                    if let key = KeychainManager.shared.getApiKey(), !key.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(AppTheme.success)
                                Text("Sesión Activa")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            if let email = userEmail {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            if let tier = userTierName {
                                Text("Plan: \(tier)")
                                    .font(.caption.bold())
                                    .foregroundColor(AppTheme.primaryNeon)
                            }
                            if let credits = userCredits {
                                Text("Créditos restantes: \(Int(credits)) tokens")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            
                            Button(role: .destructive, action: logoutNewton) {
                                Text("Cerrar Sesión")
                            }
                            .padding(.top, 4)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Usuario o Email", text: $usernameInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            SecureField("Contraseña", text: $passwordInput)
                            
                            if isLoggingIn {
                                ProgressView("Conectando con api.newton.daniellimon.uk...")
                            } else {
                                Button(action: loginWithNewton) {
                                    Text("Iniciar Sesión (POST /auth/login)")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.primaryNeon)
                                }
                                .disabled(usernameInput.isEmpty || passwordInput.isEmpty)
                            }
                            
                            if let error = loginError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.danger)
                            }
                        }
                    }
                }
                
                // Fallback o Edición manual de API Key
                Section(header: Text("API Key Manual"), footer: Text("Alternativamente puedes ingresar directamente un token ntwn-...")) {
                    SecureField("ntwn-...", text: $manualApiKey)
                    Button(action: {
                        if KeychainManager.shared.saveApiKey(manualApiKey) {
                            hasSavedKey = true
                            refreshNewtonProfile()
                        }
                    }) {
                        Text("Guardar Token Manual")
                            .foregroundColor(AppTheme.primaryNeon)
                    }
                    if hasSavedKey {
                        Text("Token guardado en Keychain.")
                            .font(.caption)
                            .foregroundColor(AppTheme.success)
                    }
                }
                
                // Sección de Datos Biométricos
                Section("Datos Biométricos") {
                    TextField("Nombre", text: $appState.userProfile.name)
                        .onChange(of: appState.userProfile.name) { _ in appState.saveProfile() }
                    
                    DatePicker("Cumpleaños", selection: $appState.userProfile.birthDate, displayedComponents: .date)
                        .onChange(of: appState.userProfile.birthDate) { _ in appState.saveProfile() }
                    
                    HStack {
                        Text("Edad Calculada")
                        Spacer()
                        Text("\(appState.userProfile.age) años")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Picker("Género", selection: $appState.userProfile.gender) {
                        ForEach(Gender.allCases) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                    .onChange(of: appState.userProfile.gender) { _ in appState.saveProfile() }
                    
                    HStack {
                        Text("Altura (cm)")
                        Spacer()
                        TextField("cm", value: $appState.userProfile.heightCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: appState.userProfile.heightCm) { _ in appState.saveProfile() }
                    }
                    
                    Picker("Nivel de Actividad", selection: $appState.userProfile.activityLevel) {
                        ForEach(ActivityLevel.allCases) { a in
                            Text(a.rawValue).tag(a)
                        }
                    }
                    .onChange(of: appState.userProfile.activityLevel) { _ in appState.saveProfile() }
                }
                
                // Sección de Meta Temporal
                Section("Meta de Peso & Plazo") {
                    HStack {
                        Text("Peso Objetivo (kg)")
                        Spacer()
                        TextField("kg", value: $appState.userProfile.targetWeightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: appState.userProfile.targetWeightKg) { _ in appState.saveProfile() }
                    }
                    
                    DatePicker("Fecha Objetivo", selection: $appState.userProfile.targetDate, in: Date()..., displayedComponents: .date)
                        .onChange(of: appState.userProfile.targetDate) { _ in appState.saveProfile() }
                    
                    HStack {
                        Text("Días Restantes")
                        Spacer()
                        Text("\(appState.userProfile.daysRemaining) días")
                            .foregroundColor(AppTheme.primaryNeon)
                    }
                }
                
                // Sección de Notificaciones y Recordatorios
                Section("Notificaciones & Recordatorios") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Recordatorios Diarios")
                            Text("Pesaje (7:30 AM), Comidas (13:30) y Entreno (18:00)")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        if notificationManager.isAuthorized {
                            Text("Activo")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.success)
                        } else {
                            Button("Activar") {
                                notificationManager.requestAuthorization()
                            }
                            .foregroundColor(AppTheme.primaryNeon)
                        }
                    }
                }
            }
            .navigationTitle("Ajustes")
            .onAppear {
                if let key = KeychainManager.shared.getApiKey() {
                    self.manualApiKey = key
                    refreshNewtonProfile()
                }
            }
        }
    }
    
    private func loginWithNewton() {
        isLoggingIn = true
        loginError = nil
        Task { @MainActor in
            do {
                let res = try await NewtonAPIClient.shared.login(username: usernameInput, password: passwordInput)
                if let key = res.api_key {
                    self.manualApiKey = key
                    self.userEmail = res.email
                    self.userTierName = res.tier?.name
                    self.userCredits = res.credits_left
                }
                self.isLoggingIn = false
                refreshNewtonProfile()
            } catch {
                self.loginError = error.localizedDescription
                self.isLoggingIn = false
            }
        }
    }
    
    private func refreshNewtonProfile() {
        Task { @MainActor in
            if let profile = try? await NewtonAPIClient.shared.getProfileMe() {
                self.userEmail = profile.email
                self.userTierName = profile.tier?.name
                self.userCredits = profile.credits?.remaining
            }
        }
    }
    
    private func logoutNewton() {
        KeychainManager.shared.deleteApiKey()
        manualApiKey = ""
        userEmail = nil
        userTierName = nil
        userCredits = nil
    }
}
