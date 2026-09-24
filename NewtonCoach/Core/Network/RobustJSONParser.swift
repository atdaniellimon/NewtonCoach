import Foundation

/// Parser y sanitizador ultra-robusto diseñado para respuestas de modelos LLM (Newton Labs / Singularity / Quantum)
/// Elimina bloques de razonamiento (<thinking>), markdown, trailing commas y decodifica números tolerantes.
public final class RobustJSONParser {
    public static let shared = RobustJSONParser()
    
    private init() {}
    
    /// Limpia texto crudo de LLM eliminando bloques de thinking, markdown y texto circundante
    public func sanitizeJSONString(_ raw: String) -> String {
        var text = raw
        
        // 1. Eliminar cualquier bloque <thinking>...</thinking> o <thought>...</thought> (incluso multilinea)
        let thinkingRegex = try? NSRegularExpression(pattern: "(?s)<(thinking|thought)>.*?</\\1>", options: [])
        if let regex = thinkingRegex {
            let range = NSRange(location: 0, length: text.utf16.count)
            text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        }
        
        // Limpieza si quedaron tags de thinking incompletos o huérfanos
        if let closeTag = text.range(of: "</thinking>") {
            text = String(text[closeTag.upperBound...])
        }
        text = text.replacingOccurrences(of: "<thinking>", with: "")
        text = text.replacingOccurrences(of: "</thinking>", with: "")
        text = text.replacingOccurrences(of: "<thought>", with: "")
        text = text.replacingOccurrences(of: "</thought>", with: "")
        
        // 2. Extraer bloques entre ```json ... ``` si existen
        let codeBlockRegex = try? NSRegularExpression(pattern: "(?s)```(?:json)?\\s*([\\{\\[].*?[\\}\\]])\\s*```", options: [])
        if let match = codeBlockRegex?.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let range = Range(match.range(at: 1), in: text) {
            text = String(text[range])
        }
        
        // 3. Localizar el primer '{' o '[' y el último '}' o ']'
        let firstBrace = text.firstIndex(where: { $0 == "{" || $0 == "[" })
        let lastBrace = text.lastIndex(where: { $0 == "}" || $0 == "]" })
        
        if let start = firstBrace, let end = lastBrace, start < end {
            text = String(text[start...end])
        }
        
        // 4. Limpiar trailing commas que invalidan JSON en Swift (ej: ", }" o ", ]")
        let trailingCommaRegex = try? NSRegularExpression(pattern: ",\\s*([\\}\\]])", options: [])
        if let regex = trailingCommaRegex {
            let range = NSRange(location: 0, length: text.utf16.count)
            text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1")
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Decodifica de forma segura un tipo Codable a partir de texto devuelto por Newton LLM
    public func decode<T: Decodable>(_ type: T.Type, from rawText: String) throws -> T {
        let cleanJson = sanitizeJSONString(rawText)
        guard let data = cleanJson.data(using: .utf8) else {
            throw NSError(
                domain: "NewtonCoach.RobustJSONParser",
                code: 422,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo convertir la respuesta en UTF-8."]
            )
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        } catch {
            // Intentar una segunda pasada si falló: reemplazar valores con unidades (ej: "500 kcal" -> 500)
            let numericSanitized = sanitizeNumericStrings(cleanJson)
            if let secondData = numericSanitized.data(using: .utf8),
               let secondTry = try? decoder.decode(type, from: secondData) {
                return secondTry
            }
            throw error
        }
    }
    
    /// Transforma "500 kcal", "45g", "30.5 kg" a números planos para evitar fallos de decodificación
    private func sanitizeNumericStrings(_ json: String) -> String {
        var result = json
        // Reemplazar patrones como "calories": "500 kcal" o "protein": "45 g"
        let pattern = "(\"(?:calories|protein|carbs|fat|weight|reps|rir|height)\"\\s*:\\s*)\"([0-9]+(?:\\.[0-9]+)?)\\s*(?:kcal|cal|g|kg|lbs|reps)?\""
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: result.utf16.count)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1$2")
        }
        return result
    }
}
