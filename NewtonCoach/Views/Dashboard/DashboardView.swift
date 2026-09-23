import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingWeightModal = false
    @State private var newWeightText = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header con saludo y alerta de cumpleaños
                    headerCard
                    
                    // Card Principal de Peso y Meta
                    weightGoalCard
                    
                    // Resumen de Objetivos Nutricionales
                    nutritionTargetsCard
                    
                    // Acceso Rápido a Acciones
                    quickActionsGrid
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("NewtonCoach")
            .sheet(isPresented: $showingWeightModal) {
                weightEntrySheet
            }
        }
    }
    
    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hola, \(appState.userProfile.name)")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("\(appState.userProfile.age) años • \(appState.userProfile.daysRemaining) días restantes")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            
            if appState.userProfile.isBirthdayToday {
                HStack(spacing: 4) {
                    Image(systemName: "birthday.cake.fill")
                        .foregroundColor(.pink)
                    Text("¡Tu Día!")
                        .font(.caption.bold())
                        .foregroundColor(.pink)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.pink.opacity(0.15))
                .cornerRadius(12)
            }
        }
    }
    
    private var weightGoalCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Progreso de Peso")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button(action: {
                    newWeightText = String(format: "%.1f", appState.userProfile.currentWeightKg)
                    showingWeightModal = true
                }) {
                    Label("Registrar", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.primaryNeon)
                }
            }
            
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    Text("Actual")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(String(format: "%.1f kg", appState.userProfile.currentWeightKg))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(AppTheme.primaryNeon)
                    .font(.title3)
                
                VStack(alignment: .leading) {
                    Text("Meta")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(String(format: "%.1f kg", appState.userProfile.targetWeightKg))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primaryNeon)
                }
            }
            
            let delta = appState.userProfile.weightDelta
            let sign = delta > 0 ? "+" : ""
            Text("Diferencia restante: \(sign)\(String(format: "%.1f", delta)) kg en \(appState.userProfile.daysRemaining) días")
                .font(.footnote)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }
    
    private var nutritionTargetsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Objetivo Diario de Macros")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            HStack {
                VStack {
                    Text("\(Int(appState.currentTargets.targetCalories))")
                        .font(.title2.bold())
                        .foregroundColor(AppTheme.textPrimary)
                    Text("kcal")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider().background(AppTheme.surfaceElevated)
                
                macroColumn(name: "Proteína", grams: appState.currentTargets.proteinGrams, color: .red)
                macroColumn(name: "Carbos", grams: appState.currentTargets.carbGrams, color: .orange)
                macroColumn(name: "Grasas", grams: appState.currentTargets.fatGrams, color: .blue)
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }
    
    private func macroColumn(name: String, grams: Double, color: Color) -> some View {
        VStack {
            Text("\(Int(grams))g")
                .font(.title3.bold())
                .foregroundColor(color)
            Text(name)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Acciones Rápidas")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            HStack(spacing: 12) {
                NavigationLink(destination: MealPlanView()) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.title2)
                            .foregroundColor(AppTheme.primaryNeon)
                        Text("Ver Menú de Hoy")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppTheme.surface)
                    .cornerRadius(14)
                }
                
                NavigationLink(destination: CoachChatView()) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.secondaryAccent)
                        Text("Consultar Coach")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppTheme.surface)
                    .cornerRadius(14)
                }
            }
        }
    }
    
    private var weightEntrySheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Actualizar Peso")
                    .font(.title3.bold())
                    .foregroundColor(AppTheme.textPrimary)
                
                TextField("Peso en kg", text: $newWeightText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(AppTheme.surfaceElevated)
                    .cornerRadius(12)
                
                Button(action: {
                    if let w = Double(newWeightText.replacingOccurrences(of: ",", with: ".")) {
                        appState.updateWeight(newWeight: w)
                        showingWeightModal = false
                    }
                }) {
                    Text("Guardar Pesaje")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryNeon)
                        .cornerRadius(12)
                }
                Spacer()
            }
            .padding()
            .background(AppTheme.background.ignoresSafeArea())
        }
        .presentationDetents([.fraction(0.4)])
    }
}
