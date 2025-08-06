import Foundation

enum CarrierType: String, CaseIterable, Codable {
    case verizon = "Verizon"
    case att = "AT&T"
    case tmobile = "T-Mobile"
    case googleFi = "Google Fi"
    case visible = "Visible"
    case mintMobile = "Mint Mobile"
    case other = "Other (Custom)"
    
    var forwardingCode: String {
        switch self {
        case .verizon, .visible:
            return "*72"
        case .att, .tmobile, .mintMobile:
            return "**21*"
        case .googleFi:
            return ""
        case .other:
            return "*72"
        }
    }
    
    var forwardingCodeSuffix: String {
        switch self {
        case .verizon, .visible, .googleFi, .other:
            return ""
        case .att, .tmobile, .mintMobile:
            return "#"
        }
    }
    
    var disableCode: String {
        switch self {
        case .verizon, .visible:
            return "*73"
        case .att, .tmobile, .mintMobile:
            return "##21#"
        case .googleFi:
            return ""
        case .other:
            return "*73"
        }
    }
    
    var requiresAppForForwarding: Bool {
        return self == .googleFi
    }
    
    var instructions: String {
        switch self {
        case .googleFi:
            return "Google Fi requires using their app or website to set up call forwarding. The shortcut will guide you to the right place."
        default:
            return "Your carrier uses standard dialing codes for call forwarding."
        }
    }
    
    func formatForwardingNumber(_ number: String) -> String {
        let cleanNumber = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        switch self {
        case .verizon, .visible, .googleFi, .other:
            return "\(forwardingCode)\(cleanNumber)"
        case .att, .tmobile, .mintMobile:
            return "\(forwardingCode)\(cleanNumber)\(forwardingCodeSuffix)"
        }
    }
}