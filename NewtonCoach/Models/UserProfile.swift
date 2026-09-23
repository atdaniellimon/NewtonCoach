import Foundation

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
        syncWithHealthKit: Bool = true,
        weightHistory: [WeightEntry] = []
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
}
