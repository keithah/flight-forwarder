import Foundation
import Intents

struct ShortcutGenerator {
    let configuration: UserConfiguration
    
    func generateShortcut() -> INShortcut? {
        let shortcut = createShortcutStructure()
        return convertToINShortcut(shortcut)
    }
    
    private func createShortcutStructure() -> ShortcutFile {
        var actions: [ShortcutAction] = []
        
        actions.append(ShortcutAction(
            identifier: UUID().uuidString,
            type: "is.workflow.actions.comment",
            parameters: ["WFCommentActionText": "Flight Forwarder - Generated on \(Date().formatted())"]
        ))
        
        actions.append(ShortcutAction(
            identifier: UUID().uuidString,
            type: "is.workflow.actions.gettext",
            parameters: ["WFTextActionText": "Checking for flights..."]
        ))
        
        actions.append(ShortcutAction(
            identifier: UUID().uuidString,
            type: "is.workflow.actions.notification",
            parameters: [
                "WFNotificationActionTitle": "Flight Detection",
                "WFNotificationActionBody": "Checking for flights..."
            ]
        ))
        
        actions.append(contentsOf: createDetectionActions())
        
        actions.append(contentsOf: createForwardingActions())
        
        return ShortcutFile(
            name: "Flight Call Forwarding",
            actions: actions,
            clientVersion: "1230.1"
        )
    }
    
    private func createDetectionActions() -> [ShortcutAction] {
        var actions: [ShortcutAction] = []
        var detectionResults: [String] = []
        
        if configuration.detectionMethods.contains(.calendar) {
            let calendarCheckId = UUID().uuidString
            detectionResults.append(calendarCheckId)
            
            actions.append(ShortcutAction(
                identifier: UUID().uuidString,
                type: "is.workflow.actions.filter.calendarevents",
                parameters: [
                    "WFCalendarEventFilter": [
                        "WFActionParameterFilterPrefix": 0,
                        "WFActionParameterFilterTemplates": [
                            [
                                "Property": "Title",
                                "Operator": 4,
                                "Values": ["flight", "Flight", "FLIGHT", "departure", "arrival", "boarding"]
                            ]
                        ]
                    ],
                    "WFCalendarEventEntityDates": [
                        "WFCalendarEventEntityDateType": "Today",
                        "WFCalendarEventEntityRelativeDateQuantity": 1
                    ]
                ],
                outputUUID: calendarCheckId
            ))
            
            actions.append(ShortcutAction(
                identifier: UUID().uuidString,
                type: "is.workflow.actions.count",
                parameters: ["Input": ["Value": ["OutputUUID": calendarCheckId], "WFSerializationType": "WFTextTokenAttachment"]],
                outputUUID: "\(calendarCheckId)_count"
            ))
        }
        
        if configuration.detectionMethods.contains(.location) {
            let locationCheckId = UUID().uuidString
            detectionResults.append(locationCheckId)
            
            actions.append(ShortcutAction(
                identifier: UUID().uuidString,
                type: "is.workflow.actions.getcurrentlocation",
                parameters: [:],
                outputUUID: "\(locationCheckId)_location"
            ))
            
            actions.append(ShortcutAction(
                identifier: UUID().uuidString,
                type: "is.workflow.actions.gettext",
                parameters: ["WFTextActionText": "airport"],
                outputUUID: "\(locationCheckId)_keyword"
            ))
            
            actions.append(ShortcutAction(
                identifier: UUID().uuidString,
                type: "is.workflow.actions.conditional",
                parameters: [
                    "WFCondition": 4,
                    "WFConditionalActionString": ["Value": ["OutputUUID": "\(locationCheckId)_location"], "WFSerializationType": "WFTextTokenAttachment"],
                    "WFConditionalActionString2": ["Value": ["OutputUUID": "\(locationCheckId)_keyword"], "WFSerializationType": "WFTextTokenAttachment"]
                ],
                outputUUID: locationCheckId
            ))
        }
        
        let flightDetectedId = UUID().uuidString
        actions.append(ShortcutAction(
            identifier: UUID().uuidString,
            type: "is.workflow.actions.conditional",
            parameters: [
                "WFCondition": 100,
                "WFConditionalActionNumber": 0,
                "WFConditionalActionString": detectionResults.map { ["Value": ["OutputUUID": $0], "WFSerializationType": "WFTextTokenAttachment"] }.first ?? [:]
            ],
            outputUUID: flightDetectedId
        ))
        
        return actions
    }
    
    private func createForwardingActions() -> [ShortcutAction] {
        var actions: [ShortcutAction] = []
        
        let promptMessage = createPromptMessage()
        
        if configuration.promptStyle != .silent {
            actions.append(ShortcutAction(
                identifier: UUID().uuidString,
                type: "is.workflow.actions.alert",
                parameters: [
                    "WFAlertActionTitle": "Flight Detected",
                    "WFAlertActionMessage": promptMessage,
                    "WFAlertActionCancelButtonShown": true
                ]
            ))
        }
        
        if configuration.carrier.requiresAppForForwarding {
            actions.append(ShortcutAction(
                identifier: UUID().uuidString,
                type: "is.workflow.actions.openurl",
                parameters: ["WFURLActionURL": "https://fi.google.com/account#phoneusage"]
            ))
            
            actions.append(ShortcutAction(
                identifier: UUID().uuidString,
                type: "is.workflow.actions.alert",
                parameters: [
                    "WFAlertActionTitle": "Google Fi",
                    "WFAlertActionMessage": "Please enable call forwarding to \(configuration.forwardingNumber) in the Google Fi app or website."
                ]
            ))
        } else {
            let forwardingCode = configuration.carrier.formatForwardingNumber(configuration.forwardingNumber)
            
            actions.append(ShortcutAction(
                identifier: UUID().uuidString,
                type: "is.workflow.actions.openurl",
                parameters: ["WFURLActionURL": "tel:\(forwardingCode)"]
            ))
            
            actions.append(ShortcutAction(
                identifier: UUID().uuidString,
                type: "is.workflow.actions.notification",
                parameters: [
                    "WFNotificationActionTitle": "Call Forwarding Active",
                    "WFNotificationActionBody": "Calls are being forwarded to \(configuration.forwardingNumber). To disable, dial \(configuration.carrier.disableCode)"
                ]
            ))
        }
        
        actions.append(ShortcutAction(
            identifier: UUID().uuidString,
            type: "is.workflow.actions.setvariable",
            parameters: [
                "WFVariableName": "ForwardingActive",
                "WFInput": ["Value": "true", "WFSerializationType": "WFTextTokenString"]
            ]
        ))
        
        return actions
    }
    
    private func createPromptMessage() -> String {
        switch configuration.promptStyle {
        case .minimal:
            return "Enable call forwarding to \(configuration.forwardingNumber)?"
        case .detailed:
            return "Flight detected! Would you like to forward calls to \(configuration.forwardingNumber)? You can disable forwarding later by dialing \(configuration.carrier.disableCode)."
        case .silent:
            return ""
        }
    }
    
    private func convertToINShortcut(_ shortcut: ShortcutFile) -> INShortcut? {
        return nil
    }
}

struct ShortcutFile {
    let name: String
    let actions: [ShortcutAction]
    let clientVersion: String
}

struct ShortcutAction {
    let identifier: String
    let type: String
    let parameters: [String: Any]
    let outputUUID: String?
    
    init(identifier: String, type: String, parameters: [String: Any], outputUUID: String? = nil) {
        self.identifier = identifier
        self.type = type
        self.parameters = parameters
        self.outputUUID = outputUUID
    }
}