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
    
    let steps = [
        SetupStep(
            title: "Check Google Voice Settings",
            instruction: "First, we need to ensure Google Voice can make calls over Wi-Fi",
            icon: "gear",
            action: .checkSettings
        ),
        SetupStep(
            title: "Open Google Voice",
            instruction: "We'll open Google Voice where you can find your number",
            icon: "globe",
            action: .openWebView
        ),
        SetupStep(
            title: "Find Your Number",
            instruction: "Look for your Google Voice number at the top of the page or in Settings",
            icon: "magnifyingglass",
            action: .showGuide
        ),
        SetupStep(
            title: "Copy Your Number",
            instruction: "Long press on your number and select 'Copy'",
            icon: "doc.on.doc",
            action: .waitForCopy
        ),
        SetupStep(
            title: "Paste & Verify",
            instruction: "Paste your Google Voice number below",
            icon: "checkmark.circle",
            action: .pasteNumber
        )
    ]
    
    struct SetupStep {
        let title: String
        let instruction: String
        let icon: String
        let action: StepAction
        
        enum StepAction {
            case checkSettings
            case openWebView
            case showGuide
            case waitForCopy
            case pasteNumber
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(steps.count))
                    .padding()
                
                if !showWebView {
                    // Step content
                    VStack(spacing: 24) {
                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding()
                        
                        Text(steps[currentStep].title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(steps[currentStep].instruction)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if currentStep == 0 {
                            // Google Voice settings guide
                            GoogleVoiceSettingsGuide()
                                .padding()
                        }
                        
                        if currentStep == 2 {
                            // Visual guide for finding the number
                            GoogleVoiceGuideView()
                                .padding()
                        }
                        
                        if currentStep == 4 {
                            // Paste field
                            VStack(spacing: 16) {
                                HStack {
                                    TextField("Paste your Google Voice number", text: $copiedNumber)
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
                            .disabled(currentStep == 3 && !isValidGoogleVoiceNumber(copiedNumber))
                            
                            // Show app option on first step if available
                            if currentStep == 0 && googleVoiceAppAvailable {
                                Button(action: openGoogleVoiceSettings) {
                                    HStack {
                                        Image(systemName: "gear")
                                        Text("Open Google Voice Settings")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            } else if currentStep == 1 && googleVoiceAppAvailable {
                                Button(action: openGoogleVoiceApp) {
                                    HStack {
                                        Image(systemName: "arrow.up.forward.app")
                                        Text("Open in Google Voice App")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            }
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
                                currentStep = 3
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
        switch steps[currentStep].action {
        case .checkSettings:
            return "I've Enabled Wi-Fi Calling"
        case .openWebView:
            return "Open Google Voice"
        case .showGuide:
            return "Continue"
        case .waitForCopy:
            return "I've Copied My Number"
        case .pasteNumber:
            return "Use This Number"
        }
    }
    
    func handleStepAction() {
        switch steps[currentStep].action {
        case .checkSettings:
            currentStep += 1
        case .openWebView:
            showWebView = true
        case .showGuide:
            currentStep += 1
        case .waitForCopy:
            currentStep += 1
            checkClipboard()
        case .pasteNumber:
            if isValidGoogleVoiceNumber(copiedNumber) {
                forwardingNumber = formatPhoneNumber(copiedNumber)
                isPresented = false
            }
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
                    // Move to copy step since user will find number in app
                    currentStep = 3
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

struct GoogleVoiceSetupView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleVoiceSetupView(
            forwardingNumber: .constant(""),
            isPresented: .constant(true)
        )
    }
}