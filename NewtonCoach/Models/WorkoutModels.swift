import Foundation

public enum ExerciseCategory: String, Codable, CaseIterable {
    case chest = "Pecho"
    case back = "Espalda"
    case legs = "Pierna"
    case shoulders = "Hombros"
    case arms = "Brazos"
    case core = "Abdomen"
}

public struct WorkoutSet: Codable, Identifiable {
    public var id: UUID
    public var setNumber: Int
    public var weightKg: Double
    public var reps: Int
    public var rir: Int // Repeticiones en reserva (0 = fallo)
    public var isCompleted: Bool
    
    public init(id: UUID = UUID(), setNumber: Int, weightKg: Double, reps: Int, rir: Int = 2, isCompleted: Bool = false) {
        self.id = id
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.rir = rir
        self.isCompleted = isCompleted
    }
    
    /// Estimación 1RM usando la fórmula de Epley
    public var estimatedOneRepMaxKg: Double {
        if reps == 1 { return weightKg }
        return weightKg * (1.0 + Double(reps) / 30.0)
    }
}

public struct ExerciseLog: Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var category: ExerciseCategory
    public var sets: [WorkoutSet]
    
    public init(id: UUID = UUID(), name: String, category: ExerciseCategory, sets: [WorkoutSet] = []) {
        self.id = id
        self.name = name
        self.category = category
        self.sets = sets
    }
}

public struct WorkoutRoutine: Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var subtitle: String
    public var iconName: String
    public var exercises: [ExerciseLog]
    
    public init(id: UUID = UUID(), title: String, subtitle: String, iconName: String, exercises: [ExerciseLog]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.exercises = exercises
    }
}
