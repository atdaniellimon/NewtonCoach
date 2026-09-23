import Foundation
import UIKit

public struct NewtonAttachment: Codable {
    public let type: String // "image"
    public let data: String // Data URI o base64
    public let name: String?
    
    public init(type: String = "image", data: String, name: String? = nil) {
        self.type = type
        self.data = data
        self.name = name
    }
}

public struct ChatHistoryMessage: Codable {
    public let role: String // "user" o "assistant"
    public let content: String
    
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct NewtonChatRequest: Codable {
    public let prompt: String
    public let model: String
    public let stream: Bool
    public let system: String?
    public let history: [ChatHistoryMessage]?
    public let attachments: [NewtonAttachment]?
    
    public init(
        prompt: String,
        model: String = "Singularity",
        stream: Bool = false,
        system: String? = nil,
        history: [ChatHistoryMessage]? = nil,
        attachments: [NewtonAttachment]? = nil
    ) {
        self.prompt = prompt
        self.model = model
        self.stream = stream
        self.system = system
        self.history = history
        self.attachments = attachments
    }
}

public struct NewtonChatResponse: Codable {
    public let reply: String
    public let thinking: String?
    public let credits_left: Double?
}

public final class NewtonAPIClient {
    public static let shared = NewtonAPIClient()
    public let baseURL = "https://api.newton.daniellimon.uk"
    
    private init() {}
    
    /// Envía solicitud de chat con Server-Sent Events (SSE) streaming
    public func streamChat(
        request: NewtonChatRequest,
        onDelta: @escaping (String) -> Void,
        onComplete: @escaping (Result<String, Error>) -> Void
    ) {
        guard let apiKey = KeychainManager.shared.getApiKey(), !apiKey.isEmpty else {
            onComplete(.failure(NSError(domain: "NewtonCoach", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key de Newton no configurada"])))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/nwtn/chat?stream=true") else { return }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            onComplete(.failure(error))
            return
        }
        
        let session = URLSession(configuration: .default, delegate: SSEStreamDelegate(onDelta: onDelta, onComplete: onComplete), delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: urlRequest)
        task.resume()
    }
    
    /// Envía solicitud estándar (sin streaming, por ejemplo para estructurar JSON de menús)
    public func sendChatSync(request: NewtonChatRequest) async throws -> NewtonChatResponse {
        guard let apiKey = KeychainManager.shared.getApiKey(), !apiKey.isEmpty else {
            throw NSError(domain: "NewtonCoach", code: 401, userInfo: [NSLocalizedDescriptionKey: "Por favor configura tu API Key de Newton en Ajustes"])
        }
        
        guard let url = URL(string: "\(baseURL)/nwtn/chat") else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Error desconocido en el servidor de Newton"
            throw NSError(domain: "NewtonCoach", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        return try JSONDecoder().decode(NewtonChatResponse.self, from: data)
    }
}

// Delegado para procesar chunks de Server-Sent Events (SSE)
private final class SSEStreamDelegate: NSObject, URLSessionDataDelegate {
    private let onDelta: (String) -> Void
    private let onComplete: (Result<String, Error>) -> Void
    private var accumulatedReply = ""
    private var buffer = ""
    
    init(onDelta: @escaping (String) -> Void, onComplete: @escaping (Result<String, Error>) -> Void) {
        self.onDelta = onDelta
        self.onComplete = onComplete
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        buffer += chunk
        
        let lines = buffer.components(separatedBy: "\n")
        // Dejar última línea en el buffer si está incompleta
        buffer = lines.last ?? ""
        
        for line in lines.dropLast() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("data: ") {
                let payload = String(trimmed.dropFirst(6))
                if payload == "[DONE]" {
                    continue
                }
                
                if let jsonData = payload.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    if let delta = json["delta"] as? String {
                        accumulatedReply += delta
                        onDelta(delta)
                    } else if let reply = json["reply"] as? String, (json["done"] as? Bool) == true {
                        accumulatedReply = reply
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onComplete(.failure(error))
        } else {
            onComplete(.success(accumulatedReply))
        }
    }
}
