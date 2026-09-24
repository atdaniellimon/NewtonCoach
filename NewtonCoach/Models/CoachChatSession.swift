import Foundation

/// Mensaje individual dentro de una sesión de chat con el coach
public struct CoachChatMessage: Codable, Identifiable {
    public var id: UUID
    public var role: String
    public var content: String
    public var timestamp: Date
    
    public init(id: UUID = UUID(), role: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

/// Modelo para una conversación completa guardada con el Newton Coach
public struct CoachChatSession: Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var createdAt: Date
    public var mode: CoachMode
    public var messages: [CoachChatMessage]
    
    public init(
        id: UUID = UUID(),
        title: String = "Nueva Consulta",
        createdAt: Date = Date(),
        mode: CoachMode = .strength,
        messages: [CoachChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.mode = mode
        self.messages = messages
    }
}

/// Modos especializados de Newton Coach
public enum CoachMode: String, Codable, CaseIterable, Identifiable {
    case strength = "Biomecánica & Fuerza"
    case nutrition = "Nutrición de Precisión"
    case recovery = "Recuperación & SNC"
    case formCheck = "Form Check Técnico"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .nutrition: return "fork.knife.circle.fill"
        case .recovery: return "bed.double.circle.fill"
        case .formCheck: return "camera.metering.matrix"
        }
    }
    
    public var welcomeMessage: String {
        switch self {
        case .strength:
            return "¡Hola! Soy tu Newton Coach de Biomecánica y Fuerza. Dime qué ejercicio quieres optimizar, calcular tu sobrecarga progresiva o qué máquina ocupada necesitas sustituir con el mismo perfil de resistencia."
        case .nutrition:
            return "Newton Nutritionist en línea. Dime qué te apetece comer, cuánto te falta para tus macros de hoy o qué sustitución saludable buscas y te daré los gramos exactos."
        case .recovery:
            return "Especialista en Fatiga y Recuperación del SNC. Cuéntame cómo sentiste tu último entreno, si tienes molestias articulares o fatiga sistémica y evaluaremos si necesitas una semana de descarga (deload)."
        case .formCheck:
            return "Bienvenido a Form Check AI. Sube una foto o video corto de tu sentadilla, banca o peso muerto y analizaré el recorrido de la barra, ángulos articulares y seguridad espinal."
        }
    }
}
