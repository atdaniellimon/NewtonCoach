import Foundation
import UIKit

public final class NewtonAIService {
    public static let shared = NewtonAIService()
    
    private init() {}
    
    /// Genera un menú personalizado para el día basado en el perfil y las calorías objetivo
    public func generateDailyMenu(for profile: UserProfile, targets: NutritionTargets) async throws -> MealPlan {
        let systemPrompt = """
        Eres Newton Nutritionist, un nutriólogo deportivo y científico experto en composición corporal.
        Tu tarea es generar un plan de menú estructurado y apetitoso exactamente para el día de hoy, cuadrando milimétricamente las calorías y macronutrientes solicitados.
        
        IMPORTANTE: Devuelve ÚNICAMENTE un objeto JSON válido con la siguiente estructura, sin texto adicional antes o después:
        {
          "title": "Plan de Comidas de Alto Rendimiento",
          "meals": [
            {
              "category": "Desayuno",
              "name": "Nombre del plato",
              "description": "Ingredientes y cantidades exactas (ej: 3 huevos, 50g avena, frutos rojos)",
              "calories": 500,
              "protein": 35,
              "carbs": 50,
              "fat": 15
            },
            {
              "category": "Almuerzo",
              "name": "...",
              "description": "...",
              "calories": 700,
              "protein": 55,
              "carbs": 70,
              "fat": 18
            },
            {
              "category": "Merienda",
              "name": "...",
              "description": "...",
              "calories": 300,
              "protein": 25,
              "carbs": 30,
              "fat": 6
            },
            {
              "category": "Cena",
              "name": "...",
              "description": "...",
              "calories": 550,
              "protein": 45,
              "carbs": 40,
              "fat": 14
            }
          ]
        }
        """
        
        let prompt = """
        Genera el menú completo para:
        - Usuario: \(profile.name)
        - Edad: \(profile.age) años
        - Peso actual: \(String(format: "%.1f", profile.currentWeightKg)) kg -> Meta: \(String(format: "%.1f", profile.targetWeightKg)) kg
        - Meta Calórica Diaria: \(Int(targets.targetCalories)) kcal
        - Proteínas: \(Int(targets.proteinGrams))g
        - Carbohidratos: \(Int(targets.carbGrams))g
        - Grasas: \(Int(targets.fatGrams))g
        Asegúrate de que la suma de las comidas se aproxime lo más posible a estos números.
        """
        
        let request = NewtonChatRequest(
            prompt: prompt,
            model: "Singularity",
            stream: false,
            system: systemPrompt
        )
        
        let response = try await NewtonAPIClient.shared.sendChatSync(request: request)
        
        // Parsear el JSON recibido
        var rawJson = response.reply
        if let start = rawJson.range(of: "{"), let end = rawJson.range(of: "}", options: .backwards) {
            rawJson = String(rawJson[start.lowerBound...end.upperBound])
        }
        
        guard let jsonData = rawJson.data(using: .utf8) else {
            throw NSError(domain: "NewtonCoach", code: 422, userInfo: [NSLocalizedDescriptionKey: "No se pudo interpretar el formato del menú."])
        }
        
        struct JsonMenu: Codable {
            let title: String?
            let meals: [JsonMeal]
        }
        struct JsonMeal: Codable {
            let category: String
            let name: String
            let description: String
            let calories: Double
            let protein: Double
            let carbs: Double
            let fat: Double
        }
        
        let decoded = try JSONDecoder().decode(JsonMenu.self, from: jsonData)
        
        let mealItems = decoded.meals.map { m in
            MealItem(
                category: m.category,
                name: m.name,
                description: m.description,
                calories: m.calories,
                protein: m.protein,
                carbs: m.carbs,
                fat: m.fat
            )
        }
        
        let totalCals = mealItems.reduce(0) { $0 + $1.calories }
        let totalProt = mealItems.reduce(0) { $0 + $1.protein }
        let totalCarbs = mealItems.reduce(0) { $0 + $1.carbs }
        let totalFat = mealItems.reduce(0) { $0 + $1.fat }
        
        return MealPlan(
            title: decoded.title ?? "Menú Recomendado por Newton AI",
            totalCalories: totalCals,
            totalProtein: totalProt,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            meals: mealItems
        )
    }
    
