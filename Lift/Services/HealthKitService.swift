import Foundation
import HealthKit

@MainActor
public class HealthKitService {
    public static let shared = HealthKitService()
    
    private let healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    
    public var isAvailable: Bool {
        healthStore != nil
    }
    
    private init() {}
    
    public func requestPermissions(completion: @escaping (Bool, Error?) -> Void) {
        guard let healthStore = healthStore else {
            completion(false, NSError(domain: "LiftHealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }
        
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(false, NSError(domain: "LiftHealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Body mass type not available."]))
            return
        }
        
        let typesToRead: Set<HKObjectType> = [bodyMassType]
        let typesToWrite: Set<HKSampleType> = [bodyMassType]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    public func fetchLatestBodyweight(completion: @escaping (Double?, Date?, Error?) -> Void) {
        guard let healthStore = healthStore else {
            completion(nil, nil, NSError(domain: "LiftHealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit not available."]))
            return
        }
        
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil, nil, NSError(domain: "LiftHealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Body mass type unavailable."]))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, error in
            guard error == nil else {
                DispatchQueue.main.async { completion(nil, nil, error) }
                return
            }
            
            if let sample = results?.first as? HKQuantitySample {
                let unit = UserSettingsManager.shared.bodyweightUnit == .lb ? HKUnit.pound() : HKUnit.gramUnit(with: .kilo)
                let weight = sample.quantity.doubleValue(for: unit)
                let date = sample.startDate
                DispatchQueue.main.async {
                    completion(weight, date, nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil, nil, nil)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    public func saveBodyweight(weight: Double, date: Date, completion: @escaping (Bool, Error?) -> Void) {
        guard let healthStore = healthStore else {
            completion(false, NSError(domain: "LiftHealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit not available."]))
            return
        }
        
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(false, NSError(domain: "LiftHealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Body mass type unavailable."]))
            return
        }
        
        let unit = UserSettingsManager.shared.bodyweightUnit == .lb ? HKUnit.pound() : HKUnit.gramUnit(with: .kilo)
        let quantity = HKQuantity(unit: unit, doubleValue: weight)
        let sample = HKQuantitySample(type: bodyMassType, quantity: quantity, start: date, end: date)
        
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}
