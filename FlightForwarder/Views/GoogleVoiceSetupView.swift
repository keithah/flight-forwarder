import SwiftUI
import WebKit

struct GoogleVoiceSetupView: View {
    @Binding var forwardingNumber: String
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var showWebView = false
    @State private var copiedNumber = ""
    @State private var isValidating = false
    @State private var googleVoiceAppAvailable = false
    
    var currentStepSafe: Int {
        return min(max(currentStep, 0), steps.count - 1)
    }
    
    let steps = [
        SetupStep(
            title: "Open Google Voice",
            instruction: "We'll help you get your number and configure Wi-Fi calling",
            icon: "phone.circle",
            action: .openApp
        ),
        SetupStep(
            title: "Put Your Google Voice Number Here",
            instruction: "Enter your Google Voice number from the app or website",
            icon: "textformat.123",
            action: .enterNumber
        ),
        SetupStep(
            title: "Enable Wi-Fi Calling",
            instruction: "Find and enable 'Prefer Wi-Fi and mobile data' setting",
            icon: "wifi",
            action: .configureWiFi
        )
    ]
    
    struct SetupStep {
        let title: String
        let instruction: String
        let icon: String
        let action: StepAction
        
        enum StepAction {
            case openApp
            case enterNumber
            case configureWiFi
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStepSafe + 1), total: Double(steps.count))
                    .padding()
                
                if !showWebView {
                    // Step content
                    VStack(spacing: 24) {
                        Image(systemName: steps[currentStepSafe].icon)
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding()
                        
                        Text(steps[currentStepSafe].title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(steps[currentStepSafe].instruction)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if currentStep == 1 {
                            // Number entry field
                            VStack(spacing: 16) {
                                HStack {
                                    TextField("Enter your Google Voice number", text: $copiedNumber)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.phonePad)
                                    
                                    Button(action: pasteFromClipboard) {
                                        Image(systemName: "doc.on.clipboard")
                                            .font(.title2)
                                    }
                                }
                                .padding(.horizontal)
                                
                                if isValidating && !copiedNumber.isEmpty {
                                    HStack {
                                        if isValidGoogleVoiceNumber(copiedNumber) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Valid Google Voice number")
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
                        }
                        
                        if currentStep == 2 {
                            // Wi-Fi calling configuration guide
                            WiFiCallingGuide(hasApp: googleVoiceAppAvailable)
                                .padding()
                        }
                        
                        Spacer()
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button(action: handleStepAction) {
                                Text(actionButtonText)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .disabled(currentStep == 1 && !isValidGoogleVoiceNumber(copiedNumber))
                            
                        }
                    }
                    .padding(.vertical)
                } else {
                    // Web view with floating instructions
                    ZStack {
                        GoogleVoiceWebView(url: URL(string: "https://voice.google.com")!)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack {
                            // Floating instruction card
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Find and copy your Google Voice number")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(radius: 4)
                            )
                            .padding()
                            
                            Spacer()
                            
                            // Continue button
                            Button(action: {
                                showWebView = false
                                currentStep = 1  // Go to number entry step
                            }) {
                                Text("I've found my number")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Google Voice Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                checkClipboard()
                checkGoogleVoiceApp()
            }
        }
    }
    
    var actionButtonText: String {
        switch steps[currentStepSafe].action {
        case .openApp:
            return googleVoiceAppAvailable ? "Open Google Voice App" : "Open Google Voice Website"
        case .enterNumber:
            return "Use This Number"
        case .configureWiFi:
            return "I've Enabled Prefer Wi-Fi and Mobile Data"
        }
    }
    
    func handleStepAction() {
        switch steps[currentStepSafe].action {
        case .openApp:
            if googleVoiceAppAvailable {
                openGoogleVoiceApp()
            } else {
                showWebView = true
            }
            currentStep += 1
        case .enterNumber:
            if isValidGoogleVoiceNumber(copiedNumber) {
                forwardingNumber = formatPhoneNumber(copiedNumber)
                currentStep += 1
            }
        case .configureWiFi:
            isPresented = false
        }
    }
    
    func checkClipboard() {
        if UIPasteboard.general.hasStrings {
            if let clipboardText = UIPasteboard.general.string {
                let cleaned = clipboardText.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
                if isValidGoogleVoiceNumber(cleaned) {
                    copiedNumber = cleaned
                    isValidating = true
                }
            }
        }
    }
    
    func pasteFromClipboard() {
        checkClipboard()
        isValidating = true
    }
    
    func isValidGoogleVoiceNumber(_ number: String) -> Bool {
        let cleaned = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        // Check if it's a valid US phone number format
        if cleaned.hasPrefix("+1") && cleaned.count == 12 {
            return true
        } else if cleaned.hasPrefix("1") && cleaned.count == 11 {
            return true
        } else if cleaned.count == 10 {
            return true
        }
        
        return false
    }
    
    func formatPhoneNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        if cleaned.hasPrefix("+") {
            return cleaned
        } else if cleaned.count == 10 {
            return "+1\(cleaned)"
        } else if cleaned.count == 11 && cleaned.hasPrefix("1") {
            return "+\(cleaned)"
        }
        
        return cleaned
    }
    
    func checkGoogleVoiceApp() {
        // Check if Google Voice app is installed
        if let url = URL(string: "googlevoice://") {
            googleVoiceAppAvailable = UIApplication.shared.canOpenURL(url)
        }
    }
    
    func openGoogleVoiceApp() {
        if let url = URL(string: "googlevoice://") {
            UIApplication.shared.open(url) { success in
                if success {
                    // Move to number entry step since user will find number in app
                    currentStep = 1
                } else {
                    // Fallback to web view
                    showWebView = true
                }
            }
        }
    }
    
    func openGoogleVoiceSettings() {
        // Try to open Google Voice settings directly
        // Note: This URL scheme may not work, but we'll try it first
        if let url = URL(string: "googlevoice://settings") {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback to just opening the app
                    openGoogleVoiceApp()
                }
            }
        }
    }
}

