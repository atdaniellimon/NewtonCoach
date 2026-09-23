import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var notificationManager = NotificationManager.shared
    
    // Auth Newton Labs
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    @State private var isLoggingIn: Bool = false
    @State private var loginError: String?
    
    // Datos Newton
    @State private var userCredits: Double?
    @State private var userTierName: String?
    @State private var userEmail: String?
    
    @State private var showingWeightModal = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                // Sección 1: Apple Health Sync
                Section(header: Text("Apple Health (HealthKit)")) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(AppTheme.moveRed)
                        VStack(alignment: .leading) {
                            Text("Sincronizar con Apple Health")
                                .font(.subheadline.weight(.semibold))
                            Text("Lectura y escritura de pesajes y altura")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: $appState.userProfile.syncWithHealthKit)
                            .tint(AppTheme.exerciseGreen)
                            .onChange(of: appState.userProfile.syncWithHealthKit) { enabled in
                                if enabled {
                                    HealthKitManager.shared.requestAuthorization { _, _ in }
                                }
                                appState.saveProfile()
                            }
                    }
                    
                    Button(action: importHealthData) {
                        HStack {
                            Text("Importar datos más recientes de Salud")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.exerciseGreen)
                            Spacer()
                            Image(systemName: "arrow.down.heart.fill")
                                .foregroundColor(AppTheme.exerciseGreen)
                        }
                    }
                }
                
                // Sección 2: Sistema de Unidades Dual
                Section(header: Text("Unidades de Medida")) {
                    Picker("Sistema", selection: $appState.userProfile.unitSystem) {
                        ForEach(UnitSystem.allCases) { system in
                            Text(system.rawValue).tag(system)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: appState.userProfile.unitSystem) { _ in
                        appState.saveProfile()
                    }
                }
                
                // Sección 3: Datos Biométricos & Peso
                Section(header: Text("Perfil Biométrico & Metas")) {
                    HStack {
                        Text("Peso Actual")
                        Spacer()
                        Button(action: { showingWeightModal = true }) {
                            Text(UnitFormatter.shared.formatWeight(appState.userProfile.currentWeightKg, system: appState.userProfile.unitSystem))
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(AppTheme.exerciseGreen)
                        }
                    }
                    
                    HStack {
                        Text("Peso Objetivo")
                        Spacer()
                        TextField("Meta", value: $appState.userProfile.targetWeightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: appState.userProfile.targetWeightKg) { _ in appState.saveProfile() }
                    }
                    
                    DatePicker("Fecha Objetivo", selection: $appState.userProfile.targetDate, in: Date()..., displayedComponents: .date)
                        .onChange(of: appState.userProfile.targetDate) { _ in appState.saveProfile() }
                    
                    DatePicker("Cumpleaños", selection: $appState.userProfile.birthDate, displayedComponents: .date)
                        .onChange(of: appState.userProfile.birthDate) { _ in appState.saveProfile() }
                    
                    HStack {
                        Text("Edad")
                        Spacer()
                        Text("\(appState.userProfile.age) años")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    HStack {
                        Text("Altura")
                        Spacer()
                        Text(UnitFormatter.shared.formatHeight(appState.userProfile.heightCm, system: appState.userProfile.unitSystem))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                // Sección 4: Notificaciones y Recordatorios
                Section(header: Text("Notificaciones & Recordatorios")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Recordatorios Activos")
                            Text("Pesaje (7:30 AM), Comidas (13:30) y Entreno (18:00)")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        if notificationManager.isAuthorized {
                            Text("Activo")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.exerciseGreen)
                        } else {
                            Button("Activar") {
                                notificationManager.requestAuthorization()
                            }
                            .foregroundColor(AppTheme.exerciseGreen)
                        }
                    }
                }
                
                // Sección 5: Cuenta Newton Labs (Autenticación Oficial)
                Section(header: Text("Cuenta Newton Labs Gateway")) {
                    if let key = KeychainManager.shared.getApiKey(), !key.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(AppTheme.exerciseGreen)
                                Text("Sesión Activa")
                                    .font(.headline)
                            }
                            if let email = userEmail {
                                Text(email).font(.subheadline).foregroundColor(AppTheme.textSecondary)
                            }
                            if let tier = userTierName {
                                Text("Plan: \(tier)").font(.caption.bold()).foregroundColor(AppTheme.exerciseGreen)
                            }
                            if let credits = userCredits {
                                Text("Créditos restantes: \(Int(credits)) tokens").font(.caption).foregroundColor(AppTheme.textSecondary)
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
                            SecureField("Contraseña", text: $passwordInput)
                            
                            if isLoggingIn {
                                ProgressView("Autenticando en Newton Labs...")
                            } else {
                                Button(action: loginWithNewton) {
                                    Text("Iniciar Sesión (POST /auth/login)")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(AppTheme.exerciseGreen)
                                }
                                .disabled(usernameInput.isEmpty || passwordInput.isEmpty)
                            }
                            if let err = loginError {
                                Text(err).font(.caption).foregroundColor(AppTheme.danger)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ajustes")
            .sheet(isPresented: $showingWeightModal) {
                WeightDialModal()
            }
            .onAppear {
                refreshNewtonProfile()
            }
        }
    }
    
    private func importHealthData() {
        HealthKitManager.shared.fetchLatestWeight { w in
            if let w = w {
                appState.updateWeight(newWeight: w)
            }
        }
        HealthKitManager.shared.fetchLatestHeight { h in
            if let h = h {
                appState.userProfile.heightCm = h
                appState.saveProfile()
            }
        }
        HealthKitManager.shared.fetchBirthDate()
        if let b = HealthKitManager.shared.birthDateFromHealth {
            appState.userProfile.birthDate = b
            appState.saveProfile()
        }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func loginWithNewton() {
        isLoggingIn = true
        loginError = nil
        Task { @MainActor in
            do {
                let res = try await NewtonAPIClient.shared.login(username: usernameInput, password: passwordInput)
                self.userEmail = res.email
                self.userTierName = res.tier?.name
                self.userCredits = res.credits_left
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
        userEmail = nil
        userTierName = nil
        userCredits = nil
    }
}
