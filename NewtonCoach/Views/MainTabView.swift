import SwiftUI

public struct MainTabView: View {
    @StateObject private var appState = AppState()
    
    public init() {}
    
    public var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Inicio", systemImage: "bolt.fill")
                }
            
            MealPlanView()
                .tabItem {
                    Label("Menú", systemImage: "fork.knife")
                }
            
            CoachChatView()
                .tabItem {
                    Label("Coach", systemImage: "bubble.left.and.bubble.right.fill")
                }
            
            AchievementsView()
                .tabItem {
                    Label("Logros", systemImage: "trophy.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
        }
        .environmentObject(appState)
        .accentColor(AppTheme.primaryNeon)
        .onAppear {
            NotificationManager.shared.checkAuthorization()
        }
    }
}
