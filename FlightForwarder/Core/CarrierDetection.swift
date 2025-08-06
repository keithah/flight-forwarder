import Foundation
import CoreTelephony
import Network
import SystemConfiguration

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
        // Debug logging - let's see what we're actually getting
        print("🔍 Carrier Detection Debug:")
        
        // Check all available providers
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            print("📱 Multiple providers found: \(providers.count)")
            for (key, carrier) in providers {
                print("  Provider \(key):")
                print("    Carrier Name: \(carrier.carrierName ?? "nil")")
                print("    MNC: \(carrier.mobileNetworkCode ?? "nil")")
                print("    MCC: \(carrier.mobileCountryCode ?? "nil")")
                print("    ISO Country Code: \(carrier.isoCountryCode ?? "nil")")
                print("    Allows VOIP: \(carrier.allowsVOIP)")
            }
        } else {
            print("📱 No multiple providers")
        }
        
        // Single SIM check
        if let carrier = networkInfo.subscriberCellularProvider {
            print("📱 Single provider:")
            print("  Carrier Name: \(carrier.carrierName ?? "nil")")
            print("  MNC: \(carrier.mobileNetworkCode ?? "nil")")
            print("  MCC: \(carrier.mobileCountryCode ?? "nil")")
            print("  ISO Country Code: \(carrier.isoCountryCode ?? "nil")")
            print("  Allows VOIP: \(carrier.allowsVOIP)")
        } else {
            print("📱 No single provider")
        }
        
        // Try MNC code detection first (most reliable)
        if let mncCarrier = detectCarrierByMNC() {
            print("✅ Detected by MNC: \(mncCarrier.carrier)")
            return mncCarrier
        }
        
        // Fallback to carrier name matching
        if let nameCarrier = detectCarrierByName() {
            print("✅ Detected by name: \(nameCarrier.carrier)")
            return nameCarrier
        }
        
        // Try alternative detection methods before giving up
        
        // Method 1: Check radio access technology
        if let radioTechCarrier = detectCarrierByRadioTech() {
            print("✅ Detected by radio tech: \(radioTechCarrier.carrier)")
            return radioTechCarrier
        }
        
        // Method 2: Check service current radio access technology
        if let serviceRadioCarrier = detectCarrierByServiceRadio() {
            print("✅ Detected by service radio: \(serviceRadioCarrier.carrier)")
            return serviceRadioCarrier
        }
        
        // Method 3: Try to get any non-nil carrier name (even if it's not in our mapping)
        if let anyCarrierName = getAnyCarrierName() {
            print("🔍 Found carrier name: \(anyCarrierName)")
            // Try partial matching
            if let partialMatch = detectCarrierByPartialName(anyCarrierName) {
                print("✅ Detected by partial name match: \(partialMatch.carrier)")
                return partialMatch
            }
        }
        
        // Check if this is specifically due to Wi-Fi calling
        let hasInvalidCarrierData = hasInvalidCarrierInfo()
        let isOnWiFi = isConnectedToWiFi()
        
        if hasInvalidCarrierData && isOnWiFi {
            // This is likely Wi-Fi calling blocking carrier detection
            print("📶 Wi-Fi calling likely active, carrier info blocked")
            return CarrierInfo(
                carrier: .att, // We'll change UI to show Wi-Fi calling message
                confidence: .low,
                detectedName: "Wi-Fi Calling Active"
            )
        }
        
        // Final fallback - complete detection failure
        print("❌ All detection methods failed")
        return CarrierInfo(
            carrier: .att, // We'll change UI to show "Detection Failed"
            confidence: .low,
            detectedName: "Detection Failed"
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
    
    // MARK: - Additional Detection Methods
    
    private func detectCarrierByRadioTech() -> CarrierInfo? {
        // Check current radio access technology
        print("🔍 Trying radio technology detection...")
        
        if let radioTech = networkInfo.currentRadioAccessTechnology {
            print("  Current radio tech: \(radioTech)")
        }
        
        // Check service-specific radio tech
        if let serviceRadioTech = networkInfo.serviceCurrentRadioAccessTechnology {
            for (key, tech) in serviceRadioTech {
                print("  Service \(key) radio tech: \(tech)")
            }
        }
        
        return nil // This method doesn't directly give us carrier info
    }
    
    private func detectCarrierByServiceRadio() -> CarrierInfo? {
        print("🔍 Trying service radio detection...")
        // Sometimes service radio access tech provides different info
        if let serviceRadioTech = networkInfo.serviceCurrentRadioAccessTechnology {
            print("  Service radio tech keys: \(Array(serviceRadioTech.keys))")
        }
        return nil
    }
    
    private func getAnyCarrierName() -> String? {
        print("🔍 Looking for any carrier name...")
        
        // Check all providers for any non-empty name
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            for (key, carrier) in providers {
                if let name = carrier.carrierName, !name.isEmpty && name != "--" {
                    print("  Found name in provider \(key): '\(name)'")
                    return name
                }
            }
        }
        
        // Check single provider
        if let carrier = networkInfo.subscriberCellularProvider,
           let name = carrier.carrierName, !name.isEmpty && name != "--" {
            print("  Found name in single provider: '\(name)'")
            return name
        }
        
        print("  No valid carrier names found")
        return nil
    }
    
    private func detectCarrierByPartialName(_ name: String) -> CarrierInfo? {
        print("🔍 Trying partial name matching for: '\(name)'")
        let lowercasedName = name.lowercased()
        
        // More aggressive matching - look for partial strings
        let carrierMatches: [(String, CarrierType)] = [
            ("att", .att), ("at&t", .att), ("at t", .att),
            ("verizon", .verizon), ("vzw", .verizon), ("vz", .verizon),
            ("tmobile", .tmobile), ("t-mobile", .tmobile), ("tmo", .tmobile),
            ("sprint", .tmobile), // Sprint is now T-Mobile
            ("visible", .visible),
            ("mint", .mintMobile),
            ("google", .googleFi), ("fi", .googleFi)
        ]
        
        for (pattern, carrier) in carrierMatches {
            if lowercasedName.contains(pattern) {
                print("  Matched pattern '\(pattern)' -> \(carrier)")
                return CarrierInfo(
                    carrier: carrier,
                    confidence: .medium,
                    detectedName: name
                )
            }
        }
        
        print("  No pattern matches found")
        return nil
    }
    
    private func hasInvalidCarrierInfo() -> Bool {
        // Check if carrier info is the "invalid" values we saw
        let invalidValues = ["--", "", "65535"]
        
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            for (_, carrier) in providers {
                let name = carrier.carrierName ?? ""
                let mnc = carrier.mobileNetworkCode ?? ""
                let mcc = carrier.mobileCountryCode ?? ""
                
                // If ANY provider has valid data, return false
                if !invalidValues.contains(name) && !invalidValues.contains(mnc) && !invalidValues.contains(mcc) {
                    return false
                }
            }
        }
        
        return true // All data is invalid
    }
    
    private func isConnectedToWiFi() -> Bool {
        // Simple Wi-Fi detection
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        guard let reachability = defaultRouteReachability else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(reachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let isWiFi = !flags.contains(.isWWAN)
        
        return isReachable && !needsConnection && isWiFi
    }
}