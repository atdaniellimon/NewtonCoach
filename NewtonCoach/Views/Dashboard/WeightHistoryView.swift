import SwiftUI
import Charts

public struct WeightHistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedRange: Int = 1 // 0 = 1S, 1 = 1M, 2 = 3M, 3 = 1A
    @State private var showingAddWeight = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header de Resumen y Meta
                    metricsSummaryHero
                    
                    // Selector de Rango Temporal
                    Picker("Rango", selection: $selectedRange) {
                        Text("1S").tag(0)
                        Text("1M").tag(1)
                        Text("3M").tag(2)
                        Text("1A").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Gráfica Interactiva con Swift Charts
                    weightChartCard
                    
                    // Tarjetas de Analíticas Biométricas (IMC, BMR, TDEE)
                    biometricInsightsGrid
                    
                    // Lista de Pesajes Cronológicos
                    weightLogListSection
                }
                .padding(.vertical)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Evolución de Peso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWeight = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.exerciseGreen)
                    }
                }
            }
            .sheet(isPresented: $showingAddWeight) {
                WeightDialModal()
            }
        }
    }
    
    private var metricsSummaryHero: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Peso Actual")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.textSecondary)
                Text(UnitFormatter.shared.formatWeight(appState.userProfile.currentWeightKg, system: appState.userProfile.unitSystem))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Meta Objetivo")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.textSecondary)
                Text(UnitFormatter.shared.formatWeight(appState.userProfile.targetWeightKg, system: appState.userProfile.unitSystem))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.exerciseGreen)
            }
        }
        .padding(18)
        .background(AppTheme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
        .padding(.horizontal)
    }
    
    private var filteredWeights: [WeightEntry] {
        let history = appState.userProfile.weightHistory
        guard !history.isEmpty else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate: Date
        
        switch selectedRange {
        case 0: cutoffDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case 1: cutoffDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case 2: cutoffDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case 3: cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        default: cutoffDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        }
        
        let filtered = history.filter { $0.date >= cutoffDate }.sorted { $0.date < $1.date }
        return filtered.isEmpty ? history.suffix(7) : filtered
    }
    
    private var weightChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tendencia Suavizada")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("Línea punteada: Meta")
                    .font(.caption2)
                    .foregroundColor(AppTheme.exerciseGreen)
            }
            
            let data = filteredWeights
            
            if data.count >= 2 {
                Chart {
                    ForEach(data) { entry in
                        LineMark(
                            x: .value("Fecha", entry.date),
                            y: .value("Peso", entry.weightKg)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppTheme.exerciseGreen)
                        
                        PointMark(
                            x: .value("Fecha", entry.date),
                            y: .value("Peso", entry.weightKg)
                        )
                        .foregroundStyle(AppTheme.exerciseGreen)
                    }
                    
                    RuleMark(y: .value("Meta", appState.userProfile.targetWeightKg))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                        .foregroundStyle(AppTheme.exerciseGreen.opacity(0.6))
                }
                .frame(height: 190)
                .chartYScale(domain: (data.map { $0.weightKg }.min() ?? 50) - 2 ... (data.map { $0.weightKg }.max() ?? 90) + 2)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Registra al menos 2 pesajes para ver la curva de tendencia")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            }
        }
        .padding(18)
        .background(AppTheme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
        .padding(.horizontal)
    }
    
    private var biometricInsightsGrid: some View {
        let weight = appState.userProfile.currentWeightKg
        let heightM = appState.userProfile.heightCm / 100.0
        let bmi = weight / max(1.0, (heightM * heightM))
        
        let age = Double(appState.userProfile.age)
        // Mifflin-St Jeor
        let bmr = (10 * weight) + (6.25 * appState.userProfile.heightCm) - (5 * age) + (appState.userProfile.gender == .female ? -161 : 5)
        let tdee = bmr * appState.userProfile.activityLevel.multiplier
        
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            biometricCard(title: "IMC", value: String(format: "%.1f", bmi), subtitle: bmiCategory(bmi))
            biometricCard(title: "BMR", value: "\(Int(bmr))", subtitle: "Reposo (kcal)")
            biometricCard(title: "TDEE", value: "\(Int(tdee))", subtitle: "Gasto Total")
        }
        .padding(.horizontal)
    }
    
    private func bmiCategory(_ val: Double) -> String {
        if val < 18.5 { return "Bajo Peso" }
        if val < 24.9 { return "Normal" }
        if val < 29.9 { return "Sobrepeso" }
        return "Obesidad"
    }
    
    private func biometricCard(title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundColor(AppTheme.textSecondary)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(AppTheme.exerciseGreen)
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
    }
    
    private var weightLogListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historial de Pesajes")
                .font(.headline.weight(.bold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal)
            
            let reversed = appState.userProfile.weightHistory.sorted { $0.date > $1.date }
            
            ForEach(0..<reversed.count, id: \.self) { idx in
                let current = reversed[idx]
                let previous = idx + 1 < reversed.count ? reversed[idx + 1] : nil
                let delta = previous != nil ? current.weightKg - previous!.weightKg : 0.0
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(current.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(relativeDateString(for: current.date))
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    if previous != nil && abs(delta) > 0.01 {
                        Text(String(format: "%@%.1f kg", delta > 0 ? "+" : "", delta))
                            .font(.caption.weight(.bold))
                            .foregroundColor(delta <= 0 ? AppTheme.exerciseGreen : AppTheme.moveRed)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((delta <= 0 ? AppTheme.exerciseGreen : AppTheme.moveRed).opacity(0.15))
                            .cornerRadius(6)
                    }
                    
                    Text(UnitFormatter.shared.formatWeight(current.weightKg, system: appState.userProfile.unitSystem))
                        .font(.headline.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(minWidth: 80, alignment: .trailing)
                }
                .padding()
                .background(AppTheme.surface)
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
    }
    
    private func relativeDateString(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Hoy" }
        if calendar.isDateInYesterday(date) { return "Ayer" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date).capitalized
    }
}
