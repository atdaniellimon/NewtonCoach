import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingWeightModal = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header de Usuario Estilo Summary
                    summaryHeader
                    
                    // Banner Conmemorativo de Cumpleaños (Si aplica)
                    if appState.userProfile.isBirthdayToday {
                        birthdayBanner
                    }
                    
                    // Hero Card: Anillos de Rendimiento Concéntricos (Apple Activity Rings)
                    activityRingsHeroCard
                    
                    // Grid Modular 2x2 (Idéntico a Captura 3 de Apple Fitness)
                    fitnessGrid2x2
                    
                    // Acceso Rápido a Rutinas y Nutrición
                    quickWorkoutBanner
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showingWeightModal) {
                WeightDialModal()
            }
        }
    }
    
    private var summaryHeader: some View {
        HStack {
            Text("Summary")
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            // Avatar Circular Deportivo
            ZStack {
                Circle()
                    .fill(AppTheme.surfaceElevated)
                    .frame(width: 44, height: 44)
                
                Text("🤠")
                    .font(.title2)
            }
        }
        .padding(.top, 10)
    }
    
    private var birthdayBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "birthday.cake.fill")
                .font(.title2)
                .foregroundColor(AppTheme.awardGold)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("¡Feliz Cumpleaños \(appState.userProfile.name)!")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Desbloqueaste la medalla conmemorativa anual.")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(AppTheme.awardGold.opacity(0.12))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.awardGold.opacity(0.3), lineWidth: 1))
    }
    
    private var activityRingsHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Activity Rings")
                .font(.headline.weight(.bold))
                .foregroundColor(AppTheme.textPrimary)
            
            HStack(spacing: 24) {
                // Anillos Concéntricos Animados
                let consumedCals = appState.userProfile.todayConsumedCalories
                let targetCals = max(1.0, appState.currentTargets.targetCalories)
                let caloriesRatio = min(1.0, consumedCals / targetCals)
                
                let weightRatio = min(1.0, max(0.05, 1.0 - (abs(appState.userProfile.weightDelta) / 10.0)))
                
                let consumedProt = appState.userProfile.todayConsumedProtein
                let targetProt = max(1.0, appState.currentTargets.proteinGrams)
                let proteinRatio = min(1.0, consumedProt / targetProt)
                
                ActivityRingsView(
                    caloriesProgress: caloriesRatio,
                    weightProgress: weightRatio,
                    proteinProgress: proteinRatio
                )
                
                // Leyenda a la derecha
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Move")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(Int(consumedCals))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.moveRed)
                            Text("/ \(Int(targetCals)) KCAL")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Goal Weight")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textSecondary)
                        Text(UnitFormatter.shared.formatWeight(appState.userProfile.targetWeightKg, system: appState.userProfile.unitSystem))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.exerciseGreen)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Protein Target")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(Int(consumedProt))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.standCyan)
                            Text("/ \(Int(targetProt)) G")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                Spacer()
            }
        }

        .padding(18)
        .background(AppTheme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
    }
    
    private var fitnessGrid2x2: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            // Tarjeta 1: Peso Actual
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                showingWeightModal = true
            }) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Weight")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text(UnitFormatter.shared.formatWeight(appState.userProfile.currentWeightKg, system: appState.userProfile.unitSystem))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    // Micro-gráfica de barras horarias simuladas
                    HStack(alignment: .bottom, spacing: 3) {
                        bar(height: 12)
                        bar(height: 18)
                        bar(height: 24, active: true)
                        bar(height: 20)
                        bar(height: 16)
                    }
                    .frame(height: 30)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 155, alignment: .leading)
                .background(AppTheme.surface)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            
            // Tarjeta 2: Meta y Días Restantes
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Target")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Text("\(appState.userProfile.daysRemaining) DÍAS")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppTheme.exerciseGreen)
                
                Text(UnitFormatter.shared.formatWeight(appState.userProfile.targetWeightKg, system: appState.userProfile.unitSystem))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.exerciseGreen)
                    .monospacedDigit()
                
                Spacer()
                
                Text("Ritmo recomendado:\n-0.5 kg por semana")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 155, alignment: .leading)
            .background(AppTheme.surface)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
            
            // Tarjeta 3: Nutrición y Calorías de Hoy
            NavigationLink(destination: MealPlanView()) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Nutrition")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    let consumed = appState.userProfile.todayConsumedCalories
                    let target = appState.currentTargets.targetCalories
                    
                    Text("Today's Diet")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(Int(consumed))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.exerciseGreen)
                        Text("/ \(Int(target))")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(appState.userProfile.todayConsumedProtein))g / \(Int(appState.currentTargets.proteinGrams))g Proteína")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 155, alignment: .leading)
                .background(AppTheme.surface)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            
            // Tarjeta 4: Awards / Premios con Medalla 3D
            NavigationLink(destination: AchievementsView()) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Awards")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppTheme.awardGold.opacity(0.2))
                                .frame(width: 52, height: 52)
                            Image(systemName: "trophy.fill")
                                .font(.title)
                                .foregroundColor(AppTheme.awardGold)
                        }
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Text("Newton Discipline")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 155, alignment: .leading)
                .background(AppTheme.surface)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var quickWorkoutBanner: some View {
        NavigationLink(destination: WorkoutListView()) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.exerciseGreen)
                        .frame(width: 48, height: 48)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Iniciar Entrenamiento de Hoy")
                        .font(.headline.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Fuerza, registro de series y temporizador RPE")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding()
            .background(AppTheme.workoutCardBg)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.exerciseGreen.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
    
    private func bar(height: CGFloat, active: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(active ? AppTheme.standCyan : AppTheme.surfaceBorder)
            .frame(width: 6, height: height)
    }
}
