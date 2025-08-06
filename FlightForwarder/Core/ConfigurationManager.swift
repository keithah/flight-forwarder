import Foundation
import SwiftUI
import CoreTelephony

class ConfigurationManager: ObservableObject {
    @Published var configuration: UserConfiguration
    @Published var detectedCarrier: CarrierType?
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "userConfiguration"
    private let networkInfo = CTTelephonyNetworkInfo()
    
    init() {
        if let data = userDefaults.data(forKey: configKey),
           let config = try? JSONDecoder().decode(UserConfiguration.self, from: data) {
            self.configuration = config
        } else {
            self.configuration = UserConfiguration()
        }
        
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
        if let carriers = networkInfo.serviceSubscriberCellularProviders {
            for (_, carrier) in carriers {
                if let carrierName = carrier.carrierName?.lowercased() {
                    if carrierName.contains("verizon") {
                        detectedCarrier = .verizon
                    } else if carrierName.contains("at&t") || carrierName.contains("att") {
                        detectedCarrier = .att
                    } else if carrierName.contains("t-mobile") || carrierName.contains("tmobile") {
                        detectedCarrier = .tmobile
                    } else if carrierName.contains("google") && carrierName.contains("fi") {
                        detectedCarrier = .googleFi
                    } else if carrierName.contains("visible") {
                        detectedCarrier = .visible
                    } else if carrierName.contains("mint") {
                        detectedCarrier = .mintMobile
                    }
                    break
                }
            }
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
    
    func reset() {
        configuration = UserConfiguration()
        detectedCarrier = nil
        userDefaults.removeObject(forKey: configKey)
        detectCarrier()
    }
}