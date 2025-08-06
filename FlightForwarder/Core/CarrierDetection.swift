import Foundation
import CoreTelephony

class CarrierDetector {
    private let networkInfo = CTTelephonyNetworkInfo()
    
    // MNC codes for US carriers
    private let carrierMNCMap: [String: CarrierType] = [
        // Verizon
        "004": .verizon, "010": .verizon, "012": .verizon, "013": .verizon,
        "590": .verizon, "890": .verizon, "910": .verizon,
        
        // AT&T
        "030": .att, "070": .att, "150": .att, "170": .att,
        "280": .att, "380": .att, "410": .att, "560": .att,
        
        // T-Mobile (including former Sprint)
        "160": .tmobile, "200": .tmobile, "210": .tmobile, "220": .tmobile,
        "230": .tmobile, "240": .tmobile, "250": .tmobile, "260": .tmobile,
        "270": .tmobile, "310": .tmobile, "490": .tmobile, "660": .tmobile,
        "800": .tmobile, "120": .tmobile,
        
        // Visible (Verizon MVNO)
        "480": .visible,
        
        // Mint Mobile uses T-Mobile network
        // Will be detected as T-Mobile and user can override
    ]
    
    struct CarrierInfo {
        let carrier: CarrierType
        let confidence: Confidence
        let detectedName: String?
        
        enum Confidence {
            case high   // Detected via MNC code
            case medium // Detected via carrier name
            case low    // Unknown/manual selection needed
        }
    }
    
    func detectCarrier() -> CarrierInfo {
        // Try MNC code detection first (most reliable)
        if let mncCarrier = detectCarrierByMNC() {
            return mncCarrier
        }
        
        // Fallback to carrier name matching
        if let nameCarrier = detectCarrierByName() {
            return nameCarrier
        }
        
        // Return unknown result
        return CarrierInfo(
            carrier: .verizon, // Default to most common
            confidence: .low,
            detectedName: nil
        )
    }
    
    private func detectCarrierByMNC() -> CarrierInfo? {
        // Check all available providers (handles dual SIM)
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            for (_, carrier) in providers {
                if let mnc = carrier.mobileNetworkCode,
                   let mappedCarrier = carrierMNCMap[mnc] {
                    return CarrierInfo(
                        carrier: mappedCarrier,
                        confidence: .high,
                        detectedName: carrier.carrierName
                    )
                }
            }
        }
        
        // Single SIM fallback
        if let carrier = networkInfo.subscriberCellularProvider,
           let mnc = carrier.mobileNetworkCode,
           let mappedCarrier = carrierMNCMap[mnc] {
            return CarrierInfo(
                carrier: mappedCarrier,
                confidence: .high,
                detectedName: carrier.carrierName
            )
        }
        
        return nil
    }
    
    private func detectCarrierByName() -> CarrierInfo? {
        let carrierName: String?
        
        // Try to get carrier name from any available source
        if let providers = networkInfo.serviceSubscriberCellularProviders,
           let firstCarrier = providers.values.first {
            carrierName = firstCarrier.carrierName
        } else {
            carrierName = networkInfo.subscriberCellularProvider?.carrierName
        }
        
        guard let name = carrierName?.lowercased() else { return nil }
        
        // Match carrier by name patterns
        let carrier: CarrierType
        switch name {
        case let n where n.contains("verizon"):
            carrier = .verizon
        case let n where n.contains("at&t") || n.contains("att"):
            carrier = .att
        case let n where n.contains("t-mobile") || n.contains("tmobile"):
            carrier = .tmobile
        case let n where n.contains("visible"):
            carrier = .visible
        case let n where n.contains("mint"):
            carrier = .mintMobile
        case let n where n.contains("google fi") || n.contains("fi"):
            carrier = .googleFi
        default:
            return nil
        }
        
        return CarrierInfo(
            carrier: carrier,
            confidence: .medium,
            detectedName: carrierName
        )
    }
    
    // Get all carriers for dual SIM phones
    func getAllDetectedCarriers() -> [CarrierInfo] {
        var carriers: [CarrierInfo] = []
        
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            for (_, carrier) in providers {
                if let mnc = carrier.mobileNetworkCode,
                   let mappedCarrier = carrierMNCMap[mnc] {
                    carriers.append(CarrierInfo(
                        carrier: mappedCarrier,
                        confidence: .high,
                        detectedName: carrier.carrierName
                    ))
                } else if let name = carrier.carrierName {
                    // Try name-based detection for this specific carrier
                    if let nameBasedInfo = detectCarrierByNameString(name) {
                        carriers.append(nameBasedInfo)
                    }
                }
            }
        }
        
        return carriers
    }
    
    private func detectCarrierByNameString(_ name: String) -> CarrierInfo? {
        let lowercased = name.lowercased()
        
        let carrier: CarrierType
        switch lowercased {
        case let n where n.contains("verizon"):
            carrier = .verizon
        case let n where n.contains("at&t") || n.contains("att"):
            carrier = .att
        case let n where n.contains("t-mobile") || n.contains("tmobile"):
            carrier = .tmobile
        case let n where n.contains("visible"):
            carrier = .visible
        case let n where n.contains("mint"):
            carrier = .mintMobile
        case let n where n.contains("google fi") || n.contains("fi"):
            carrier = .googleFi
        default:
            return nil
        }
        
        return CarrierInfo(
            carrier: carrier,
            confidence: .medium,
            detectedName: name
        )
    }
}