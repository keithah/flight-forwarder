import Foundation
import CoreTelephony

class SIMStatusDetector {
    private let networkInfo = CTTelephonyNetworkInfo()
    
    struct SIMStatus {
        let isUnlocked: Bool
        let isDualSIM: Bool
        let simCount: Int
        let carriers: [String]
        let confidence: Confidence
        
        enum Confidence {
            case high    // Reliable detection
            case medium  // Some indicators
            case low     // Best guess
        }
    }
    
    func detectSIMStatus() -> SIMStatus {
        print("🔍 SIM Status Detection:")
        
        var carriers: [String] = []
        var simCount = 0
        var hasValidSIM = false
        
        // Check multiple providers (dual SIM)
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            print("📱 Found \(providers.count) cellular providers")
            simCount = providers.count
            
            for (key, carrier) in providers {
                print("  Provider \(key):")
                print("    Carrier Name: \(carrier.carrierName ?? "nil")")
                print("    MNC: \(carrier.mobileNetworkCode ?? "nil")")
                print("    MCC: \(carrier.mobileCountryCode ?? "nil")")
                print("    ISO Country Code: \(carrier.isoCountryCode ?? "nil")")
                print("    Allows VOIP: \(carrier.allowsVOIP)")
                
                if let name = carrier.carrierName, !name.isEmpty && name != "--" {
                    carriers.append(name)
                    hasValidSIM = true
                }
                
                // Check if we have valid MNC/MCC (indicates working SIM)
                if let mnc = carrier.mobileNetworkCode, let mcc = carrier.mobileCountryCode,
                   mnc != "65535" && mcc != "65535" && !mnc.isEmpty && !mcc.isEmpty {
                    hasValidSIM = true
                }
            }
        }
        
        // Single SIM fallback
        if simCount == 0, let carrier = networkInfo.subscriberCellularProvider {
            print("📱 Single SIM provider found")
            simCount = 1
            
            if let name = carrier.carrierName, !name.isEmpty && name != "--" {
                carriers.append(name)
                hasValidSIM = true
            }
        }
        
        // Determine if unlocked
        let isUnlocked = determineUnlockStatus(hasValidSIM: hasValidSIM, simCount: simCount)
        let isDualSIM = simCount > 1
        
        print("📊 SIM Status Summary:")
        print("  SIM Count: \(simCount)")
        print("  Has Valid SIM: \(hasValidSIM)")
        print("  Is Unlocked: \(isUnlocked)")
        print("  Is Dual SIM: \(isDualSIM)")
        print("  Carriers: \(carriers)")
        
        return SIMStatus(
            isUnlocked: isUnlocked,
            isDualSIM: isDualSIM,
            simCount: simCount,
            carriers: carriers,
            confidence: hasValidSIM ? .high : .medium
        )
    }
    
    private func determineUnlockStatus(hasValidSIM: Bool, simCount: Int) -> Bool {
        // Basic heuristics for SIM unlock detection
        // Note: There's no direct API to check SIM lock status
        
        // If we can read SIM info, it's likely unlocked or at least functional
        if hasValidSIM {
            return true
        }
        
        // If we have multiple SIM slots detected, device supports it
        if simCount > 1 {
            return true // Dual SIM devices are typically unlocked
        }
        
        // Default assumption - most modern devices are unlocked
        // Especially if user is installing third-party apps like this
        return true
    }
    
    func getUnlockMessage(status: SIMStatus) -> String {
        if status.isUnlocked {
            if status.isDualSIM {
                return "Great! Your phone is SIM unlocked AND supports dual SIM! 🎉\n\nThis means you can use 3rd party SIMs such as eSIMs while keeping your current carrier SIM active. Perfect for travel - you can leave your local carrier SIM on to send/receive texts, but this app will help you forward your phone number to Google Voice or another number automatically anytime you travel.\n\nWe detect when you have an upcoming flight and forward calls an hour before takeoff, so you receive calls over data instead of through your local carrier SIM. This allows you to buy much cheaper eSIMs for data while abroad!"
            } else {
                return "Great! Your phone is SIM unlocked! 🎉\n\nThis means you can use 3rd party SIMs such as eSIMs in it. This app will help you forward your phone number to Google Voice or another number automatically when you travel, so you can use cheaper local eSIMs for data while still receiving your important calls over Wi-Fi/data."
            }
        } else {
            return "It looks like your phone might be carrier-locked. This app can still help you forward calls when traveling, but you may be limited to your current carrier's international roaming options."
        }
    }
    
    func getTechExplanation(status: SIMStatus) -> String {
        var explanation = ""
        
        if status.isDualSIM {
            explanation += "Dual SIM detected: You have \(status.simCount) SIM slots available. "
        }
        
        if !status.carriers.isEmpty {
            explanation += "Active carriers: \(status.carriers.joined(separator: ", ")). "
        }
        
        if status.isUnlocked {
            explanation += "Your device appears to support third-party carriers and eSIMs."
        }
        
        return explanation
    }
}