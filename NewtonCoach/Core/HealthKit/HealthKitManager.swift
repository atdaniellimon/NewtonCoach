import Foundation
import HealthKit

public final class HealthKitManager: ObservableObject {
    public static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    @Published public var isAvailable: Bool = false
    @Published public var isAuthorized: Bool = false
    @Published public var latestWeightKg: Double?
    @Published public var latestHeightCm: Double?
    @Published public var birthDateFromHealth: Date?
    
    private init() {
        self.isAvailable = HKHealthStore.isHealthDataAvailable()
    }
    
    /// Solicita autorización para leer y escribir métricas clave en Apple Health
    public func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard isAvailable else {
            completion(false, NSError(domain: "NewtonCoach", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit no está disponible en este dispositivo"]))
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchLatestWeight()
                    self.fetchLatestHeight()
                    self.fetchBirthDate()
                }
                completion(success, error)
            }
        }
    }
    
    /// Lee el pesaje más reciente registrado en Apple Health
    public func fetchLatestWeight(completion: ((Double?) -> Void)? = nil) {
        guard let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion?(nil) }
                return
            }
            
            let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            DispatchQueue.main.async {
                self.latestWeightKg = weightInKg
                completion?(weightInKg)
            }
        }
        healthStore.execute(query)
    }
    
    /// Lee la altura configurada en Apple Health
    public func fetchLatestHeight(completion: ((Double?) -> Void)? = nil) {
        guard let heightType = HKSampleType.quantityType(forIdentifier: .height) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion?(nil) }
                return
            }
            let heightInCm = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
            DispatchQueue.main.async {
                self.latestHeightCm = heightInCm
                completion?(heightInCm)
            }
        }
        healthStore.execute(query)
    }
    
    /// Lee la fecha de cumpleaños registrada en Apple Health
    public func fetchBirthDate() {
        if let components = try? healthStore.dateOfBirthComponents(),
           let date = Calendar.current.date(from: components) {
            DispatchQueue.main.async {
                self.birthDateFromHealth = date
            }
        }
    }
    
    /// Escribe un nuevo pesaje en Apple Health
    public func saveWeightToHealthKit(weightKg: Double, date: Date = Date(), completion: @escaping (Bool, Error?) -> Void) {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(false, nil)
            return
        }
        
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(type: bodyMassType, quantity: quantity, start: date, end: date)
        
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}
