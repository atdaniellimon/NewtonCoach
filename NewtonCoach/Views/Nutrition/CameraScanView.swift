import SwiftUI
import PhotosUI

public struct CameraScanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var scanMode: Int = 0 // 0 = Foto, 1 = Texto
    
    // Modo Foto
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    // Modo Texto
    @State private var textDescription: String = ""
    
    // Estado común
    @State private var isAnalyzing = false
    @State private var analysisResult: MealItem?
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("MacroLens AI")
                        .font(.title2.bold())
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Picker("Método", selection: $scanMode) {
                        Text("Foto").tag(0)
                        Text("Describir con Texto").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    
                    if scanMode == 0 {
                        photoScannerSection
                    } else {
                        textScannerSection
                    }
                    
                    if isAnalyzing {
                        ProgressView("Newton AI calculando macros milimétricos...")
                            .tint(AppTheme.exerciseGreen)
                            .padding()
                    }
                    
                    if let result = analysisResult {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text(result.name)
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Text("\(Int(result.calories)) KCAL")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(AppTheme.exerciseGreen)
                            }
                            
                            Text(result.description)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            HStack(spacing: 16) {
                                macroBadge(name: "Proteína", value: "\(Int(result.protein))g", color: AppTheme.moveRed)
                                macroBadge(name: "Carbos", value: "\(Int(result.carbs))g", color: AppTheme.standCyan)
                                macroBadge(name: "Grasas", value: "\(Int(result.fat))g", color: AppTheme.awardGold)
                            }
                            
                            Button(action: addFoodToLog) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Añadir a mi Registro de Hoy")
                                        .font(.subheadline.bold())
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.exerciseGreen)
                                .cornerRadius(14)
                            }
                        }
                        .padding(18)
                        .background(AppTheme.surface)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(AppTheme.danger)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
    
    private var photoScannerSection: some View {
        VStack(spacing: 16) {
            Text("Sube o toma una foto de tu comida para calcular calorías y macronutrientes al instante.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.exerciseGreen, lineWidth: 2))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.exerciseGreen)
                    Text("Seleccionar Foto de Comida")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(AppTheme.surface)
                .cornerRadius(16)
            }
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Elegir de Galería / Cámara", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.exerciseGreen)
                    .cornerRadius(14)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        analyzePhoto(uiImage)
                    }
                }
            }
        }
    }
    
    private var textScannerSection: some View {
        VStack(spacing: 16) {
            Text("Describe en tus palabras lo que comiste (porciones, ingredientes o platos) y la IA calculará tus macros.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            TextField("Ej: 2 huevos revueltos con 2 tortillas de maíz, medio aguacate y café negro...", text: $textDescription, axis: .vertical)
                .lineLimit(4...6)
                .padding(14)
                .background(AppTheme.surface)
                .cornerRadius(16)
                .foregroundColor(AppTheme.textPrimary)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
            
            Button(action: analyzeText) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Calcular con Newton AI")
                        .font(.headline.weight(.bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.exerciseGreen)
                .cornerRadius(14)
            }
            .disabled(textDescription.trimmingCharacters(in: .whitespaces).isEmpty || isAnalyzing)
            .opacity(textDescription.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
        }
    }
    
    private func macroBadge(name: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)
            Text(name)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppTheme.surfaceElevated)
        .cornerRadius(10)
    }
    
    private func addFoodToLog() {
        guard let item = analysisResult else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        appState.logFood(
            name: item.name,
            description: item.description,
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat
        )
        dismiss()
    }
    
    private func analyzePhoto(_ image: UIImage) {
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil
        Task { @MainActor in
            do {
                let result = try await NewtonAIService.shared.analyzeMealPhoto(image: image, currentProfile: appState.userProfile)
                self.analysisResult = result
                self.isAnalyzing = false
                AchievementManager.shared.evaluateAchievements(profile: appState.userProfile, scansCount: 1)
            } catch {
                self.errorMessage = error.localizedDescription
                self.isAnalyzing = false
            }
        }
    }
    
    private func analyzeText() {
        let trimmed = textDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil
        Task { @MainActor in
            do {
                let result = try await NewtonAIService.shared.analyzeMealDescription(text: trimmed, currentProfile: appState.userProfile)
                self.analysisResult = result
                self.isAnalyzing = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isAnalyzing = false
            }
        }
    }
}

