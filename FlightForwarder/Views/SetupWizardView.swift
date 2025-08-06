import SwiftUI

struct SetupWizardView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var selectedCarrier: CarrierType = .verizon
    @State private var forwardingNumber = ""
    @State private var selectedDetectionMethods: Set<DetectionMethod> = [.calendar, .location]
    @State private var internationalBehavior: InternationalOptions = .alwaysForward
    @State private var promptStyle: PromptPreferences = .detailed
    @State private var disableOption: DisableForwardingOption = .automatic
    
    let steps = ["SIM Status", "Carrier", "Phone Number", "Detection", "Preferences", "Disable Options", "Review"]
    
    var body: some View {
        NavigationView {
            VStack {
                ProgressBar(currentStep: currentStep, totalSteps: steps.count)
                    .padding(.horizontal)
                    .padding(.top)
                
                TabView(selection: $currentStep) {
                    SIMStatusStep()
                        .tag(0)
                    
                    CarrierSelectionStep(selectedCarrier: $selectedCarrier)
                        .tag(1)
                    
                    PhoneNumberStep(forwardingNumber: $forwardingNumber)
                        .tag(2)
                    
                    DetectionMethodsStep(selectedMethods: $selectedDetectionMethods)
                        .tag(3)
                    
                    PreferencesStep(
                        internationalBehavior: $internationalBehavior,
                        promptStyle: $promptStyle
                    )
                    .tag(4)
                    
                    DisableOptionsStep(disableOption: $disableOption)
                        .tag(5)
                    
                    ReviewStep(
                        carrier: selectedCarrier,
                        forwardingNumber: forwardingNumber,
                        detectionMethods: selectedDetectionMethods,
                        internationalBehavior: internationalBehavior,
                        promptStyle: promptStyle,
                        disableOption: disableOption
                    )
                    .tag(6)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    Button(currentStep < steps.count - 1 ? "Next" : "Complete") {
                        // Dismiss keyboard before transitioning
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        if currentStep < steps.count - 1 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            completeSetup()
                        }
                    }
                    .disabled(!isCurrentStepValid)
                    .padding()
                }
            }
            .navigationTitle("Setup Wizard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let detectedCarrier = configurationManager.detectedCarrier {
                    selectedCarrier = detectedCarrier
                }
            }
        }
    }
    
    var isCurrentStepValid: Bool {
        switch currentStep {
        case 2: // Phone Number step
            return configurationManager.validatePhoneNumber(forwardingNumber)
        case 3: // Detection methods step
            return !selectedDetectionMethods.isEmpty
        default:
            return true
        }
    }
    
    func completeSetup() {
        let formattedNumber = configurationManager.formatPhoneNumber(forwardingNumber)
        let config = UserConfiguration(
            carrier: selectedCarrier,
            forwardingNumber: formattedNumber,
            detectionMethods: selectedDetectionMethods,
            internationalBehavior: internationalBehavior,
            promptStyle: promptStyle,
            disableOption: disableOption
        )
        configurationManager.update(configuration: config)
        dismiss()
    }
}

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 4)
                    .cornerRadius(2)
                    .animation(.easeInOut, value: currentStep)
            }
        }
        .frame(height: 4)
    }
}

