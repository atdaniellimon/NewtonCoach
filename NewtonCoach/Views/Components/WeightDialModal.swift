import SwiftUI

public struct WeightDialModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var weightInput: String = ""
    @State private var selectedUnit: UnitSystem
    @FocusState private var isFieldFocused: Bool
    @State private var showSuccessNotice = false
    
    public init() {
        _selectedUnit = State(initialValue: .metric)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 6) {
                    Text("Registrar Peso Corporal")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Pésate preferiblemente en ayunas por la mañana")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.top, 10)
                
                // Selector Segmentado de Unidad
                Picker("Unidad", selection: $selectedUnit) {
                    Text("kg").tag(UnitSystem.metric)
                    Text("lbs").tag(UnitSystem.imperial)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
                .onChange(of: selectedUnit) { newUnit in
                    updateInputForUnit(newUnit)
                }
                
                // Entrada Masiva con Focus
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("0.0", text: $weightInput)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 60, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .focused($isFieldFocused)
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(minWidth: 160)
                    
                    Text(selectedUnit == .imperial ? "LBS" : "KG")
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppTheme.exerciseGreen)
                }
                .padding(.vertical, 8)
                
                // Steppers de Ajuste Rápido (+/- 0.1, +/- 0.5, +/- 1.0)
                HStack(spacing: 12) {
                    stepperButton("-1.0", delta: -1.0)
                    stepperButton("-0.1", delta: -0.1)
                    stepperButton("+0.1", delta: 0.1)
                    stepperButton("+1.0", delta: 1.0)
                }
                
                // Botón Sincronizar desde Apple Health
                if HealthKitManager.shared.isAvailable {
                    Button(action: importFromAppleHealth) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(AppTheme.moveRed)
                            Text("Importar pesaje desde Apple Health")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppTheme.surfaceElevated)
                        .cornerRadius(20)
                    }
                }
                
                Spacer()
                
                // Botón Guardar con Haptic Feedback
                Button(action: saveWeight) {
                    Text("Guardar y Sincronizar")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.exerciseGreen)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .padding()
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .onAppear {
                self.selectedUnit = appState.userProfile.unitSystem
                updateInputForUnit(selectedUnit)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFieldFocused = true
                }
            }
        }
        .presentationDetents([.fraction(0.65)])
    }
    
    private func updateInputForUnit(_ unit: UnitSystem) {
        let kg = appState.userProfile.currentWeightKg
        if unit == .imperial {
            weightInput = String(format: "%.1f", kg * 2.20462)
        } else {
            weightInput = String(format: "%.1f", kg)
        }
    }
    
    private func stepperButton(_ label: String, delta: Double) -> some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            let clean = weightInput.replacingOccurrences(of: ",", with: ".")
            if var current = Double(clean) {
                current += delta
                weightInput = String(format: "%.1f", max(10, current))
            }
        }) {
            Text(label)
                .font(.footnote.weight(.bold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.surfaceElevated)
                .cornerRadius(12)
        }
    }
    
    private func importFromAppleHealth() {
        HealthKitManager.shared.fetchLatestWeight { weightInKg in
            if let w = weightInKg {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                if selectedUnit == .imperial {
                    weightInput = String(format: "%.1f", w * 2.20462)
                } else {
                    weightInput = String(format: "%.1f", w)
                }
            }
        }
    }
    
    private func saveWeight() {
        guard let kgValue = UnitFormatter.shared.parseWeightToKg(input: weightInput, system: selectedUnit) else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        appState.updateWeight(newWeight: kgValue)
        
        // Sincronizar hacia Apple Health si está habilitado
        if appState.userProfile.syncWithHealthKit {
            HealthKitManager.shared.saveWeightToHealthKit(weightKg: kgValue) { _, _ in }
        }
        
        dismiss()
    }
}
