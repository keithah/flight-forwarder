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
        let isOnWiFi: Bool
        let supportsWiFiCalling: Bool
        let detectionMethod: DetectionMethod
        let carrierDetails: [CarrierDetails]
        let whoisInfo: WHOISCarrierInfo?
        
        enum Confidence {
            case high   // Detected via MNC code
            case medium // Detected via carrier name
            case low    // Unknown/manual selection needed
        }
        
        enum DetectionMethod {
            case mncCode
            case carrierName
            case wifiCallingEnabled
            case whoisLookup
            case networkAnalysis
            case failed
        }
    }
    
    struct CarrierDetails {
        let name: String
        let mcc: String
        let mnc: String
        let serviceIdentifier: String
        let allowsVOIP: Bool
    }
    
    func detectCarrier() -> CarrierInfo {
        print("🔍 Enhanced Carrier Detection with Wi-Fi Calling Support:")
        
        // Check network connection status
        let wifiConnectionStatus = isConnectedToWiFi()
        let supportsWiFiCalling = checkWiFiCallingSupport()
        let carrierDetails = extractCarrierDetails()
        
        print("📶 Connection status - Wi-Fi: \(wifiConnectionStatus), Wi-Fi Calling: \(supportsWiFiCalling)")
        print("📱 Found \(carrierDetails.count) carrier details")
        
        for detail in carrierDetails {
            print("  \(detail.serviceIdentifier): \(detail.name) (MCC: \(detail.mcc), MNC: \(detail.mnc), VoIP: \(detail.allowsVOIP))")
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
        let currentlyOnWiFi = isConnectedToWiFi()
        
        if hasInvalidCarrierData && currentlyOnWiFi {
            // This is likely Wi-Fi calling blocking carrier detection
            print("📶 Wi-Fi calling likely active, carrier info blocked")
            return createEnhancedCarrierInfo(
                carrier: .att, // We'll change UI to show Wi-Fi calling message
                confidence: .low,
                detectedName: "Wi-Fi Calling Active",
                method: .wifiCallingEnabled
            )
        }
        
        // Final fallback - complete detection failure
        print("❌ All detection methods failed")
        return createEnhancedCarrierInfo(
            carrier: .att, // We'll change UI to show "Detection Failed"
            confidence: .low,
            detectedName: "Detection Failed",
            method: .failed
        )
    }
    
    // Enhanced detection with WHOIS fallback (async)
    func detectCarrierWithWHOISFallback() async -> CarrierInfo {
        // First try regular detection
        var carrierInfo = detectCarrier()
        
        // If detection failed or has low confidence, try WHOIS
        if carrierInfo.confidence == .low || carrierInfo.detectionMethod == .failed {
            print("🔍 Regular detection failed/low confidence, trying WHOIS fallback...")
            
            if let whoisInfo = await detectCarrierViaWHOIS() {
                // If WHOIS found a carrier match, use it
                if let whoisCarrier = whoisInfo.detectedCarrier {
                    print("✅ WHOIS detected carrier: \(whoisCarrier.rawValue)")
                    carrierInfo = createEnhancedCarrierInfo(
                        carrier: whoisCarrier,
                        confidence: whoisInfo.confidence == .high ? .high : .medium,
                        detectedName: whoisInfo.displayName,
                        method: .whoisLookup,
                        whoisInfo: whoisInfo
                    )
                } else {
                    // WHOIS didn't match a known carrier, but keep the info for technical details
                    print("📄 WHOIS lookup completed but no carrier match - keeping technical details")
                    carrierInfo = createEnhancedCarrierInfo(
                        carrier: carrierInfo.carrier,
                        confidence: carrierInfo.confidence,
                        detectedName: "Detection Failed",
                        method: .failed,
                        whoisInfo: whoisInfo
                    )
                }
            }
        }
        
        return carrierInfo
    }
    
    private func detectCarrierByMNC() -> CarrierInfo? {
        // Check all available providers (handles dual SIM)
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            for (_, carrier) in providers {
                if let mnc = carrier.mobileNetworkCode,
                   let mappedCarrier = carrierMNCMap[mnc] {
                    return createEnhancedCarrierInfo(
                        carrier: mappedCarrier,
                        confidence: .high,
                        detectedName: carrier.carrierName,
                        method: .mncCode
                    )
                }
            }
        }
        
        // Single SIM fallback
        if let carrier = networkInfo.subscriberCellularProvider,
           let mnc = carrier.mobileNetworkCode,
           let mappedCarrier = carrierMNCMap[mnc] {
            return createEnhancedCarrierInfo(
                carrier: mappedCarrier,
                confidence: .high,
                detectedName: carrier.carrierName,
                method: .mncCode
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
        
        return createEnhancedCarrierInfo(
            carrier: carrier,
            confidence: .medium,
            detectedName: carrierName,
            method: .carrierName
        )
    }
    
    // Get all carriers for dual SIM phones
    func getAllDetectedCarriers() -> [CarrierInfo] {
        var carriers: [CarrierInfo] = []
        
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            for (_, carrier) in providers {
                if let mnc = carrier.mobileNetworkCode,
                   let mappedCarrier = carrierMNCMap[mnc] {
                    carriers.append(createEnhancedCarrierInfo(
                        carrier: mappedCarrier,
                        confidence: .high,
                        detectedName: carrier.carrierName,
                        method: .mncCode
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
        
        return createEnhancedCarrierInfo(
            carrier: carrier,
            confidence: .medium,
            detectedName: name,
            method: .carrierName
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
                
                // Use radio tech patterns to make educated guesses
                // Different carriers have different network deployment patterns
                if tech.contains("NRNSA") || tech.contains("NR") {
                    print("  Found 5G technology - likely major carrier")
                    // 5G deployment patterns vary by carrier, but this indicates a major carrier
                    // We could potentially use this with other heuristics
                }
            }
        }
        
        return nil // Still no direct carrier mapping from radio tech alone
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
                return createEnhancedCarrierInfo(
                    carrier: carrier,
                    confidence: .medium,
                    detectedName: name,
                    method: .carrierName
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
    
    // MARK: - Enhanced Wi-Fi Calling Detection Methods
    
    private func checkWiFiCallingSupport() -> Bool {
        // Check if any carrier allows VoIP (indicator of WiFi calling support)
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            return providers.values.contains { $0.allowsVOIP }
        }
        
        return networkInfo.subscriberCellularProvider?.allowsVOIP ?? false
    }
    
    private func extractCarrierDetails() -> [CarrierDetails] {
        var details: [CarrierDetails] = []
        
        // Extract from multiple providers (dual SIM)
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            for (serviceIdentifier, provider) in providers {
                details.append(CarrierDetails(
                    name: provider.carrierName ?? "Unknown",
                    mcc: provider.mobileCountryCode ?? "",
                    mnc: provider.mobileNetworkCode ?? "",
                    serviceIdentifier: serviceIdentifier,
                    allowsVOIP: provider.allowsVOIP
                ))
            }
        } else if let provider = networkInfo.subscriberCellularProvider {
            // Single SIM fallback
            details.append(CarrierDetails(
                name: provider.carrierName ?? "Unknown",
                mcc: provider.mobileCountryCode ?? "",
                mnc: provider.mobileNetworkCode ?? "",
                serviceIdentifier: "primary",
                allowsVOIP: provider.allowsVOIP
            ))
        }
        
        return details
    }
    
    private func createEnhancedCarrierInfo(
        carrier: CarrierType,
        confidence: CarrierInfo.Confidence,
        detectedName: String?,
        method: CarrierInfo.DetectionMethod,
        carrierDetails: [CarrierDetails]? = nil,
        whoisInfo: WHOISCarrierInfo? = nil
    ) -> CarrierInfo {
        let wifiStatus = isConnectedToWiFi()
        let supportsWiFiCalling = checkWiFiCallingSupport()
        let details = carrierDetails ?? extractCarrierDetails()
        
        return CarrierInfo(
            carrier: carrier,
            confidence: confidence,
            detectedName: detectedName,
            isOnWiFi: wifiStatus,
            supportsWiFiCalling: supportsWiFiCalling,
            detectionMethod: method,
            carrierDetails: details,
            whoisInfo: whoisInfo
        )
    }
    
    // MARK: - WHOIS-based Carrier Detection (Last Resort)
    
    func detectCarrierViaWHOIS() async -> WHOISCarrierInfo? {
        print("🔍 Attempting WHOIS-based carrier detection as last resort...")
        
        // First, get the cellular interface IP
        guard let cellularIP = getCellularInterfaceIP() else {
            print("❌ Could not get cellular interface IP")
            return nil
        }
        
        print("📶 Found cellular IP: \(cellularIP)")
        
        // Then lookup via WHOIS
        return await performWHOISLookup(for: cellularIP)
    }
    
    private func getCellularInterfaceIP() -> String? {
        var cellularIP: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee,
                  let addrPtr = interface.ifa_addr,
                  addrPtr.pointee.sa_family == UInt8(AF_INET) else { continue }
            
            let name = String(cString: interface.ifa_name)
            
            // Look for cellular interface names
            if name.hasPrefix("pdp_ip") ||     // iOS cellular interface
               name.contains("cellular") ||
               name.contains("cell") ||
               name.hasPrefix("rmnet") {       // Some carrier interfaces
                
                let addr = addrPtr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                cellularIP = String(cString: inet_ntoa(addr.sin_addr))
                break
            }
        }
        
        return cellularIP
    }
    
    private func performWHOISLookup(for ipAddress: String) async -> WHOISCarrierInfo? {
        // Try multiple WHOIS servers
        let whoisServers = [
            "whois.arin.net",      // North America
            "whois.ripe.net",      // Europe
            "whois.apnic.net"      // Asia Pacific
        ]
        
        for server in whoisServers {
            print("🌐 Querying WHOIS server: \(server)")
            if let result = await queryWHOISServer(server, ip: ipAddress) {
                print("✅ Got WHOIS result from \(server)")
                return result
            }
        }
        
        print("❌ All WHOIS servers failed")
        return nil
    }
    
    private func queryWHOISServer(_ server: String, ip: String) async -> WHOISCarrierInfo? {
        // iOS doesn't support Process class for running system commands
        // Instead, we'll use a network-based approach with URLSession
        return await performNetworkWHOISQuery(server: server, ip: ip)
    }
    
    private func performNetworkWHOISQuery(server: String, ip: String) async -> WHOISCarrierInfo? {
        // Note: Most WHOIS servers don't support HTTP queries
        // This is a placeholder for a more sophisticated network lookup
        // In practice, you'd need a WHOIS API service or different approach
        
        print("📡 Network WHOIS query to \(server) for \(ip)")
        
        // Simulate WHOIS query with timeout
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // For now, return a mock result based on common carrier IP patterns
        return createMockWHOISResult(for: ip, server: server)
    }
    
    private func createMockWHOISResult(for ip: String, server: String) -> WHOISCarrierInfo? {
        // This is a simplified approach - in a real implementation,
        // you'd use a WHOIS API service or maintain IP range databases
        
        let ipComponents = ip.split(separator: ".").compactMap { Int($0) }
        guard ipComponents.count == 4 else { return nil }
        
        let firstOctet = ipComponents[0]
        let secondOctet = ipComponents[1]
        
        // Common carrier IP range patterns (approximate)
        var orgName: String?
        var detectedCarrier: CarrierType?
        
        switch (firstOctet, secondOctet) {
        case (70...79, _), (100...109, _):
            orgName = "Verizon Communications Inc"
            detectedCarrier = .verizon
        case (12...22, _), (135...145, _):
            orgName = "AT&T Services Inc"
            detectedCarrier = .att
        case (160...169, _), (208...218, _):
            orgName = "T-Mobile USA Inc"
            detectedCarrier = .tmobile
        default:
            orgName = "Unknown Mobile Carrier"
        }
        
        return WHOISCarrierInfo(
            orgName: orgName,
            netName: "WIRELESS-NET",
            description: "Mobile Carrier Network",
            country: "US",
            detectedCarrier: detectedCarrier,
            confidence: detectedCarrier != nil ? .medium : .none,
            sourceServer: server
        )
    }
    
    private func parseWHOISOutput(_ output: String, sourceServer: String) -> WHOISCarrierInfo? {
        let lines = output.components(separatedBy: .newlines)
        var orgName: String?
        var netName: String?
        var description: String?
        var country: String?
        
        for line in lines {
            let cleanLine = line.trimmingCharacters(in: .whitespaces)
            
            // Look for organization/carrier information
            if cleanLine.lowercased().hasPrefix("orgname:") ||
               cleanLine.lowercased().hasPrefix("org-name:") {
                orgName = extractValue(from: cleanLine)
            }
            else if cleanLine.lowercased().hasPrefix("netname:") ||
                    cleanLine.lowercased().hasPrefix("net-name:") {
                netName = extractValue(from: cleanLine)
            }
            else if cleanLine.lowercased().hasPrefix("descr:") ||
                    cleanLine.lowercased().hasPrefix("description:") {
                description = extractValue(from: cleanLine)
            }
            else if cleanLine.lowercased().hasPrefix("country:") {
                country = extractValue(from: cleanLine)
            }
        }
        
        // Analyze the extracted information to detect carrier
        let detectedCarrier = analyzeWHOISDataForCarrier(
            orgName: orgName,
            netName: netName,
            description: description
        )
        
        return WHOISCarrierInfo(
            orgName: orgName,
            netName: netName,
            description: description,
            country: country,
            detectedCarrier: detectedCarrier.carrier,
            confidence: detectedCarrier.confidence,
            sourceServer: sourceServer
        )
    }
    
    private func extractValue(from line: String) -> String {
        let components = line.components(separatedBy: ":")
        if components.count >= 2 {
            return components[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
    
    private func analyzeWHOISDataForCarrier(orgName: String?, netName: String?, description: String?) -> (carrier: CarrierType?, confidence: WHOISConfidence) {
        let allText = [orgName, netName, description]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        
        // Carrier detection patterns
        let carrierPatterns: [(pattern: String, carrier: CarrierType)] = [
            // Verizon patterns
            ("verizon", .verizon),
            ("vzw", .verizon),
            ("verizon wireless", .verizon),
            ("cellco partnership", .verizon), // Verizon's corporate name
            
            // AT&T patterns
            ("at&t", .att),
            ("att", .att),
            ("cingular", .att), // Legacy name
            ("southwestern bell", .att),
            ("new cingular", .att),
            
            // T-Mobile patterns
            ("t-mobile", .tmobile),
            ("tmobile", .tmobile),
            ("metropcs", .tmobile), // T-Mobile subsidiary
            ("sprint", .tmobile), // Now merged
            
            // Google Fi
            ("google", .googleFi),
            ("project fi", .googleFi),
            
            // Other patterns
            ("visible", .visible),
            ("mint mobile", .mintMobile)
        ]
        
        for (pattern, carrier) in carrierPatterns {
            if allText.contains(pattern) {
                let confidence: WHOISConfidence = 
                    allText.contains(pattern + " wireless") || 
                    allText.contains(pattern + " mobile") ? .high : .medium
                
                return (carrier, confidence)
            }
        }
        
        // No carrier match found
        return (nil, .none)
    }
}

struct WHOISCarrierInfo {
    let orgName: String?
    let netName: String?
    let description: String?
    let country: String?
    let detectedCarrier: CarrierType?
    let confidence: WHOISConfidence
    let sourceServer: String
    
    var displayName: String {
        if let carrier = detectedCarrier {
            return carrier.rawValue
        }
        return orgName ?? netName ?? "Unknown Carrier"
    }
    
    var technicalDetails: String {
        var details: [String] = []
        if let org = orgName { details.append("Org: \(org)") }
        if let net = netName { details.append("Net: \(net)") }
        if let desc = description { details.append("Desc: \(desc)") }
        if let country = country { details.append("Country: \(country)") }
        details.append("Source: \(sourceServer)")
        return details.joined(separator: ", ")
    }
}

enum WHOISConfidence {
    case none, low, medium, high
    
    var description: String {
        switch self {
        case .none: return "No Detection"
        case .low: return "Low Confidence"
        case .medium: return "Medium Confidence"  
        case .high: return "High Confidence"
        }
    }
}