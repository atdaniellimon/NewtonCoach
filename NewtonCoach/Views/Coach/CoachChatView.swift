import SwiftUI

public struct CoachChatMessage: Identifiable, Codable {
    public var id = UUID()
    public var role: String // "user" o "assistant"
    public var content: String
    public var timestamp = Date()
}

public struct CoachChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var messages: [CoachChatMessage] = [
        CoachChatMessage(role: "assistant", content: "¡Hola! Soy tu Newton Coach deportivo. Tengo presentes tus datos, tu meta de peso y tus calorías calculadas. ¿Qué entrenamos hoy o qué duda tienes con tu nutrición?")
    ]
    @State private var inputPrompt: String = ""
    @State private var isStreaming: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            chatBubble(msg: msg)
                        }
                    }
                    .padding()
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
        .navigationTitle("Newton Coach")
    }
    
    private func chatBubble(msg: CoachChatMessage) -> some View {
        HStack {
            if msg.role == "user" { Spacer() }
            
            Text(msg.content)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(msg.role == "user" ? AppTheme.secondaryAccent : AppTheme.surfaceElevated)
                .cornerRadius(16)
            
            if msg.role == "assistant" { Spacer() }
        }
    }
    
    private var quickChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton("¿Cuánto descansar hoy?")
                chipButton("Sustituir ejercicio")
                chipButton("¿Cómo llegar a mis proteínas?")
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }
    
    private func chipButton(_ text: String) -> some View {
        Button(action: {
            inputPrompt = text
            sendMessage()
        }) {
            Text(text)
                .font(.caption.bold())
                .foregroundColor(AppTheme.primaryNeon)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.surface)
                .cornerRadius(12)
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Pregúntale a Newton Coach...", text: $inputPrompt)
                .padding(12)
                .background(AppTheme.surfaceElevated)
                .cornerRadius(12)
                .foregroundColor(AppTheme.textPrimary)
            
            Button(action: sendMessage) {
                Image(systemName: isStreaming ? "stop.fill" : "paperplane.fill")
                    .foregroundColor(.black)
                    .padding(12)
                    .background(AppTheme.primaryNeon)
                    .clipShape(Circle())
            }
            .disabled(inputPrompt.trimmingCharacters(in: .whitespaces).isEmpty && !isStreaming)
        }
        .padding()
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
        
        let systemPrompt = """
        Eres Newton Coach, preparador físico y biomecánico de élite.
        El usuario es \(appState.userProfile.name), tiene \(appState.userProfile.age) años, peso actual \(String(format: "%.1f", appState.userProfile.currentWeightKg)) kg, meta \(String(format: "%.1f", appState.userProfile.targetWeightKg)) kg, con un objetivo de \(Int(appState.currentTargets.targetCalories)) kcal diarias.
        Responde con rigor científico, directo al punto, claro y sin introducciones innecesarias.
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
