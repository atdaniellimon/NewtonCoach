import SwiftUI

public struct AchievementsView: View {
    @ObservedObject var achievementManager = AchievementManager.shared
    @EnvironmentObject var appState: AppState
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header con Progreso General
                    let unlockedCount = achievementManager.achievements.filter { $0.isUnlocked }.count
                    let total = achievementManager.achievements.count
                    
                    VStack(spacing: 8) {
                        Text("\(unlockedCount) de \(total) Desbloqueados")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        ProgressView(value: Double(unlockedCount), total: Double(total))
                            .tint(AppTheme.primaryNeon)
                            .padding(.horizontal, 20)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.surface)
                    .cornerRadius(16)
                    
                    // Lista de Logros
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(achievementManager.achievements) { item in
                            achievementCard(item)
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Logros")
        }
    }
    
    private func achievementCard(_ item: Achievement) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.isUnlocked ? AppTheme.primaryNeon.opacity(0.15) : AppTheme.surfaceElevated)
                    .frame(width: 56, height: 56)
                
                Image(systemName: item.icon)
                    .font(.title2)
                    .foregroundColor(item.isUnlocked ? AppTheme.primaryNeon : AppTheme.textSecondary)
            }
            
            Text(item.title)
                .font(.headline)
                .foregroundColor(item.isUnlocked ? AppTheme.textPrimary : AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            Text(item.description)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            if item.isUnlocked {
                Text("Desbloqueado")
                    .font(.caption2.bold())
                    .foregroundColor(AppTheme.success)
            } else {
                Text("Bloqueado")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(AppTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(item.isUnlocked ? AppTheme.primaryNeon.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
}
