import Foundation

public enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "Masculino"
    case female = "Femenino"
    case other = "Otro"
    
    public var id: String { rawValue }
}

public enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary = "Sedentario (Poco o nada de ejercicio)"
    case light = "Ligero (1-3 días por semana)"
    case moderate = "Moderado (3-5 días por semana)"
    case active = "Activo (6-7 días por semana)"
    case veryActive = "Muy Activo (Doble sesión / Trabajo físico pesado)"
    
    public var id: String { rawValue }
    
    public var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}

public struct WeightEntry: Codable, Identifiable {
    public var id: UUID
    public var date: Date
    public var weightKg: Double
    
    public init(id: UUID = UUID(), date: Date = Date(), weightKg: Double) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
    }
}

public struct LoggedFoodEntry: Codable, Identifiable {
    public var id: UUID
    public var date: Date
    public var name: String
    public var description: String
    public var calories: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        name: String,
        description: String = "",
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.description = description
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

public struct UserProfile: Codable {
    public var name: String
    public var birthDate: Date
    public var gender: Gender
    public var heightCm: Double
    public var currentWeightKg: Double
    public var targetWeightKg: Double
    public var targetDate: Date
    public var activityLevel: ActivityLevel
    public var unitSystem: UnitSystem
    public var syncWithHealthKit: Bool
    public var weightHistory: [WeightEntry]
    public var loggedFoods: [LoggedFoodEntry]
    
    public init(
        name: String = "Daniel",
        birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
        gender: Gender = .male,
        heightCm: Double = 175.0,
        currentWeightKg: Double = 78.0,
        targetWeightKg: Double = 72.0,
        targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
        activityLevel: ActivityLevel = .moderate,
        unitSystem: UnitSystem = .metric,
        syncWithHealthKit: Bool = false,
        weightHistory: [WeightEntry] = [],
        loggedFoods: [LoggedFoodEntry] = []
    ) {
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.heightCm = heightCm
        self.currentWeightKg = currentWeightKg
        self.targetWeightKg = targetWeightKg
        self.targetDate = targetDate
        self.activityLevel = activityLevel
        self.unitSystem = unitSystem
        self.syncWithHealthKit = syncWithHealthKit
        self.weightHistory = weightHistory.isEmpty ? [WeightEntry(date: Date(), weightKg: currentWeightKg)] : weightHistory
        self.loggedFoods = loggedFoods
    }
    
    public var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return max(0, ageComponents.year ?? 0)
    }
    
    public var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return max(0, components.day ?? 0)
    }
    
    public var weightDelta: Double {
        return targetWeightKg - currentWeightKg
    }
    
    public var isBirthdayToday: Bool {
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.month, .day], from: Date())
        let birthComponents = calendar.dateComponents([.month, .day], from: birthDate)
        return todayComponents.month == birthComponents.month && todayComponents.day == birthComponents.day
    }
    
    /// Alimentos consumidos hoy
    public var todayLoggedFoods: [LoggedFoodEntry] {
        let calendar = Calendar.current
        return loggedFoods.filter { calendar.isDateInToday($0.date) }
    }
    
    public var todayConsumedCalories: Double {
        return todayLoggedFoods.reduce(0) { $0 + $1.calories }
    }
    
    public var todayConsumedProtein: Double {
        return todayLoggedFoods.reduce(0) { $0 + $1.protein }
    }
    
    public var todayConsumedCarbs: Double {
        return todayLoggedFoods.reduce(0) { $0 + $1.carbs }
    }
    
    public var todayConsumedFat: Double {
        return todayLoggedFoods.reduce(0) { $0 + $1.fat }
    }
}

