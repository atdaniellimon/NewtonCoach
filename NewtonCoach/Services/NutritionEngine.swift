import Foundation

public struct NutritionTargets: Codable {
    public var tmb: Double
    public var tdee: Double
    public var targetCalories: Double
    public var proteinGrams: Double
    public var carbGrams: Double
    public var fatGrams: Double
    public var dailyCalorieDelta: Double // déficit o superávit diario necesario
}

public final class NutritionEngine {
    public static let shared = NutritionEngine()
    
    private init() {}
    
    /// Calcula TMB usando la fórmula Mifflin-St Jeor (la más validada científicamente)
    public func calculateTargets(for profile: UserProfile) -> NutritionTargets {
        let weight = profile.currentWeightKg
        let height = profile.heightCm
        let age = Double(profile.age)
        
        // Mifflin-St Jeor Base
        var tmb: Double
        if profile.gender == .female {
            tmb = (10 * weight) + (6.25 * height) - (5 * age) - 161
        } else {
            tmb = (10 * weight) + (6.25 * height) - (5 * age) + 5
        }
        
        let tdee = tmb * profile.activityLevel.multiplier
        
        // 1 kg de grasa corporal ≈ 7700 kcal
        let totalWeightDelta = profile.weightDelta // Negativo = perder peso, Positivo = ganar
        let days = max(14, profile.daysRemaining) // Mínimo 14 días para evitar cálculos extremos
        
        let totalCaloriesNeeded = totalWeightDelta * 7700.0
        var dailyDelta = totalCaloriesNeeded / Double(days)
        
        // Limitar déficit diario a máximo -750 kcal (saludable) o superávit a +500 kcal (volumen limpio)
        dailyDelta = min(500.0, max(-750.0, dailyDelta))
        
        var targetCalories = tdee + dailyDelta
        // Suelo mínimo de seguridad calórica
        if profile.gender == .female {
            targetCalories = max(1200.0, targetCalories)
        } else {
            targetCalories = max(1500.0, targetCalories)
        }
        
        // Distribución de Macronutrientes para deportista / entrenamiento de fuerza:
        // Proteína: 2.0g - 2.2g por kg de peso corporal
        let proteinGrams = weight * 2.0
        let proteinCalories = proteinGrams * 4.0
        
        // Grasas saludables: ~25% de las calorías totales (mínimo 0.8g por kg)
        let fatCalories = max(weight * 0.8 * 9.0, targetCalories * 0.25)
        let fatGrams = fatCalories / 9.0
        
        // Carbohidratos: El resto de calorías disponibles
        let remainingCalories = max(0, targetCalories - (proteinCalories + fatCalories))
        let carbGrams = remainingCalories / 4.0
        
        return NutritionTargets(
            tmb: tmb,
            tdee: tdee,
            targetCalories: targetCalories,
            proteinGrams: proteinGrams,
            carbGrams: carbGrams,
            fatGrams: fatGrams,
            dailyCalorieDelta: dailyDelta
        )
    }
}
