import Foundation

struct UserConfiguration: Codable {
    let carrier: CarrierType
    let forwardingNumber: String
    let detectionMethods: Set<DetectionMethod>
    let internationalBehavior: InternationalOptions
    let promptStyle: PromptPreferences
    let setupDate: Date
    
    init(
        carrier: CarrierType = .verizon,
        forwardingNumber: String = "",
        detectionMethods: Set<DetectionMethod> = [.calendar, .location],
        internationalBehavior: InternationalOptions = .alwaysForward,
        promptStyle: PromptPreferences = .detailed,
        setupDate: Date = Date()
    ) {
        self.carrier = carrier
        self.forwardingNumber = forwardingNumber
        self.detectionMethods = detectionMethods
        self.internationalBehavior = internationalBehavior
        self.promptStyle = promptStyle
        self.setupDate = setupDate
    }
    
    var isValid: Bool {
        !forwardingNumber.isEmpty && !detectionMethods.isEmpty
    }
    
    var formattedForwardingNumber: String {
        carrier.formatForwardingNumber(forwardingNumber)
    }
}

enum DetectionMethod: String, CaseIterable, Codable {
    case calendar = "Calendar Events"
    case location = "Location (Airports)"
    case wallet = "Apple Wallet Passes"
    
    var description: String {
        switch self {
        case .calendar:
            return "Scan calendar for flight keywords and patterns"
        case .location:
            return "Detect when you're at an airport"
        case .wallet:
            return "Check for boarding passes in Apple Wallet"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .calendar:
            return "calendar"
        case .location:
            return "location.fill"
        case .wallet:
            return "wallet.pass.fill"
        }
    }
}

enum InternationalOptions: String, CaseIterable, Codable {
    case alwaysForward = "Always Forward"
    case askEachTime = "Ask Each Time"
    case neverForward = "Never Forward"
    
    var description: String {
        switch self {
        case .alwaysForward:
            return "Automatically forward calls for international flights"
        case .askEachTime:
            return "Prompt before forwarding for international flights"
        case .neverForward:
            return "Only forward for domestic flights"
        }
    }
}

enum PromptPreferences: String, CaseIterable, Codable {
    case minimal = "Minimal"
    case detailed = "Detailed"
    case silent = "Silent"
    
    var description: String {
        switch self {
        case .minimal:
            return "Simple yes/no prompts"
        case .detailed:
            return "Show flight details in prompts"
        case .silent:
            return "Forward without prompting (use with caution)"
        }
    }
}