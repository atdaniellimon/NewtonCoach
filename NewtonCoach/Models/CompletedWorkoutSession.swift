import Foundation

/// Modelo para una sesión de entrenamiento finalizada
public struct CompletedWorkoutSession: Codable, Identifiable {
    public var id: UUID
    public var date: Date
    public var routineTitle: String
    public var durationMinutes: Int
    public var totalTonnageKg: Double // Peso levantado x reps x series
    public var totalSetsCompleted: Int
    public var notes: String
    public var completedExercises: [CompletedExerciseSnapshot]
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        routineTitle: String,
        durationMinutes: Int,
        totalTonnageKg: Double,
        totalSetsCompleted: Int,
        notes: String = "",
        completedExercises: [CompletedExerciseSnapshot] = []
    ) {
        self.id = id
        self.date = date
        self.routineTitle = routineTitle
        self.durationMinutes = durationMinutes
        self.totalTonnageKg = totalTonnageKg
        self.totalSetsCompleted = totalSetsCompleted
        self.notes = notes
        self.completedExercises = completedExercises
    }
}

public struct CompletedExerciseSnapshot: Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var category: ExerciseCategory
    public var setsCompleted: Int
    public var bestWeightKg: Double
    public var bestReps: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory,
        setsCompleted: Int,
        bestWeightKg: Double,
        bestReps: Int
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.setsCompleted = setsCompleted
        self.bestWeightKg = bestWeightKg
        self.bestReps = bestReps
    }
}

/// Récord personal individual (PR)
public struct PersonalRecord: Codable, Identifiable {
    public var id: UUID
    public var exerciseName: String
    public var category: ExerciseCategory
    public var maxWeightKg: Double
    public var repsAtMaxWeight: Int
    public var estimatedOneRepMaxKg: Double
    public var achievedDate: Date
    
    public init(
        id: UUID = UUID(),
        exerciseName: String,
        category: ExerciseCategory,
        maxWeightKg: Double,
        repsAtMaxWeight: Int,
        estimatedOneRepMaxKg: Double,
        achievedDate: Date = Date()
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.category = category
        self.maxWeightKg = maxWeightKg
        self.repsAtMaxWeight = repsAtMaxWeight
        self.estimatedOneRepMaxKg = estimatedOneRepMaxKg
        self.achievedDate = achievedDate
    }
}