struct GoogleVoiceSettingsGuide: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("Important Setting Required")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                
                Text("Google Voice must be configured to work over Wi-Fi for international travel.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Open Google Voice Settings")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("In the app: Menu → Settings → Calls")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Find \"Making & receiving calls\"")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Select \"Prefer Wi-Fi and mobile data\"")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("NOT \"Use carrier only\"")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("This allows calls over Wi-Fi when traveling")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct GoogleVoiceGuideView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Where to find your number:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.blue)
                    Text("At the top of the Google Voice page")
                        .font(.body)
                }
                
                HStack(alignment: .top) {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.blue)
                    Text("In Settings → Account")
                        .font(.body)
                }
                
                HStack(alignment: .top) {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(.blue)
                    Text("On the main dashboard")
                        .font(.body)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct GoogleVoiceWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: GoogleVoiceWebView
        
        init(_ parent: GoogleVoiceWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow Google Voice navigation
            if let url = navigationAction.request.url,
               url.host?.contains("google.com") == true {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }
    }
}

struct WiFiCallingGuide: View {
    let hasApp: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if hasApp {
                // Instructions for app users
                VStack(alignment: .leading, spacing: 16) {
                    Text("In the Google Voice app:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.blue)
                            Text("Tap Menu (☰) → Settings → Calls")
                                .font(.body)
                        }
                        
                        HStack(alignment: .top) {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.blue)
                            Text("Find 'Making & receiving calls'")
                                .font(.body)
                        }
                        
                        HStack(alignment: .top) {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Select 'Prefer Wi-Fi and mobile data'")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("NOT 'Use carrier only'")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                // Placeholder for video
                VStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                        .overlay(
                            VStack {
                                Image(systemName: "play.circle")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                Text("Video guide coming soon")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                        .cornerRadius(8)
                    Text("Video placeholder - will show step-by-step guide")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            } else {
                // Instructions for website users
                VStack(alignment: .leading, spacing: 16) {
                    Text("On the Google Voice website:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.blue)
                            Text("Click Settings (gear icon)")
                                .font(.body)
                        }
                        
                        HStack(alignment: .top) {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.blue)
                            Text("Go to 'Calls' tab")
                                .font(.body)
                        }
                        
                        HStack(alignment: .top) {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Under 'Making & receiving calls', choose:")
                                    .font(.body)
                                Text("'Prefer Wi-Fi and mobile data'")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            
            InfoCard(text: "This setting allows Google Voice to work over Wi-Fi when traveling internationally, ensuring you can receive forwarded calls.")
        }
    }
}

struct GoogleVoiceSetupView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleVoiceSetupView(
            forwardingNumber: .constant(""),
            isPresented: .constant(true)
        )
    }
}