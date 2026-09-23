import Foundation

public enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case metric = "Métrico (kg / cm)"
    case imperial = "Imperial (lbs / ft-in)"
    
    public var id: String { rawValue }
}

public struct UnitFormatter {
    public static let shared = UnitFormatter()
    
    private init() {}
    
    // KG <-> LBS
    public func formatWeight(_ kg: Double, system: UnitSystem, showUnit: Bool = true) -> String {
        if system == .imperial {
            let lbs = kg * 2.20462
            let formatted = String(format: "%.1f", lbs)
            return showUnit ? "\(formatted) LBS" : formatted
        } else {
            let formatted = String(format: "%.1f", kg)
            return showUnit ? "\(formatted) KG" : formatted
        }
    }
    
    public func parseWeightToKg(input: String, system: UnitSystem) -> Double? {
        let clean = input.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let val = Double(clean) else { return nil }
        if system == .imperial {
            return val / 2.20462
        }
        return val
    }
    
    // CM <-> FT/IN
    public func formatHeight(_ cm: Double, system: UnitSystem) -> String {
        if system == .imperial {
            let totalInches = cm / 2.54
            let feet = Int(totalInches) / 12
            let inches = Int(totalInches) % 12
            return "\(feet)' \(inches)\""
        } else {
            return "\(Int(cm)) cm"
        }
    }
}
