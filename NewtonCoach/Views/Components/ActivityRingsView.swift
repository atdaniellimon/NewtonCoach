import SwiftUI

public struct ActivityRingsView: View {
    public let caloriesProgress: Double // 0.0 a 1.0 (Anillo Rojo Move)
    public let weightProgress: Double   // 0.0 a 1.0 (Anillo Verde Exercise)
    public let proteinProgress: Double  // 0.0 a 1.0 (Anillo Cian Stand)
    
    public init(caloriesProgress: Double, weightProgress: Double, proteinProgress: Double) {
        self.caloriesProgress = caloriesProgress
        self.weightProgress = weightProgress
        self.proteinProgress = proteinProgress
    }
    
    public var body: some View {
        ZStack {
            // Anillo Exterior (Move / Calorías)
            RingCircle(
                progress: caloriesProgress,
                color: AppTheme.moveRed,
                lineWidth: 16,
                radius: 65
            )
            
            // Anillo Medio (Exercise / Progreso de Peso)
            RingCircle(
                progress: weightProgress,
                color: AppTheme.exerciseGreen,
                lineWidth: 16,
                radius: 46
            )
            
            // Anillo Interior (Stand / Proteínas)
            RingCircle(
                progress: proteinProgress,
                color: AppTheme.standCyan,
                lineWidth: 16,
                radius: 27
            )
        }
        .frame(width: 150, height: 150)
    }
}

private struct RingCircle: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let radius: CGFloat
    
    var body: some View {
        ZStack {
            // Fondo oscuro del anillo
            Circle()
                .stroke(color.opacity(0.2), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)
            
            // Trazo coloreado con progreso
            Circle()
                .trim(from: 0, to: CGFloat(min(1.0, max(0.02, progress))))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
        }
    }
}
