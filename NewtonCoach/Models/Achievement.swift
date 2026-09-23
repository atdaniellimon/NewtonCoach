import Foundation

public struct Achievement: Codable, Identifiable {
    public var id: String
    public var title: String
    public var description: String
    public var icon: String // SF Symbol o Emoji
    public var isUnlocked: Bool
    public var unlockedDate: Date?
    public var progress: Double // 0.0 a 1.0
    
    public init(
        id: String,
        title: String,
        description: String,
        icon: String,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil,
        progress: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.progress = progress
    }
}

public final class AchievementManager: ObservableObject {
    public static let shared = AchievementManager()
    
    private let storageKey = "newton_achievements_v1"
    @Published public var achievements: [Achievement] = []
    
    private init() {
        loadAchievements()
    }
    
    public func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            self.achievements = saved
        } else {
            self.achievements = defaultAchievements
            save()
        }
    }
    
    public func save() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    public func evaluateAchievements(profile: UserProfile, mealsLogged: Int = 0, scansCount: Int = 0) {
        var updated = false
        
        // 1. Primer Paso (Tener perfil configurado)
        if unlock("first_step") { updated = true }
        
        // 2. Cumpleaños deportivo
        if profile.isBirthdayToday {
            if unlock("birthday_hero") { updated = true }
        }
        
        // 3. Progreso de peso hacia la meta
        let initialWeight = profile.weightHistory.first?.weightKg ?? profile.currentWeightKg
        let weightChange = abs(profile.currentWeightKg - initialWeight)
        if weightChange >= 2.0 {
            if unlock("weight_milestone_2kg") { updated = true }
        }
        if weightChange >= 5.0 {
            if unlock("weight_milestone_5kg") { updated = true }
        }
        
        // 4. Escáner de comidas con Newton Vision
        if scansCount >= 1 {
            if unlock("first_scan") { updated = true }
        }
        if scansCount >= 10 {
            if unlock("scan_master") { updated = true }
        }
        
        // 5. Constancia de comidas
        if mealsLogged >= 10 {
            if unlock("nutrition_discipline") { updated = true }
        }
        
        if updated {
            save()
        }
    }
    
    @discardableResult
    public func unlock(_ id: String) -> Bool {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return false }
        if !achievements[index].isUnlocked {
            achievements[index].isUnlocked = true
            achievements[index].unlockedDate = Date()
            achievements[index].progress = 1.0
            return true
        }
        return false
    }
    
    private var defaultAchievements: [Achievement] {
        [
            Achievement(
                id: "first_step",
                title: "Primer Paso",
                description: "Configura tu perfil, peso actual y meta en NewtonCoach.",
                icon: "flag.checkered"
            ),
            Achievement(
                id: "birthday_hero",
                title: "Cumpleaños en Acción",
                description: "¡Entrenando o cuidando tu nutrición el día de tu cumpleaños!",
                icon: "birthday.cake.fill"
            ),
            Achievement(
                id: "weight_milestone_2kg",
                title: "En Marcha (-2kg / +2kg)",
                description: "Primeros 2 kg de progreso hacia tu peso ideal.",
                icon: "flame.fill"
            ),
            Achievement(
                id: "weight_milestone_5kg",
                title: "Transformación Real (-5kg / +5kg)",
                description: "¡5 kg de progreso comprobado! Tu disciplina está pagando.",
                icon: "bolt.heart.fill"
            ),
            Achievement(
                id: "first_scan",
                title: "Ojo Nutricional",
                description: "Analizaste tu primer plato usando la IA de Newton.",
                icon: "camera.viewfinder"
            ),
            Achievement(
                id: "scan_master",
                title: "Master Vision",
                description: "Has analizado más de 10 comidas con la cámara.",
                icon: "sparkles"
            ),
            Achievement(
                id: "nutrition_discipline",
                title: "Disciplina Newtoniana",
                description: "Registraste y cumpliste más de 10 comidas de tu menú.",
                icon: "trophy.fill"
            )
        ]
    }
}
