import Foundation

public struct MealPlan: Codable, Identifiable {
    public var id: UUID
    public var date: Date
    public var title: String
    public var totalCalories: Double
    public var totalProtein: Double
    public var totalCarbs: Double
    public var totalFat: Double
    public var meals: [MealItem]
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        title: String = "Menú Diario Óptimo",
        totalCalories: Double,
        totalProtein: Double,
        totalCarbs: Double,
        totalFat: Double,
        meals: [MealItem]
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFat = totalFat
        self.meals = meals
    }
}

public struct MealItem: Codable, Identifiable {
    public var id: UUID
    public var category: String // "Desayuno", "Almuerzo", "Merienda", "Cena"
    public var name: String
    public var description: String
    public var calories: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    public var isCompleted: Bool
    
    public init(
        id: UUID = UUID(),
        category: String,
        name: String,
        description: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.description = description
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.isCompleted = isCompleted
    }
}
