import SwiftUI

public final class AppState: ObservableObject {
    @Published public var userProfile: UserProfile
    @Published public var currentTargets: NutritionTargets
    @Published public var todayMenu: MealPlan?
    @Published public var isLoadingMenu: Bool = false
    @Published public var errorMessage: String?
    
    private let profileKey = "newton_user_profile_v1"
    private let menuKey = "newton_today_menu_v1"
    
    public init() {
        let loadedProfile: UserProfile
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            loadedProfile = profile
        } else {
            loadedProfile = UserProfile()
        }
        
        self.userProfile = loadedProfile
        self.currentTargets = NutritionEngine.shared.calculateTargets(for: loadedProfile)
        
        if let menuData = UserDefaults.standard.data(forKey: menuKey),
           let menu = try? JSONDecoder().decode(MealPlan.self, from: menuData) {
            self.todayMenu = menu
        } else {
            self.todayMenu = nil
        }
    }
    
    public func saveProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
        self.currentTargets = NutritionEngine.shared.calculateTargets(for: userProfile)
        AchievementManager.shared.evaluateAchievements(profile: userProfile)
        NotificationManager.shared.scheduleDefaultReminders()
    }
    
    public func updateWeight(newWeight: Double) {
        userProfile.currentWeightKg = newWeight
        userProfile.weightHistory.append(WeightEntry(date: Date(), weightKg: newWeight))
        saveProfile()
    }
    
    public func logFood(name: String, description: String = "", calories: Double, protein: Double, carbs: Double, fat: Double) {
        let entry = LoggedFoodEntry(
            name: name,
            description: description,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
        userProfile.loggedFoods.append(entry)
        saveProfile()
    }
    
    public func removeLoggedFood(id: UUID) {
        userProfile.loggedFoods.removeAll { $0.id == id }
        saveProfile()
    }
    
    public func toggleMealPlanCompleted(mealId: UUID) {
        guard var menu = todayMenu,
              let index = menu.meals.firstIndex(where: { $0.id == mealId }) else { return }
        
        menu.meals[index].isCompleted.toggle()
        let meal = menu.meals[index]
        self.todayMenu = menu
        
        if meal.isCompleted {
            // Registrar como consumido
            logFood(
                name: meal.name,
                description: meal.description,
                calories: meal.calories,
                protein: meal.protein,
                carbs: meal.carbs,
                fat: meal.fat
            )
        } else {
            // Desmarcar de consumidos si existe con el mismo nombre y fecha de hoy
            if let lastIndex = userProfile.loggedFoods.lastIndex(where: { $0.name == meal.name && Calendar.current.isDateInToday($0.date) }) {
                userProfile.loggedFoods.remove(at: lastIndex)
                saveProfile()
            }
        }
        
        if let data = try? JSONEncoder().encode(menu) {
            UserDefaults.standard.set(data, forKey: menuKey)
        }
    }
    
    public func fetchOrRegenerateMenu() {
        isLoadingMenu = true
        errorMessage = nil
        Task { @MainActor in
            do {
                let menu = try await NewtonAIService.shared.generateDailyMenu(for: userProfile, targets: currentTargets)
                self.todayMenu = menu
                if let data = try? JSONEncoder().encode(menu) {
                    UserDefaults.standard.set(data, forKey: self.menuKey)
                }
                self.isLoadingMenu = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoadingMenu = false
            }
        }
    }
}
