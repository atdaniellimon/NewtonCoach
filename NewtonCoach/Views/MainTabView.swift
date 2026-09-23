import SwiftUI

public struct MainTabView: View {
    @StateObject private var appState = AppState()
    
    public init() {}
    
    public var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Summary", systemImage: "circle.grid.cross.fill")
                }
            
            WorkoutListView()
                .tabItem {
                    Label("Workout", systemImage: "figure.run.circle.fill")
                }
            
            MealPlanView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife.circle.fill")
                }
            
            CoachChatView()
                .tabItem {
                    Label("Coach", systemImage: "bubble.left.and.bubble.right.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.circle.fill")
                }
        }
        .environmentObject(appState)
        .accentColor(AppTheme.exerciseGreen)
        .onAppear {
            NotificationManager.shared.checkAuthorization()
        }
    }
}
