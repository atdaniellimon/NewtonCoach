import SwiftUI

public struct CoachChatMessage: Identifiable, Codable {
    public var id = UUID()
    public var role: String // "user" o "assistant"
    public var content: String
    public var timestamp = Date()
    
    public init(id: UUID = UUID(), role: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

public struct CoachChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var messages: [CoachChatMessage] = [
        CoachChatMessage(role: "assistant", content: "¡Hola! Soy tu Newton Coach deportivo. He sincronizado tus métricas actuales, tus metas de peso y tus requerimientos nutricionales. ¿Qué entrenamos hoy o qué duda tienes con tu plan?")
    ]
    @State private var inputPrompt: String = ""
    @State private var isStreaming: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Coach Estilo Apple Fitness
                HStack {
                    Text("Newton Coach")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(AppTheme.exerciseGreen)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)
                
                // Mensajes de Chat
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                chatBubble(msg: msg)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                
                // Sugerencias Rápidas
                quickChips
                
                // Barra de Entrada
                inputBar
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
    
    private func chatBubble(msg: CoachChatMessage) -> some View {
        HStack {
            if msg.role == "user" { Spacer() }
            
            Text(msg.content)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(msg.role == "user" ? AppTheme.exerciseGreen.opacity(0.2) : AppTheme.surface)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(msg.role == "user" ? AppTheme.exerciseGreen.opacity(0.4) : AppTheme.surfaceBorder, lineWidth: 0.5)
                )
            
            if msg.role == "assistant" { Spacer() }
        }
    }
    
    private var quickChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton("¿Cuánto subir en mi press hoy?")
                chipButton("Sustituir polea ocupada")
                chipButton("¿Qué cenar con 35g de proteína?")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
    
    private func chipButton(_ text: String) -> some View {
        Button(action: {
            inputPrompt = text
            sendMessage()
        }) {
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.exerciseGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.surfaceElevated)
                .cornerRadius(16)
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Pregúntale a Newton Coach...", text: $inputPrompt)
                .padding(12)
                .background(AppTheme.surfaceElevated)
                .cornerRadius(16)
                .foregroundColor(AppTheme.textPrimary)
            
            Button(action: sendMessage) {
                Image(systemName: isStreaming ? "stop.fill" : "arrow.up")
                    .font(.body.weight(.bold))
                    .foregroundColor(.black)
                    .padding(10)
                    .background(AppTheme.exerciseGreen)
                    .clipShape(Circle())
            }
            .disabled(inputPrompt.trimmingCharacters(in: .whitespaces).isEmpty && !isStreaming)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
    }
    
    private func sendMessage() {
        let text = inputPrompt.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        inputPrompt = ""
        let userMsg = CoachChatMessage(role: "user", content: text)
        messages.append(userMsg)
        
        let assistantMsg = CoachChatMessage(role: "assistant", content: "")
        messages.append(assistantMsg)
        let assistantIndex = messages.count - 1
        
        isStreaming = true
        
        let weightUnitStr = UnitFormatter.shared.formatWeight(appState.userProfile.currentWeightKg, system: appState.userProfile.unitSystem)
        let targetUnitStr = UnitFormatter.shared.formatWeight(appState.userProfile.targetWeightKg, system: appState.userProfile.unitSystem)
        
        let systemPrompt = """
        Eres Newton Coach, científico deportivo, biomecánico y preparador físico de alto rendimiento.
        Datos del usuario:
        - Nombre: \(appState.userProfile.name)
        - Edad: \(appState.userProfile.age) años
        - Peso actual: \(weightUnitStr) -> Meta: \(targetUnitStr)
        - Días restantes: \(appState.userProfile.daysRemaining) días
        - Meta Calórica Diaria: \(Int(appState.currentTargets.targetCalories)) kcal
        - Proteína diaria objetivo: \(Int(appState.currentTargets.proteinGrams))g
        Responde con rigor biomecánico y científico, directo al grano, claro y accionable sin introducciones de relleno.
        """
        
        let history = messages.dropLast().map {
            ChatHistoryMessage(role: $0.role, content: $0.content)
        }
        
        let request = NewtonChatRequest(
            prompt: text,
            model: "Singularity",
            stream: true,
            system: systemPrompt,
            history: Array(history)
        )
        
        NewtonAPIClient.shared.streamChat(
            request: request,
            onDelta: { delta in
                messages[assistantIndex].content += delta
            },
            onComplete: { _ in
                isStreaming = false
            }
        )
    }
}
