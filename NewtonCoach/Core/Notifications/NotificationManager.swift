import Foundation
import UserNotifications

public final class NotificationManager: NSObject, ObservableObject {
    public static let shared = NotificationManager()
    
    @Published public var isAuthorized: Bool = false
    
    private override init() {
        super.init()
        checkAuthorization()
    }
    
    public func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.scheduleDefaultReminders()
                }
            }
        }
    }
    
    public func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Programa recordatorios diarios para pesaje, comidas e hidratación
    public func scheduleDefaultReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        // 1. Pesaje en Ayunas (07:30 AM)
        scheduleDailyNotification(
            id: "reminder_weigh_in",
            title: "⚖️ Momento de Pesaje",
            body: "¿Cómo va ese progreso? Pésate en ayunas y regístralo en NewtonCoach.",
            hour: 7,
            minute: 30
        )
        
        // 2. Almuerzo / Comida (13:30 PM)
        scheduleDailyNotification(
            id: "reminder_lunch",
            title: "🥗 Hora de Nutrirte",
            body: "Revisa tu menú recomendado de hoy o sácale una foto a tu plato.",
            hour: 13,
            minute: 30
        )
        
        // 3. Recordatorio de Entrenamiento / Hidratación (18:00 PM)
        scheduleDailyNotification(
            id: "reminder_workout",
            title: "🏋️ Sesión Newton Coach",
            body: "Momento de entrenar y activar la sobrecarga progresiva. ¡Vamos a darle!",
            hour: 18,
            minute: 0
        )
        
        // 4. Notificación Especial de Cumpleaños
        scheduleBirthdayNotification()
    }
    
    private func scheduleDailyNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error programando notificación \(id): \(error.localizedDescription)")
            }
        }
    }
    
    public func scheduleBirthdayNotification() {
        guard let profileData = UserDefaults.standard.data(forKey: "newton_user_profile_v1"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) else {
            return
        }
        
        let calendar = Calendar.current
        let birthComponents = calendar.dateComponents([.month, .day], from: profile.birthDate)
        
        let content = UNMutableNotificationContent()
        content.title = "🎂 ¡Feliz Cumpleaños \(profile.name)!"
        content.body = "Un año más fuerte, más disciplinado y más enfocado. ¡Hoy desbloqueaste tu medalla de Cumpleaños!"
        content.sound = .default
        
        var triggerComponents = DateComponents()
        triggerComponents.month = birthComponents.month
        triggerComponents.day = birthComponents.day
        triggerComponents.hour = 9
        triggerComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "reminder_birthday", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
