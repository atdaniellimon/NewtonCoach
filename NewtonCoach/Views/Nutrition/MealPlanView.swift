import SwiftUI

public struct MealPlanView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingCameraScan = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header del Menú
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.todayMenu?.title ?? "Plan Nutricional Diario")
                            .font(.title3.bold())
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Personalizado según tu meta de \(String(format: "%.1f", appState.userProfile.targetWeightKg)) kg")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    
                    Button(action: {
                        appState.fetchOrRegenerateMenu()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryNeon)
                            .padding(10)
                            .background(AppTheme.surfaceElevated)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                
                // Botón Escáner MacroLens con Cámara
                Button(action: {
                    showingCameraScan = true
                }) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Escanear Plato con IA (MacroLens)")
                                .font(.subheadline.bold())
                            Text("Foto instantánea para estimar calorías y macros")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(AppTheme.primaryNeon)
                    .padding()
                    .background(AppTheme.surface)
                    .cornerRadius(14)
                    .padding(.horizontal)
                }
                
                if appState.isLoadingMenu {
                    ProgressView("Newton AI diseñando tu menú...")
                        .tint(AppTheme.primaryNeon)
                        .padding(.top, 40)
                } else if let menu = appState.todayMenu {
                    // Lista de comidas del día
                    VStack(spacing: 14) {
                        ForEach(menu.meals) { meal in
                            mealCard(meal: meal)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 16) {
                        Text("No tienes un menú generado para hoy aún.")
                            .foregroundColor(AppTheme.textSecondary)
                        Button(action: {
                            appState.fetchOrRegenerateMenu()
                        }) {
                            Text("Generar Menú con Newton AI")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .background(AppTheme.primaryNeon)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 40)
                }
            }
            .padding(.vertical)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Menú Recomendado")
        .sheet(isPresented: $showingCameraScan) {
            CameraScanView()
        }
    }
    
    private func mealCard(meal: MealItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(meal.category.uppercased())
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.primaryNeon)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryNeon.opacity(0.12))
                    .cornerRadius(8)
                Spacer()
                Text("\(Int(meal.calories)) kcal")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Text(meal.name)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(meal.description)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            HStack(spacing: 16) {
                Label("\(Int(meal.protein))g P", systemImage: "flame.fill")
                    .foregroundColor(.red)
                Label("\(Int(meal.carbs))g C", systemImage: "leaf.fill")
                    .foregroundColor(.orange)
                Label("\(Int(meal.fat))g G", systemImage: "drop.fill")
                    .foregroundColor(.blue)
            }
            .font(.caption)
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }
}
