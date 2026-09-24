import SwiftUI
import PhotosUI

public struct CoachChatView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var selectedMode: CoachMode = .strength
    @State private var sessions: [CoachChatSession] = []
    @State private var currentSessionId: UUID = UUID()
    @State private var showingHistorySheet = false
    @State private var showingOneRMCalculator = false
    
    // Foto para Form Check
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    
    @State private var inputPrompt: String = ""
    @State private var isStreaming: Bool = false
    
    public init() {}
    
    public var currentSession: CoachChatSession? {
        sessions.first(where: { $0.id == currentSessionId })
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Coach Estilo Apple Fitness con Selector de Modo y Nueva Consulta
                coachHeader
                
                // Selector de Modos Especializados (Píldoras)
                modeSelectorPills
                
                // Mensajes de Chat
                chatMessageList
                
                // Mini Banner de Foto Adjunta si aplica
                if selectedPhotoData != nil {
                    attachedPhotoBanner
                }
                
                // Sugerencias Rápidas Dinámicas
                quickChips
                
                // Barra de Entrada Multimodal
                inputBar
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                loadSessions()
            }
            .sheet(isPresented: $showingHistorySheet) {
                chatHistorySheetView
            }
            .sheet(isPresented: $showingOneRMCalculator) {
                OneRMCalculatorModal()
            }
        }
    }
    
    private var coachHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Newton Coach")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(selectedMode.rawValue)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppTheme.exerciseGreen)
            }
            
            Spacer()
            
            // Botón Calculadora de 1RM
            Button(action: { showingOneRMCalculator = true }) {
                Image(systemName: "scalemass.fill")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(8)
                    .background(AppTheme.surfaceElevated)
                    .clipShape(Circle())
            }
            
            // Botón Historial de Sesiones
            Button(action: { showingHistorySheet = true }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(8)
                    .background(AppTheme.surfaceElevated)
                    .clipShape(Circle())
            }
            
            // Botón Nuevo Chat
            Button(action: startNewSession) {
                Image(systemName: "square.and.pencil")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(AppTheme.exerciseGreen)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
    
    private var modeSelectorPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CoachMode.allCases) { mode in
                    Button(action: {
                        selectedMode = mode
                        switchMode(mode)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                            Text(mode.rawValue)
                        }
                        .font(.caption2.weight(.bold))
                        .foregroundColor(selectedMode == mode ? .black : AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedMode == mode ? AppTheme.exerciseGreen : AppTheme.surfaceElevated)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
    
    private var chatMessageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if let messages = currentSession?.messages {
                        ForEach(messages) { msg in
                            chatBubble(msg: msg)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: currentSession?.messages.count) { _ in
                if let last = currentSession?.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }
    
    private var attachedPhotoBanner: some View {
        HStack {
            Image(systemName: "photo.fill")
                .foregroundColor(AppTheme.exerciseGreen)
            Text("Foto de postura / plato adjunta")
                .font(.caption2.weight(.bold))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Button(action: {
                selectedPhotoData = nil
                selectedPhotoItem = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.surfaceElevated)
    }
    
    private func cleanCoachMessage(_ raw: String) -> String {
        return RobustJSONParser.shared.sanitizeJSONString(raw)
            .replacingOccurrences(of: "<thinking>", with: "")
            .replacingOccurrences(of: "</thinking>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func chatBubble(msg: CoachChatMessage) -> some View {
        let isUser = msg.role == "user"
        let displayContent = isUser ? msg.content : cleanCoachMessage(msg.content)
        
        return HStack {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                Text(LocalizedStringKey(displayContent.isEmpty ? "..." : displayContent))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                    .textSelection(.enabled)
                
                Text(msg.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isUser ? AppTheme.exerciseGreen.opacity(0.2) : AppTheme.surface)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isUser ? AppTheme.exerciseGreen.opacity(0.4) : AppTheme.surfaceBorder, lineWidth: 0.5)
            )
            
            if !isUser { Spacer() }
        }
    }
    
    private var quickChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton("¿Cuánto subir en mi press hoy?")
                chipButton("Sustituir polea ocupada")
                chipButton("¿Qué cenar con 35g de proteína?")
                chipButton("Evaluar si necesito deload")
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
                .font(.caption2.weight(.semibold))
                .foregroundColor(AppTheme.exerciseGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.surfaceElevated)
                .cornerRadius(16)
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 10) {
            // Botón Adjuntar Foto para Form Check
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: "camera.fill")
                    .font(.body)
                    .foregroundColor(selectedPhotoData != nil ? AppTheme.exerciseGreen : AppTheme.textSecondary)
                    .padding(10)
                    .background(AppTheme.surfaceElevated)
                    .clipShape(Circle())
            }
            .onChange(of: selectedPhotoItem) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                    }
                }
            }
            
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
    
    // MARK: - Manejo de Sesiones Persistentes
    private func loadSessions() {
        let loaded = LocalDataManager.shared.loadChatSessions()
        if !loaded.isEmpty {
            self.sessions = loaded
            self.currentSessionId = loaded.first!.id
            self.selectedMode = loaded.first!.mode
        } else {
            startNewSession()
        }
    }
    
    private func saveSessions() {
        LocalDataManager.shared.saveChatSessions(sessions)
    }
    
    private func startNewSession() {
        let newSession = CoachChatSession(
            title: "Consulta \(selectedMode.rawValue)",
            mode: selectedMode,
            messages: [
                CoachChatMessage(role: "assistant", content: selectedMode.welcomeMessage)
            ]
        )
        sessions.insert(newSession, at: 0)
        currentSessionId = newSession.id
        saveSessions()
    }
    
    private func switchMode(_ mode: CoachMode) {
        if let idx = sessions.firstIndex(where: { $0.id == currentSessionId }) {
            sessions[idx].mode = mode
            if sessions[idx].messages.count <= 1 {
                sessions[idx].messages = [CoachChatMessage(role: "assistant", content: mode.welcomeMessage)]
            }
            saveSessions()
        }
    }
    
    private func sendMessage() {
        let text = inputPrompt.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        guard let sessionIndex = sessions.firstIndex(where: { $0.id == currentSessionId }) else { return }
        
        inputPrompt = ""
        let userMsg = CoachChatMessage(role: "user", content: text)
        sessions[sessionIndex].messages.append(userMsg)
        
        let assistantMsg = CoachChatMessage(role: "assistant", content: "")
        sessions[sessionIndex].messages.append(assistantMsg)
        let assistantIndex = sessions[sessionIndex].messages.count - 1
        
        isStreaming = true
        
        let weightUnitStr = UnitFormatter.shared.formatWeight(appState.userProfile.currentWeightKg, system: appState.userProfile.unitSystem)
        let targetUnitStr = UnitFormatter.shared.formatWeight(appState.userProfile.targetWeightKg, system: appState.userProfile.unitSystem)
        
        let systemPrompt = """
        Eres Newton Coach, científico deportivo, biomecánico y preparador físico de alto rendimiento.
        Modo actual: \(selectedMode.rawValue).
        Datos del usuario:
        - Nombre: \(appState.userProfile.name)
        - Edad: \(appState.userProfile.age) años
        - Peso actual: \(weightUnitStr) -> Meta: \(targetUnitStr)
        - Días restantes: \(appState.userProfile.daysRemaining) días
        - Meta Calórica Diaria: \(Int(appState.currentTargets.targetCalories)) kcal
        - Proteína diaria objetivo: \(Int(appState.currentTargets.proteinGrams))g
        Instrucciones: Responde con rigor biomecánico y científico, directo al grano, claro y accionable sin introducciones de relleno.
        """
        
        let history = sessions[sessionIndex].messages.dropLast().map {
            ChatHistoryMessage(role: $0.role, content: $0.content)
        }
        
        var attachments: [NewtonAttachment]? = nil
        if let data = selectedPhotoData {
            let base64 = "data:image/jpeg;base64," + data.base64EncodedString()
            attachments = [NewtonAttachment(type: "image", data: base64, name: "form_check.jpg")]
            selectedPhotoData = nil
            selectedPhotoItem = nil
        }
        
        let request = NewtonChatRequest(
            prompt: text,
            model: "Singularity",
            stream: true,
            system: systemPrompt,
            history: Array(history),
            attachments: attachments
        )
        
        NewtonAPIClient.shared.streamChat(
            request: request,
            onDelta: { delta in
                if sessionIndex < sessions.count && assistantIndex < sessions[sessionIndex].messages.count {
                    sessions[sessionIndex].messages[assistantIndex].content += delta
                }
            },
            onComplete: { _ in
                isStreaming = false
                saveSessions()
            }
        )
    }
    
    // MARK: - Sheet Historial de Sesiones
    private var chatHistorySheetView: some View {
        NavigationStack {
            List {
                ForEach(sessions) { s in
                    Button(action: {
                        currentSessionId = s.id
                        selectedMode = s.mode
                        showingHistorySheet = false
                    }) {
                        HStack {
                            Image(systemName: s.mode.icon)
                                .foregroundColor(AppTheme.exerciseGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text(s.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                            if s.id == currentSessionId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.exerciseGreen)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    sessions.remove(atOffsets: indexSet)
                    if sessions.isEmpty { startNewSession() }
                    else if !sessions.contains(where: { $0.id == currentSessionId }) {
                        currentSessionId = sessions.first!.id
                    }
                    saveSessions()
                }
            }
            .navigationTitle("Conversaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showingHistorySheet = false }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Nuevo Chat") {
                        startNewSession()
                        showingHistorySheet = false
                    }
                    .foregroundColor(AppTheme.exerciseGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Modal Calculadora de 1RM
public struct OneRMCalculatorModal: View {
    @Environment(\.dismiss) var dismiss
    @State private var weightInput: String = "80"
    @State private var repsInput: String = "8"
    
    public init() {}
    
    private var oneRM: Double {
        guard let w = Double(weightInput), let r = Double(repsInput), r >= 1 else { return 0 }
        // Epley Formula: 1RM = Weight * (1 + 0.0333 * Reps)
        return w * (1.0 + (0.0333 * r))
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Calculadora de 1RM")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Estimación científica de repetición máxima (Fórmula de Epley)")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Peso (kg)").font(.caption2).foregroundColor(AppTheme.textSecondary)
                        TextField("80", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                            .padding(10)
                            .background(AppTheme.surfaceElevated)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Repeticiones").font(.caption2).foregroundColor(AppTheme.textSecondary)
                        TextField("8", text: $repsInput)
                            .keyboardType(.numberPad)
                            .font(.title3.bold())
                            .padding(10)
                            .background(AppTheme.surfaceElevated)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                VStack(spacing: 6) {
                    Text("Tu 1RM Estimado")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(String(format: "%.1f KG", oneRM))
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.exerciseGreen)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.surface)
                .cornerRadius(20)
                .padding(.horizontal)
                
                // Tabla de Porcentajes de Carga
                VStack(spacing: 8) {
                    Text("Porcentajes de Entrenamiento")
                        .font(.footnote.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack {
                        percentagePill(pct: "90%", reps: "3-4 reps", val: oneRM * 0.9)
                        percentagePill(pct: "80%", reps: "7-8 reps", val: oneRM * 0.8)
                        percentagePill(pct: "70%", reps: "10-12 reps", val: oneRM * 0.7)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.fraction(0.65)])
    }
    
    private func percentagePill(pct: String, reps: String, val: Double) -> some View {
        VStack(spacing: 2) {
            Text(pct).font(.caption.bold()).foregroundColor(AppTheme.exerciseGreen)
            Text(String(format: "%.1f kg", val)).font(.system(.footnote, weight: .heavy))
            Text(reps).font(.system(size: 9)).foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppTheme.surfaceElevated)
        .cornerRadius(12)
    }
}
