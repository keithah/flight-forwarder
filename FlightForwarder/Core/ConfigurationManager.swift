import Foundation
import SwiftUI
import CoreTelephony

class ConfigurationManager: ObservableObject {
    @Published var configuration: UserConfiguration
    @Published var detectedCarrier: CarrierType?
    @Published var carrierConfidence: CarrierDetector.CarrierInfo.Confidence = .low
    @Published var detectedCarrierName: String?
    @Published var simStatus: SIMStatusDetector.SIMStatus?
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "userConfiguration"
    private let carrierDetector = CarrierDetector()
    let simDetector = SIMStatusDetector() // Public so views can access helper methods
    
    init() {
        if let data = userDefaults.data(forKey: configKey),
           let config = try? JSONDecoder().decode(UserConfiguration.self, from: data) {
            self.configuration = config
        } else {
            self.configuration = UserConfiguration()
        }
        
        detectSIMStatus()
        detectCarrier()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(configuration) {
            userDefaults.set(data, forKey: configKey)
        }
    }
    
    func update(configuration: UserConfiguration) {
        self.configuration = configuration
        save()
    }
    
    func detectCarrier() {
        let carrierInfo = carrierDetector.detectCarrier()
        
        detectedCarrier = carrierInfo.carrier
        carrierConfidence = carrierInfo.confidence
        detectedCarrierName = carrierInfo.detectedName
        
        // If we have high confidence and no saved configuration, auto-select this carrier
        if carrierInfo.confidence == .high && !configuration.isValid {
            configuration = UserConfiguration(
                carrier: carrierInfo.carrier,
                forwardingNumber: configuration.forwardingNumber,
                detectionMethods: configuration.detectionMethods,
                internationalBehavior: configuration.internationalBehavior,
                promptStyle: configuration.promptStyle
            )
        }
    }
    
    func validatePhoneNumber(_ number: String) -> Bool {
        let cleanNumber = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        if cleanNumber.hasPrefix("+") {
            return cleanNumber.count >= 10 && cleanNumber.count <= 15
        } else {
            return cleanNumber.count == 10 || cleanNumber.count == 11
        }
    }
    
    func formatPhoneNumber(_ number: String) -> String {
        let cleanNumber = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        if cleanNumber.hasPrefix("+") {
            return cleanNumber
        } else if cleanNumber.count == 10 {
            return "+1\(cleanNumber)"
        } else if cleanNumber.count == 11 && cleanNumber.hasPrefix("1") {
            return "+\(cleanNumber)"
        } else {
            return cleanNumber
        }
    }
    
    func detectSIMStatus() {
        simStatus = simDetector.detectSIMStatus()
    }
    
    func reset() {
        configuration = UserConfiguration()
        detectedCarrier = nil
        simStatus = nil
        userDefaults.removeObject(forKey: configKey)
        detectSIMStatus()
        detectCarrier()
    }
}