import SwiftUI

public struct WorkoutListView: View {
    @State private var routines: [WorkoutRoutine] = [
        WorkoutRoutine(
            title: "Fuerza — Empuje (Push)",
            subtitle: "Pecho, Hombro anterior y Tríceps",
            iconName: "figure.strengthtraining.traditional",
            exercises: [
                ExerciseLog(name: "Press de Banca con Barra", category: .chest, sets: [
                    WorkoutSet(setNumber: 1, weightKg: 80.0, reps: 8, rir: 2),
                    WorkoutSet(setNumber: 2, weightKg: 80.0, reps: 7, rir: 1),
                    WorkoutSet(setNumber: 3, weightKg: 80.0, reps: 6, rir: 0)
                ]),
                ExerciseLog(name: "Press Inclinado con Mancuernas", category: .chest, sets: [
                    WorkoutSet(setNumber: 1, weightKg: 28.0, reps: 10, rir: 2),
                    WorkoutSet(setNumber: 2, weightKg: 28.0, reps: 9, rir: 1)
                ]),
                ExerciseLog(name: "Elevaciones Laterales", category: .shoulders, sets: [
                    WorkoutSet(setNumber: 1, weightKg: 12.0, reps: 15, rir: 1),
                    WorkoutSet(setNumber: 2, weightKg: 12.0, reps: 12, rir: 0)
                ])
            ]
        ),
        WorkoutRoutine(
            title: "Fuerza — Tirón (Pull)",
            subtitle: "Espalda completa, Deltoides posterior y Bíceps",
            iconName: "figure.cross.training",
            exercises: [
                ExerciseLog(name: "Remo con Barra", category: .back, sets: [
                    WorkoutSet(setNumber: 1, weightKg: 75.0, reps: 8, rir: 2),
                    WorkoutSet(setNumber: 2, weightKg: 75.0, reps: 8, rir: 1)
                ]),
                ExerciseLog(name: "Jalón al Pecho en Polea", category: .back, sets: [
                    WorkoutSet(setNumber: 1, weightKg: 65.0, reps: 10, rir: 2)
                ])
            ]
        ),
        WorkoutRoutine(
            title: "Fuerza — Pierna (Legs)",
            subtitle: "Cuádriceps, Isquiotibiales y Gemelos",
            iconName: "figure.walk",
            exercises: [
                ExerciseLog(name: "Sentadilla Libre", category: .legs, sets: [
                    WorkoutSet(setNumber: 1, weightKg: 100.0, reps: 6, rir: 2),
                    WorkoutSet(setNumber: 2, weightKg: 100.0, reps: 6, rir: 1)
                ])
            ]
        )
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Header Estilo Apple Fitness Workout
                    workoutHeader
                    
                    // Banner Conexión Sensor / Apple Watch
                    watchSensorNotice
                    
                    // Lista de Tarjetas de Rutina (Estilo Captura 1)
                    ForEach(routines) { routine in
                        workoutCard(routine)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
    
    private var workoutHeader: some View {
        HStack {
            Text("Workout")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(8)
                        .background(AppTheme.surfaceElevated)
                        .clipShape(Circle())
                }
                Button(action: {}) {
                    Image(systemName: "heart.slash.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(8)
                        .background(AppTheme.surfaceElevated)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.top, 10)
    }
    
    private var watchSensorNotice: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.circle.fill")
                .font(.title2)
                .foregroundColor(AppTheme.exerciseGreen)
            
            Text("Sincroniza tus series y ritmo con Apple Health para registrar sobrecarga continua.")
                .font(.footnote)
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
        }
        .padding(14)
        .background(AppTheme.surfaceElevated)
        .cornerRadius(18)
    }
    
    private func workoutCard(_ routine: WorkoutRoutine) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: routine.iconName)
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.exerciseGreen)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(routine.subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            // Botones Gemelos Estilo Apple Fitness (Captura 1)
            HStack(spacing: 12) {
                NavigationLink(destination: ActiveWorkoutView(routine: routine)) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.subheadline)
                        Text("Iniciar")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundColor(AppTheme.exerciseGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.workoutButtonBg)
                    .cornerRadius(14)
                }
                
                Button(action: {}) {
                    Image(systemName: "timer")
                        .font(.headline)
                        .foregroundColor(AppTheme.exerciseGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.workoutButtonBg)
                        .cornerRadius(14)
                }
            }
        }
        .padding(18)
        .background(AppTheme.workoutCardBg)
        .cornerRadius(22)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(AppTheme.exerciseGreen.opacity(0.15), lineWidth: 1))
    }
}
