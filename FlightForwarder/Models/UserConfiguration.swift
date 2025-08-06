import Foundation

struct UserConfiguration: Codable {
    let carrier: CarrierType
    let forwardingNumber: String
    let detectionMethods: Set<DetectionMethod>
    let internationalBehavior: InternationalOptions
    let promptStyle: PromptPreferences
    let setupDate: Date
    let customForwardingCode: String?
    let customDisableCode: String?
    let disableOption: DisableForwardingOption
    
    init(
        carrier: CarrierType = .verizon,
        forwardingNumber: String = "",
        detectionMethods: Set<DetectionMethod> = [.calendar, .location],
        internationalBehavior: InternationalOptions = .alwaysForward,
        promptStyle: PromptPreferences = .detailed,
        setupDate: Date = Date(),
        customForwardingCode: String? = nil,
        customDisableCode: String? = nil
    ) {
        self.carrier = carrier
        self.forwardingNumber = forwardingNumber
        self.detectionMethods = detectionMethods
        self.internationalBehavior = internationalBehavior
        self.promptStyle = promptStyle
        self.setupDate = setupDate
        self.customForwardingCode = customForwardingCode
        self.customDisableCode = customDisableCode
    }
    
    var isValid: Bool {
        !forwardingNumber.isEmpty && !detectionMethods.isEmpty
    }
    
    var formattedForwardingNumber: String {
        if carrier == .other, let customCode = customForwardingCode {
            let cleanNumber = forwardingNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            return "\(customCode)\(cleanNumber)"
        } else {
            return carrier.formatForwardingNumber(forwardingNumber)
        }
    }
    
    var customDisableCodeFormatted: String {
        if carrier == .other, let customDisable = customDisableCode {
            return customDisable
        } else {
            return carrier.disableCode
        }
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
    
    var examplePrompt: String {
        switch self {
        case .minimal:
            return "Forward calls now? Yes/No"
        case .detailed:
            return "Flight AA1234 to London detected departing at 2:30 PM. Forward calls to +1234567890? Yes/No"
        case .silent:
            return "(No prompt - automatically forwards)"
        }
    }
}

enum DisableForwardingOption: String, CaseIterable, Codable {
    case automatic = "Automatic"
    case prompt = "Prompt"
    case manual = "Manual"
    
    var description: String {
        switch self {
        case .automatic:
            return "Try to automatically detect when you fly back to the US and disable when you arrive"
        case .prompt:
            return "Ask for a date/time you arrive home to prompt you to disable forwarding"
        case .manual:
            return "Never automatically disable - you'll manage it manually"
        }
    }
}