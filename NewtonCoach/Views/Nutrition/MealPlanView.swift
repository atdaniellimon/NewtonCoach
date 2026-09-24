import SwiftUI

public struct MealPlanView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingCameraScan = false
    @State private var selectedFilter = "Menú de Hoy"
    let filterOptions = ["Menú de Hoy", "Alto en Proteína", "Rápido", "Recetas"]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Estilo Fitness+ Explorer (Captura 2)
                    nutritionHeader
                    
                    // Píldoras Superiores de Filtro
                    filterPills
                    
                    // Banner MacroLens Escáner
                    macroLensBanner
                    
                    // Estado de Carga o Lista de Comidas
                    if appState.isLoadingMenu {
                        ProgressView("Newton AI calculando macros milimétricos...")
                            .tint(AppTheme.exerciseGreen)
                            .padding(.top, 40)
                    } else if let menu = appState.todayMenu {
                        ForEach(menu.meals) { meal in
                            mealCard(meal: meal)
                        }
                    } else {
                        emptyStateNotice
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCameraScan) {
                CameraScanView()
            }
        }
    }
    
    private var nutritionHeader: some View {
        HStack {
            Text("Nutrition")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            NavigationLink(destination: NutritionDiaryView()) {
                HStack(spacing: 4) {
                    Image(systemName: "list.clipboard.fill")
                    Text("Diario")
                }
                .font(.caption2.weight(.bold))
                .foregroundColor(AppTheme.exerciseGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(AppTheme.surfaceElevated)
                .cornerRadius(14)
            }
            
            Button(action: {
                appState.fetchOrRegenerateMenu()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(AppTheme.exerciseGreen)
                    .padding(8)
                    .background(AppTheme.surfaceElevated)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 10)
    }

    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterOptions, id: \.self) { option in
                    Button(action: {
                        selectedFilter = option
                        if option != "Menú de Hoy" {
                            appState.fetchOrRegenerateMenu()
                        }
                    }) {
                        Text(option)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(selectedFilter == option ? .black : AppTheme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == option ? Color.white : AppTheme.surfaceElevated)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    private var macroLensBanner: some View {
        Button(action: {
            showingCameraScan = true
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.exerciseGreen.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "camera.viewfinder")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppTheme.exerciseGreen)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("MacroLens AI (Foto o Texto)")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Escanea tu plato o describe lo que comiste para calcular macros")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(14)
            .background(AppTheme.surface)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
    
    private func mealCard(meal: MealItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(meal.category.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppTheme.exerciseGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.exerciseGreen.opacity(0.15))
                    .cornerRadius(8)
                
                Spacer()
                
                Text("\(Int(meal.calories)) KCAL")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Text(meal.name)
                .font(.headline.weight(.bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(meal.description)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            // Chips de Macros Estilo Apple Fitness
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle().fill(AppTheme.moveRed).frame(width: 8, height: 8)
                    Text("\(Int(meal.protein))g P")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                HStack(spacing: 4) {
                    Circle().fill(AppTheme.standCyan).frame(width: 8, height: 8)
                    Text("\(Int(meal.carbs))g C")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                HStack(spacing: 4) {
                    Circle().fill(AppTheme.awardGold).frame(width: 8, height: 8)
                    Text("\(Int(meal.fat))g G")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                Spacer()
                
                // Botón Check para Registrar Comida
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    appState.toggleMealPlanCompleted(mealId: meal.id)
                }) {
                    Image(systemName: meal.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(meal.isCompleted ? AppTheme.exerciseGreen : AppTheme.textSecondary)
                }
            }
        }
        .padding(18)
        .background(AppTheme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(meal.isCompleted ? AppTheme.exerciseGreen.opacity(0.5) : AppTheme.surfaceBorder, lineWidth: meal.isCompleted ? 1 : 0.5))
    }

    
    private var emptyStateNotice: some View {
        VStack(spacing: 14) {
            Text("No hay menú activo para hoy")
                .foregroundColor(AppTheme.textSecondary)
            Button(action: { appState.fetchOrRegenerateMenu() }) {
                Text("Generar Menú con Newton AI")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.black)
                    .padding()
                    .background(AppTheme.exerciseGreen)
                    .cornerRadius(14)
            }
        }
        .padding(.top, 40)
    }
}