struct CarrierSelectionStep: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Binding var selectedCarrier: CarrierType
    @State private var showManualSelection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Select Your Carrier")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if let detected = configurationManager.detectedCarrier {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: configurationManager.carrierConfidence == .high ? "checkmark.circle.fill" : 
                              configurationManager.detectedCarrierName == "Wi-Fi Calling Active" ? "wifi" :
                              configurationManager.detectedCarrierName == "Detection Failed" ? "exclamationmark.triangle.fill" : "questionmark.circle.fill")
                            .foregroundColor(configurationManager.carrierConfidence == .high ? .green : 
                                           configurationManager.detectedCarrierName == "Wi-Fi Calling Active" ? .blue :
                                           configurationManager.detectedCarrierName == "Detection Failed" ? .red : .orange)
                        VStack(alignment: .leading) {
                            if configurationManager.detectedCarrierName == "Wi-Fi Calling Active" {
                                Text("Wi-Fi Calling Detected")
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                Text("Wi-Fi calling is blocking carrier detection. Please select your carrier manually below.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if configurationManager.detectedCarrierName == "Detection Failed" {
                                Text("Carrier Detection Failed")
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                Text("Please select your carrier manually below")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Detected: \(detected.rawValue)")
                                    .fontWeight(.medium)
                                if let detectedName = configurationManager.detectedCarrierName {
                                    Text("Network: \(detectedName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    if configurationManager.carrierConfidence != .high {
                        Button("Not correct? Select manually") {
                            showManualSelection = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            if showManualSelection || configurationManager.detectedCarrier == nil || configurationManager.carrierConfidence == .low || configurationManager.detectedCarrierName == "Detection Failed" || configurationManager.detectedCarrierName == "Wi-Fi Calling Active" {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(CarrierType.allCases, id: \.self) { carrier in
                            CarrierRow(
                                carrier: carrier,
                                isSelected: selectedCarrier == carrier,
                                action: { 
                                    selectedCarrier = carrier
                                    showManualSelection = false
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            } else if configurationManager.carrierConfidence == .high {
                // High confidence - just show the selected carrier
                VStack {
                    CarrierRow(
                        carrier: selectedCarrier,
                        isSelected: true,
                        action: {}
                    )
                    .padding(.horizontal)
                    
                    Button("Choose a different carrier") {
                        showManualSelection = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                }
            }
            
            if selectedCarrier.requiresAppForForwarding {
                InfoCard(text: selectedCarrier.instructions)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct CarrierRow: View {
    let carrier: CarrierType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(carrier.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Forwarding: \(carrier.forwardingCode)X | Disable: \(carrier.disableCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PhoneNumberStep: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Binding var forwardingNumber: String
    @State private var showingContactPicker = false
    @State private var showingGoogleVoiceSetup = false
    @State private var useGoogleVoice = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Forwarding Number")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text("Choose where to forward your calls while traveling")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 20) {
                // Google Voice option
                Button(action: { 
                    useGoogleVoice = true
                    showingGoogleVoiceSetup = true 
                }) {
                    HStack {
                        Image(systemName: "phone.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Use Google Voice")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Forward calls to your Google Voice number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(useGoogleVoice ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(useGoogleVoice ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal)
                
                // Manual entry option
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter manually")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    HStack {
                        TextField("Phone number", text: $forwardingNumber)
                            .keyboardType(.phonePad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(useGoogleVoice)
                            .opacity(useGoogleVoice ? 0.5 : 1.0)
                            .onChange(of: forwardingNumber) { _ in
                                if !forwardingNumber.isEmpty {
                                    useGoogleVoice = false
                                }
                            }
                        
                        Button(action: { showingContactPicker = true }) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                        }
                        .disabled(useGoogleVoice)
                        .opacity(useGoogleVoice ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)
                }
                
                if !forwardingNumber.isEmpty {
                    HStack {
                        if configurationManager.validatePhoneNumber(forwardingNumber) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Valid format")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Please enter a valid phone number")
                                .foregroundColor(.red)
                        }
                        Spacer()
                    }
                    .font(.caption)
                    .padding(.horizontal)
                }
            }
            
            InfoCard(text: useGoogleVoice ? "Google Voice provides a unified number that works across all your devices." : "This number will receive your calls when forwarding is active. Common options include voicemail, assistant, or family member.")
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .sheet(isPresented: $showingGoogleVoiceSetup) {
            GoogleVoiceSetupView(
                forwardingNumber: $forwardingNumber,
                isPresented: $showingGoogleVoiceSetup
            )
        }
        .onChange(of: forwardingNumber) { newValue in
            if !newValue.isEmpty && useGoogleVoice {
                // User completed Google Voice setup
                useGoogleVoice = true
            }
        }
    }
}

struct DetectionMethodsStep: View {
    @Binding var selectedMethods: Set<DetectionMethod>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Detection Methods")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text("Choose how the shortcut will detect your flights")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(DetectionMethod.allCases, id: \.self) { method in
                    DetectionMethodRow(
                        method: method,
                        isSelected: selectedMethods.contains(method),
                        action: {
                            if selectedMethods.contains(method) {
                                selectedMethods.remove(method)
                            } else {
                                selectedMethods.insert(method)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            
            InfoCard(text: "Using multiple detection methods increases accuracy but may require additional permissions.")
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
}

struct DetectionMethodRow: View {
    let method: DetectionMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: method.systemImageName)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(method.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PreferencesStep: View {
    @Binding var internationalBehavior: InternationalOptions
    @Binding var promptStyle: PromptPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Preferences")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("International Flights")
                        .font(.headline)
                    
                    ForEach(InternationalOptions.allCases, id: \.self) { option in
                        RadioButton(
                            title: option.rawValue,
                            description: option.description,
                            isSelected: internationalBehavior == option,
                            action: { internationalBehavior = option }
                        )
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prompt Style")
                        .font(.headline)
                    
                    ForEach(PromptPreferences.allCases, id: \.self) { style in
                        RadioButton(
                            title: style.rawValue,
                            description: style.description,
                            isSelected: promptStyle == style,
                            action: { promptStyle = style }
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
}

struct RadioButton: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReviewStep: View {
    let carrier: CarrierType
    let forwardingNumber: String
    let detectionMethods: Set<DetectionMethod>
    let internationalBehavior: InternationalOptions
    let promptStyle: PromptPreferences
    let disableOption: DisableForwardingOption
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Review Configuration")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    ReviewRow(label: "Carrier", value: carrier.rawValue)
                    ReviewRow(label: "Forward to", value: forwardingNumber)
                    ReviewRow(label: "Detection", value: detectionMethods.map { $0.rawValue }.joined(separator: ", "))
                    ReviewRow(label: "International", value: internationalBehavior.rawValue)
                    ReviewRow(label: "Prompts", value: promptStyle.rawValue)
                    ReviewRow(label: "Disable", value: disableOption.rawValue)
                }
                
                InfoCard(text: "After completing setup, you'll be able to preview and export your custom shortcut.")
                
                Spacer(minLength: 40)
            }
            .padding()
        }
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .fontWeight(.medium)
            Spacer()
        }
    }
}

struct InfoCard: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DisableOptionsStep: View {
    @Binding var disableOption: DisableForwardingOption
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Disable Forwarding")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text("Choose when to automatically disable call forwarding after your trip")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(DisableForwardingOption.allCases, id: \.self) { option in
                    RadioButton(
                        title: option.rawValue,
                        description: option.description,
                        isSelected: disableOption == option,
                        action: { disableOption = option }
                    )
                }
            }
            .padding(.horizontal)
            
            InfoCard(text: "Automatic options help ensure you don't miss calls after returning from your trip. You can always manually disable forwarding anytime.")
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
}

struct SIMStatusStep: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("SIM Status Check")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                if let simStatus = configurationManager.simStatus {
                    VStack(alignment: .leading, spacing: 20) {
                        // Status card
                        HStack {
                            Image(systemName: simStatus.isUnlocked ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.title)
                                .foregroundColor(simStatus.isUnlocked ? .green : .orange)
                            
                            VStack(alignment: .leading) {
                                Text(simStatus.isUnlocked ? "SIM Unlocked" : "SIM Status Unknown")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                if simStatus.isDualSIM {
                                    Text("Dual SIM Capable")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Main message
                        VStack(alignment: .leading, spacing: 16) {
                            Text(configurationManager.simDetector.getUnlockMessage(status: simStatus))
                                .font(.body)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            
                            // Technical details (collapsible)
                            DisclosureGroup("Technical Details") {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("SIM Slots: \(simStatus.simCount)")
                                        .font(.caption)
                                    
                                    if !simStatus.carriers.isEmpty {
                                        Text("Active Carriers: \(simStatus.carriers.joined(separator: ", "))")
                                            .font(.caption)
                                    }
                                    
                                    Text("Detection Confidence: \(simStatus.confidence == .high ? "High" : simStatus.confidence == .medium ? "Medium" : "Low")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal)
                            .font(.subheadline)
                        }
                    }
                } else {
                    // Loading state
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text("Checking SIM status...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                
                Spacer(minLength: 40)
            }
        }
        .onAppear {
            // Trigger detection if not already done
            if configurationManager.simStatus == nil {
                configurationManager.detectSIMStatus()
            }
        }
    }
}

struct SetupWizardView_Previews: PreviewProvider {
    static var previews: some View {
        SetupWizardView()
            .environmentObject(ConfigurationManager())
    }
}