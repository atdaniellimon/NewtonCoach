import SwiftUI

public struct NutritionDiaryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddFood = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header de Consumo vs Meta
                    calorieTargetHero
                    
                    // Barras de Macros Detalladas
                    macroBarsCard
                    
                    // Lista de Alimentos Registrados Hoy
                    loggedFoodListSection
                }
                .padding(.vertical)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Diario Nutricional")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFood = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.exerciseGreen)
                    }
                }
            }
            .sheet(isPresented: $showingAddFood) {
                CameraScanView()
            }
        }
    }
    
    private var calorieTargetHero: some View {
        let consumed = appState.userProfile.todayConsumedCalories
        let target = appState.currentTargets.targetCalories
        let remaining = max(0, target - consumed)
        
        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Consumido Hoy")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("\(Int(consumed)) KCAL")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.moveRed)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Restantes")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("\(Int(remaining)) KCAL")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.exerciseGreen)
                }
            }
            
            ProgressView(value: min(1.0, consumed / max(1.0, target)))
                .tint(AppTheme.moveRed)
        }
        .padding(18)
        .background(AppTheme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
        .padding(.horizontal)
    }
    
    private var macroBarsCard: some View {
        VStack(spacing: 14) {
            macroRow(
                name: "Proteína",
                consumed: appState.userProfile.todayConsumedProtein,
                target: appState.currentTargets.proteinGrams,
                color: AppTheme.standCyan
            )
            macroRow(
                name: "Carbohidratos",
                consumed: appState.userProfile.todayConsumedCarbs,
                target: appState.currentTargets.carbGrams,
                color: AppTheme.exerciseGreen
            )
            macroRow(
                name: "Grasas",
                consumed: appState.userProfile.todayConsumedFat,
                target: appState.currentTargets.fatGrams,
                color: AppTheme.awardGold
            )
        }
        .padding(18)
        .background(AppTheme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
        .padding(.horizontal)
    }
    
    private func macroRow(name: String, consumed: Double, target: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(name)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(Int(consumed)) / \(Int(target))g")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(color)
            }
            ProgressView(value: min(1.0, consumed / max(1.0, target)))
                .tint(color)
        }
    }
    
    private var loggedFoodListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Alimentos de Hoy")
                    .font(.headline.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(appState.userProfile.todayLoggedFoods.count) items")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal)
            
            if appState.userProfile.todayLoggedFoods.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("No has registrado comidas hoy")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    Button(action: { showingAddFood = true }) {
                        Text("Registrar con Foto o Texto")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.exerciseGreen)
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(AppTheme.surface)
                .cornerRadius(20)
                .padding(.horizontal)
            } else {
                ForEach(appState.userProfile.todayLoggedFoods) { food in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(food.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(AppTheme.textPrimary)
                            if !food.description.isEmpty {
                                Text(food.description)
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .lineLimit(2)
                            }
                            HStack(spacing: 8) {
                                Text("\(Int(food.protein))g P")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(AppTheme.standCyan)
                                Text("•")
                                    .foregroundColor(AppTheme.textSecondary)
                                Text("\(Int(food.carbs))g C")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(AppTheme.exerciseGreen)
                                Text("•")
                                    .foregroundColor(AppTheme.textSecondary)
                                Text("\(Int(food.fat))g G")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(AppTheme.awardGold)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("\(Int(food.calories)) KCAL")
                                .font(.footnote.weight(.bold))
                                .foregroundColor(AppTheme.moveRed)
                            
                            Button(action: {
                                withAnimation {
                                    appState.removeLoggedFood(id: food.id)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.surface)
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
        }
    }
}
