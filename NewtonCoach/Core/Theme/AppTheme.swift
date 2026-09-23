import SwiftUI

public enum AppTheme {
    // Fondos Apple Fitness (True Black & Dark Zinc)
    public static let background = Color.black
    public static let surface = Color(hex: "121214")
    public static let surfaceElevated = Color(hex: "1C1C1E")
    public static let surfaceBorder = Color(hex: "2C2C2E")
    
    // Acentos Oficiales Apple Activity & Fitness
    public static let moveRed = Color(hex: "FA114F")        // Anillo de movimiento / Calorías / Proteína
    public static let exerciseGreen = Color(hex: "A1FF00")  // Anillo de ejercicio / Lima deportivo
    public static let standCyan = Color(hex: "00F0FF")      // Anillo de pie / Hidratación / Carbos
    public static let awardGold = Color(hex: "FFD60A")      // Trofeos / Cumpleaños / Grasas
    
    // Alias para retrocompatibilidad
    public static let primaryNeon = exerciseGreen
    public static let secondaryAccent = Color(hex: "7000FF")
    
    // Tipografía
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "8E8E93")
    public static let textTertiary = Color(hex: "48484A")
    
    // Tarjetas de Workout (Verde Oliva Oscuro Apple)
    public static let workoutCardBg = Color(hex: "151C0A")
    public static let workoutButtonBg = Color(hex: "222C10")
    
    public static let success = Color(hex: "30D158")
    public static let danger = Color(hex: "FF453A")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
