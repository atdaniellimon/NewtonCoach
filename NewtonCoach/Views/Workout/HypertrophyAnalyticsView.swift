import SwiftUI

public struct MuscleVolumeLandmark: Identifiable {
    public let id = UUID()
    public let muscleGroup: String
    public let completedSets: Int
    public let mev: Int // Minimum Effective Volume
    public let mav: ClosedRange<Int> // Maximum Adaptive Volume
    public let mrv: Int // Maximum Recoverable Volume
    
    public var status: VolumeStatus {
        if completedSets < mev { return .underTrained }
        if mav.contains(completedSets) { return .optimal }
        if completedSets > mrv { return .overTrained }
        return .productive
    }
}

public enum VolumeStatus: String {
    case underTrained = "Por debajo de MEV"
    case productive = "Crecimiento Mínimo"
    case optimal = "Rango Óptimo (MAV)"
    case overTrained = "Riesgo de Sobreentreno (MRV)"
    
    public var color: Color {
        switch self {
        case .underTrained: return AppTheme.textSecondary
        case .productive: return AppTheme.standCyan
        case .optimal: return AppTheme.exerciseGreen
        case .overTrained: return AppTheme.moveRed
        }
    }
}

public struct HypertrophyAnalyticsView: View {
    @EnvironmentObject var appState: AppState
    
    let muscleLandmarks: [MuscleVolumeLandmark] = [
        MuscleVolumeLandmark(muscleGroup: "Pecho (Pectoral)", completedSets: 14, mev: 10, mav: 12...20, mrv: 22),
        MuscleVolumeLandmark(muscleGroup: "Espalda (Dorsal & Trapecio)", completedSets: 16, mev: 12, mav: 14...22, mrv: 25),
        MuscleVolumeLandmark(muscleGroup: "Cuádriceps", completedSets: 12, mev: 8, mav: 12...18, mrv: 20),
        MuscleVolumeLandmark(muscleGroup: "Isquiotibiales & Glúteo", completedSets: 10, mev: 6, mav: 10...16, mrv: 18),
        MuscleVolumeLandmark(muscleGroup: "Hombro Lateral & Posterior", completedSets: 18, mev: 12, mav: 16...26, mrv: 30),
        MuscleVolumeLandmark(muscleGroup: "Bíceps & Tríceps", completedSets: 12, mev: 8, mav: 10...18, mrv: 20),
        MuscleVolumeLandmark(muscleGroup: "Gemelos & Abdomen", completedSets: 8, mev: 6, mav: 8...16, mrv: 20)
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Científico (RP Mike Israetel)
                    scienceHeaderHero
                    
                    // Explicación de Hitos (MEV, MAV, MRV)
                    landmarksLegendCard
                    
                    // Lista de Músculos con sus Hitos de Series Semanales
                    ForEach(muscleLandmarks) { item in
                        muscleLandmarkCard(item)
                    }
                    
                    // Rangos de Repeticiones y Sobrecarga Progresiva
                    repRangesCard
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Volumen & Hipertrofia")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var scienceHeaderHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Ciencia de Hipertrofia (RP)")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(AppTheme.exerciseGreen)
                Spacer()
                Image(systemName: "flame.fill")
                    .foregroundColor(AppTheme.exerciseGreen)
            }
            
            Text("Hitos de Volumen Semanal")
                .font(.title2.weight(.bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text("Solo se contabilizan series efectivas tomadas con RIR 0 a 3 (máximo a 3 repeticiones del fallo muscular).")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(18)
        .background(AppTheme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
    }
    
    private var landmarksLegendCard: some View {
        HStack(spacing: 8) {
            legendPill("MEV: Mínimo", color: AppTheme.standCyan)
            legendPill("MAV: Óptimo", color: AppTheme.exerciseGreen)
            legendPill("MRV: Límite", color: AppTheme.moveRed)
        }
    }
    
    private func legendPill(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .cornerRadius(10)
    }
    
    private func muscleLandmarkCard(_ item: MuscleVolumeLandmark) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.muscleGroup)
                    .font(.headline.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(item.completedSets) series")
                    .font(.subheadline.weight(.heavy))
                    .foregroundColor(item.status.color)
            }
            
            HStack {
                Text(item.status.rawValue)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(item.status.color)
                Spacer()
                Text("MAV: \(item.mav.lowerBound)-\(item.mav.upperBound) | MRV: \(item.mrv)+")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            // Barra de Progreso Multi-Hito
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.surfaceElevated)
                        .frame(height: 10)
                    
                    let maxScale = Double(item.mrv + 4)
                    let width = geo.size.width * CGFloat(min(1.0, Double(item.completedSets) / maxScale))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(item.status.color)
                        .frame(width: max(12, width), height: 10)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(AppTheme.surface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
    }
    
    private var repRangesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rangos de Repeticiones Óptimos")
                .font(.headline.weight(.bold))
                .foregroundColor(AppTheme.textPrimary)
            
            repRangeRow("Compuestos Pesados (Banca, Sentadilla, Peso Muerto)", "5 - 8 Reps", "Tensión mecánica máxima")
            repRangeRow("Hipertrofia Pura (Jalones, Remos, Extensiones)", "10 - 15 Reps", "Estímulo / Fatiga óptimo")
            repRangeRow("Aislamiento & Bombeo (Elevaciones, Brazos, Gemelos)", "15 - 25 Reps", "Estrés metabólico y bombeo")
        }
        .padding(18)
        .background(AppTheme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
    }
    
    private func repRangeRow(_ title: String, _ reps: String, _ desc: String) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(desc)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Text(reps)
                .font(.footnote.weight(.bold))
                .foregroundColor(AppTheme.exerciseGreen)
        }
        .padding(.vertical, 4)
    }
}
