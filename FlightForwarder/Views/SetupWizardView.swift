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
    
    let steps = ["Carrier", "Phone Number", "Detection", "Preferences", "Review"]
    
    var body: some View {
        NavigationView {
            VStack {
                ProgressBar(currentStep: currentStep, totalSteps: steps.count)
                    .padding(.horizontal)
                    .padding(.top)
                
                TabView(selection: $currentStep) {
                    CarrierSelectionStep(selectedCarrier: $selectedCarrier)
                        .tag(0)
                    
                    PhoneNumberStep(forwardingNumber: $forwardingNumber)
                        .tag(1)
                    
                    DetectionMethodsStep(selectedMethods: $selectedDetectionMethods)
                        .tag(2)
                    
                    PreferencesStep(
                        internationalBehavior: $internationalBehavior,
                        promptStyle: $promptStyle
                    )
                    .tag(3)
                    
                    ReviewStep(
                        carrier: selectedCarrier,
                        forwardingNumber: forwardingNumber,
                        detectionMethods: selectedDetectionMethods,
                        internationalBehavior: internationalBehavior,
                        promptStyle: promptStyle
                    )
                    .tag(4)
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
        case 1:
            return configurationManager.validatePhoneNumber(forwardingNumber)
        case 2:
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
            promptStyle: promptStyle
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Select Your Carrier")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if let detected = configurationManager.detectedCarrier {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Detected: \(detected.rawValue)")
                        .fontWeight(.medium)
                }
                .padding(.horizontal)
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(CarrierType.allCases, id: \.self) { carrier in
                        CarrierRow(
                            carrier: carrier,
                            isSelected: selectedCarrier == carrier,
                            action: { selectedCarrier = carrier }
                        )
                    }
                }
                .padding(.horizontal)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Forwarding Number")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text("Enter the phone number where calls should be forwarded when you're traveling")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                HStack {
                    TextField("Phone number", text: $forwardingNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: { showingContactPicker = true }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                
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
            
            InfoCard(text: "This number will receive your calls when forwarding is active. Common options include voicemail, assistant, or family member.")
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
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

struct SetupWizardView_Previews: PreviewProvider {
    static var previews: some View {
        SetupWizardView()
            .environmentObject(ConfigurationManager())
    }
}