    /// Analiza una foto de comida usando la visión multimodal de Newton Labs
    public func analyzeMealPhoto(image: UIImage, currentProfile: UserProfile) async throws -> MealItem {
        guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "NewtonCoach", code: 400, userInfo: [NSLocalizedDescriptionKey: "No se pudo procesar la imagen."])
        }
        
        let base64String = "data:image/jpeg;base64," + jpegData.base64EncodedString()
        let attachment = NewtonAttachment(type: "image", data: base64String, name: "plato.jpg")
        
        let systemPrompt = """
        Eres MacroLens AI, visión artificial especializada en nutrición deportiva.
        Analiza detalladamente la foto del plato o alimentos visibles y estima con la mayor precisión posible sus macronutrientes y calorías totales.
        
        Devuelve ÚNICAMENTE un JSON con este formato:
        {
          "name": "Nombre representativo del plato (ej: Pechuga a la plancha con arroz y aguacate)",
          "description": "Desglose visual estimado de cada componente y porción aproximada en gramos",
          "calories": 620,
          "protein": 48,
          "carbs": 60,
          "fat": 16
        }
        """
        
        let request = NewtonChatRequest(
            prompt: "Analiza el contenido nutricional de este plato, estimando calorías y macronutrientes.",
            model: "Singularity",
            stream: false,
            system: systemPrompt,
            attachments: [attachment]
        )
        
        let response = try await NewtonAPIClient.shared.sendChatSync(request: request)
        
        var rawJson = response.reply
        if let start = rawJson.range(of: "{"), let end = rawJson.range(of: "}", options: .backwards) {
            rawJson = String(rawJson[start.lowerBound...end.upperBound])
        }
        
        guard let jsonData = rawJson.data(using: .utf8) else {
            throw NSError(domain: "NewtonCoach", code: 422, userInfo: [NSLocalizedDescriptionKey: "Error leyendo respuesta de visión"])
        }
        
        struct ScannedDish: Codable {
            let name: String
            let description: String
            let calories: Double
            let protein: Double
            let carbs: Double
            let fat: Double
        }
        
        let scanned = try JSONDecoder().decode(ScannedDish.self, from: jsonData)
        
        return MealItem(
            category: "Comida Escaneada",
            name: scanned.name,
            description: scanned.description,
            calories: scanned.calories,
            protein: scanned.protein,
            carbs: scanned.carbs,
            fat: scanned.fat
        )
    }
    
    /// Analiza una descripción escrita en lenguaje natural de lo que el usuario comió
    public func analyzeMealDescription(text: String, currentProfile: UserProfile) async throws -> MealItem {
        let systemPrompt = """
        Eres Newton Nutritionist y calculador de macronutrientes.
        El usuario te describe en lenguaje natural lo que acaba de comer.
        Tu tarea es estimar los ingredientes, gramos aproximados, calorías totales y macronutrientes (proteína, carbohidratos, grasas).
        
        Devuelve ÚNICAMENTE un JSON válido con este formato:
        {
          "name": "Nombre conciso del plato o alimentos consumidos",
          "description": "Desglose estimado con gramos o porciones (ej: 2 huevos revueltos, 2 rebanadas pan integral)",
          "calories": 420,
          "protein": 24,
          "carbs": 38,
          "fat": 16
        }
        """
        
        let request = NewtonChatRequest(
            prompt: "He comido esto: \"\(text)\". Calcula y desglosa sus calorías y macronutrientes.",
            model: "Singularity",
            stream: false,
            system: systemPrompt
        )
        
        let response = try await NewtonAPIClient.shared.sendChatSync(request: request)
        
        var rawJson = response.reply
        // Limpiar bloques de thinking si vinieran en la respuesta
        if let thinkingEnd = rawJson.range(of: "</thinking>") {
            rawJson = String(rawJson[thinkingEnd.upperBound...])
        }
        
        if let start = rawJson.range(of: "{"), let end = rawJson.range(of: "}", options: .backwards) {
            rawJson = String(rawJson[start.lowerBound...end.upperBound])
        }
        
        guard let jsonData = rawJson.data(using: .utf8) else {
            throw NSError(domain: "NewtonCoach", code: 422, userInfo: [NSLocalizedDescriptionKey: "Error procesando el análisis de tu comida."])
        }
        
        struct ScannedDish: Codable {
            let name: String
            let description: String
            let calories: Double
            let protein: Double
            let carbs: Double
            let fat: Double
        }
        
        let scanned = try JSONDecoder().decode(ScannedDish.self, from: jsonData)
        
        return MealItem(
            category: "Comida Registrada",
            name: scanned.name,
            description: scanned.description,
            calories: scanned.calories,
            protein: scanned.protein,
            carbs: scanned.carbs,
            fat: scanned.fat
        )
    }
}

