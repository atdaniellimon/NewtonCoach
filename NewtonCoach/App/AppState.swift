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
