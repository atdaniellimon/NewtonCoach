import SwiftUI
import PhotosUI

public struct CameraScanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResult: MealItem?
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("MacroLens Vision")
                        .font(.title2.bold())
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Sube o toma una foto de tu comida para calcular calorías y macronutrientes al instante mediante la IA de Newton.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryNeon, lineWidth: 2))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.primaryNeon)
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
                            .background(AppTheme.primaryNeon)
                            .cornerRadius(12)
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                analyze(uiImage)
                            }
                        }
                    }
                    
                    if isAnalyzing {
                        ProgressView("Newton AI analizando volumen y macros...")
                            .tint(AppTheme.primaryNeon)
                            .padding()
                    }
                    
                    if let result = analysisResult {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(result.name)
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            Text(result.description)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            HStack(spacing: 20) {
                                macroBadge(name: "Calorías", value: "\(Int(result.calories)) kcal", color: .yellow)
                                macroBadge(name: "Proteína", value: "\(Int(result.protein))g", color: .red)
                                macroBadge(name: "Carbos", value: "\(Int(result.carbs))g", color: .orange)
                                macroBadge(name: "Grasas", value: "\(Int(result.fat))g", color: .blue)
                            }
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Añadir a mi Registro")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppTheme.primaryNeon)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(AppTheme.surface)
                        .cornerRadius(16)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(AppTheme.danger)
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
    
    private func macroBadge(name: String, value: String, color: Color) -> some View {
        VStack {
            Text(value)
                .font(.footnote.bold())
                .foregroundColor(color)
            Text(name)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
    
    private func analyze(_ image: UIImage) {
        isAnalyzing = true
        errorMessage = nil
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
}
