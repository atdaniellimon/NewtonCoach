import SwiftUI

public struct ActiveWorkoutView: View {
    @State public var routine: WorkoutRoutine
    @State private var restSecondsRemaining = 0
    @State private var timerActive = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    public init(routine: WorkoutRoutine) {
        self._routine = State(initialValue: routine)
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header de Sesión Activa
                VStack(spacing: 6) {
                    Text(routine.title)
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Registra cada serie y controla el RIR hacia el fallo")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                // Barra Flotante de Temporizador de Descanso
                if timerActive {
                    HStack(spacing: 12) {
                        Image(systemName: "timer")
                            .foregroundColor(AppTheme.exerciseGreen)
                        Text("Descanso: \(restSecondsRemaining)s")
                            .font(.headline.weight(.bold))
                            .foregroundColor(AppTheme.exerciseGreen)
                            .monospacedDigit()
                        Spacer()
                        Button("Saltar") {
                            timerActive = false
                        }
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding()
                    .background(AppTheme.surfaceElevated)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.exerciseGreen.opacity(0.4), lineWidth: 1))
                }
                
                // Lista de Ejercicios
                ForEach(0..<routine.exercises.count, id: \.self) { exerciseIndex in
                    exerciseBlock(exerciseIndex: exerciseIndex)
                }
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Sesión en Vivo")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            if timerActive && restSecondsRemaining > 0 {
                restSecondsRemaining -= 1
            } else if restSecondsRemaining == 0 && timerActive {
                timerActive = false
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
    
    private func exerciseBlock(exerciseIndex: Int) -> some View {
        let exercise = routine.exercises[exerciseIndex]
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.name)
                    .font(.headline.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text(exercise.category.rawValue)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppTheme.exerciseGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.exerciseGreen.opacity(0.15))
                    .cornerRadius(8)
            }
            
            // Tabla de Series
            VStack(spacing: 8) {
                HStack {
                    Text("SERIE").frame(width: 40)
                    Text("KG").frame(maxWidth: .infinity)
                    Text("REPS").frame(maxWidth: .infinity)
                    Text("RIR").frame(width: 50)
                    Text("LISTO").frame(width: 50)
                }
                .font(.caption2.weight(.bold))
                .foregroundColor(AppTheme.textSecondary)
                
                ForEach(0..<routine.exercises[exerciseIndex].sets.count, id: \.self) { setIndex in
                    let set = routine.exercises[exerciseIndex].sets[setIndex]
                    
                    HStack {
                        Text("\(set.setNumber)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 40)
                        
                        TextField("kg", value: $routine.exercises[exerciseIndex].sets[setIndex].weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.subheadline.weight(.semibold))
                            .padding(6)
                            .background(AppTheme.surfaceElevated)
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity)
                        
                        TextField("reps", value: $routine.exercises[exerciseIndex].sets[setIndex].reps, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.subheadline.weight(.semibold))
                            .padding(6)
                            .background(AppTheme.surfaceElevated)
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity)
                        
                        TextField("RIR", value: $routine.exercises[exerciseIndex].sets[setIndex].rir, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.subheadline.weight(.semibold))
                            .padding(6)
                            .background(AppTheme.surfaceElevated)
                            .cornerRadius(8)
                            .frame(width: 50)
                        
                        Button(action: {
                            routine.exercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
                            if routine.exercises[exerciseIndex].sets[setIndex].isCompleted {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                restSecondsRemaining = 90
                                timerActive = true
                            }
                        }) {
                            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(set.isCompleted ? AppTheme.exerciseGreen : AppTheme.surfaceBorder)
                        }
                        .frame(width: 50)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.surfaceBorder, lineWidth: 0.5))
    }
}
