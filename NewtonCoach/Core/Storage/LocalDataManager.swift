import Foundation

/// Gestor de persistencia física local atómica en el sandbox de iOS
/// Guarda en Application Support / Documents garantizando que ningún dato se resetee al cerrar la app
public final class LocalDataManager {
    public static let shared = LocalDataManager()
    
    private let fileManager = FileManager.default
    private let appSupportURL: URL
    private let profileFileName = "user_profile_v2.json"
    private let chatSessionsFileName = "coach_chat_sessions.json"
    private let workoutHistoryFileName = "workout_history.json"
    
    private init() {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = urls.first ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let newtonDir = dir.appendingPathComponent("NewtonCoach", isDirectory: true)
        
        if !fileManager.fileExists(atPath: newtonDir.path) {
            try? fileManager.createDirectory(at: newtonDir, withIntermediateDirectories: true)
        }
        self.appSupportURL = newtonDir
    }
    
    // MARK: - Perfil de Usuario
    public func saveUserProfile(_ profile: UserProfile) {
        saveObject(profile, to: profileFileName)
    }
    
    public func loadUserProfile() -> UserProfile? {
        return loadObject(UserProfile.self, from: profileFileName)
    }
    
    // MARK: - Historial de Sesiones de Chat con Coach
    public func saveChatSessions(_ sessions: [CoachChatSession]) {
        saveObject(sessions, to: chatSessionsFileName)
    }
    
    public func loadChatSessions() -> [CoachChatSession] {
        return loadObject([CoachChatSession].self, from: chatSessionsFileName) ?? []
    }
    
    // MARK: - Historial de Entrenamientos y Récords
    public func saveWorkoutHistory(_ history: [CompletedWorkoutSession]) {
        saveObject(history, to: workoutHistoryFileName)
    }
    
    public func loadWorkoutHistory() -> [CompletedWorkoutSession] {
        return loadObject([CompletedWorkoutSession].self, from: workoutHistoryFileName) ?? []
    }
    
    // MARK: - Operaciones Genéricas Atómicas
    private func saveObject<T: Encodable>(_ object: T, to fileName: String) {
        let fileURL = appSupportURL.appendingPathComponent(fileName)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(object)
            try data.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Error guardando \(fileName): \(error)")
        }
    }
    
    private func loadObject<T: Decodable>(_ type: T.Type, from fileName: String) -> T? {
        let fileURL = appSupportURL.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            print("Error decodificando \(fileName): \(error)")
            return nil
        }
    }
}
