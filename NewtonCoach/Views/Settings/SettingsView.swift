import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var notificationManager = NotificationManager.shared
    @State private var apiKey: String = ""
    @State private var hasSavedKey = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Sección de Datos Personales
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
                
                // Sección de Credenciales Newton Labs AI
                Section(header: Text("Newton Labs API Gateway"), footer: Text("Tu API Key se almacena de forma segura en el Keychain del iPhone y nunca abandona tu dispositivo.")) {
                    SecureField("ntwn-...", text: $apiKey)
                    Button(action: {
                        if KeychainManager.shared.saveApiKey(apiKey) {
                            hasSavedKey = true
                        }
                    }) {
                        Text("Guardar API Key")
                            .foregroundColor(AppTheme.primaryNeon)
                    }
                    if hasSavedKey {
                        Text("Clave guardada con éxito en Keychain.")
                            .font(.caption)
                            .foregroundColor(AppTheme.success)
                    }
                }
            }
            .navigationTitle("Ajustes")
            .onAppear {
                if let key = KeychainManager.shared.getApiKey() {
                    self.apiKey = key
                }
            }
        }
    }
}
