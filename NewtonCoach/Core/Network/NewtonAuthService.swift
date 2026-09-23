import Foundation

public struct NewtonLoginRequest: Codable {
    public let username: String
    public let password: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct NewtonLoginResponse: Codable {
    public let ok: Bool
    public let username: String?
    public let email: String?
    public let email_verified: Bool?
    public let api_key: String?
    public let credits_left: Double?
    public let rpm_limit: Int?
    public let message: String?
}

public struct NewtonUserProfileResponse: Codable {
    public let ok: Bool
    public let username: String?
    public let email: String?
    public let email_verified: Bool?
    public let tier: NewtonTierInfo?
    public let credits: NewtonCreditsInfo?
}

public struct NewtonTierInfo: Codable {
    public let id: String?
    public let name: String?
    public let price_mxn: Double?
}

public struct NewtonCreditsInfo: Codable {
    public let total: Double?
    public let used: Double?
    public let remaining: Double?
}

extension NewtonAPIClient {
    /// Autentica al usuario usando el endpoint oficial POST /auth/login de Newton Labs
    public func login(username: String, password: String) async throws -> NewtonLoginResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = NewtonLoginRequest(username: username, password: password)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Credenciales inválidas"
            throw NSError(domain: "NewtonCoach", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        let loginResponse = try JSONDecoder().decode(NewtonLoginResponse.self, from: data)
        
        // Si el login fue exitoso y nos entregó el api_key, lo persistimos en el Keychain
        if let key = loginResponse.api_key {
            _ = KeychainManager.shared.saveApiKey(key)
        }
        
        return loginResponse
    }
    
    /// Obtiene información de cuota y perfil del usuario autenticado vía GET /auth/me
    public func getProfileMe() async throws -> NewtonUserProfileResponse {
        guard let apiKey = KeychainManager.shared.getApiKey(), !apiKey.isEmpty else {
            throw NSError(domain: "NewtonCoach", code: 401, userInfo: [NSLocalizedDescriptionKey: "No autenticado"])
        }
        
        guard let url = URL(string: "\(baseURL)/auth/me") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "NewtonCoach", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Error consultando cuota"])
        }
        
        return try JSONDecoder().decode(NewtonUserProfileResponse.self, from: data)
    }
}
