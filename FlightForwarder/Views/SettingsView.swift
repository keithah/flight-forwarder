import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Environment(\.dismiss) var dismiss
    @State private var showingResetAlert = false
    @State private var showingEditWizard = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Current Configuration") {
                    ConfigurationRow(label: "Carrier", value: configurationManager.configuration.carrier.rawValue)
                    ConfigurationRow(label: "Forwarding Number", value: configurationManager.configuration.forwardingNumber)
                    ConfigurationRow(label: "Detection Methods", value: configurationManager.configuration.detectionMethods.count == 1 ? "1 method" : "\(configurationManager.configuration.detectionMethods.count) methods")
                    ConfigurationRow(label: "Setup Date", value: configurationManager.configuration.setupDate.formatted(date: .abbreviated, time: .omitted))
                }
                
                Section("Device Information") {
                    if let simStatus = configurationManager.simStatus {
                        ConfigurationRow(
                            label: "SIM Status", 
                            value: simStatus.isUnlocked ? "Unlocked" : "Status Unknown"
                        )
                        
                        ConfigurationRow(
                            label: "Dual SIM", 
                            value: simStatus.isDualSIM ? "Yes (\(simStatus.simCount) slots)" : "No"
                        )
                        
                        if simStatus.confidence == .low {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SIM Status Note")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Text("Cannot determine if SIM is locked due to iOS privacy restrictions. Most carrier-sold phones are unlocked after contract completion.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else {
                        ConfigurationRow(label: "SIM Status", value: "Checking...")
                    }
                    
                    if let detectedCarrier = configurationManager.detectedCarrier {
                        let detectionMethod = getCarrierDetectionMethod()
                        ConfigurationRow(label: "Detected Carrier", value: detectedCarrier.rawValue)
                        ConfigurationRow(label: "Detection Method", value: detectionMethod)
                        
                        let confidence = configurationManager.carrierConfidence
                        ConfigurationRow(
                            label: "Detection Confidence", 
                            value: confidence == .high ? "High" : confidence == .medium ? "Medium" : "Low"
                        )
                    } else {
                        ConfigurationRow(label: "Carrier Detection", value: "Failed")
                    }
                }
                
                Section("Actions") {
                    Button(action: { showingEditWizard = true }) {
                        Label("Edit Configuration", systemImage: "pencil.circle")
                    }
                    
                    Button(action: { showingResetAlert = true }) {
                        Label("Reset All Settings", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                Section("About") {
                    Link(destination: URL(string: "https://github.com/yourusername/flight-forwarder")!) {
                        Label("View on GitHub", systemImage: "link")
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("License")
                        Spacer()
                        Text("AGPL v3")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Envisioned by @keithah, written by Claude")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                        
                        Text("Privacy Notice")
                            .font(.headline)
                        Text("This app processes all data locally on your device. No information is sent to external servers. The generated shortcuts work independently without this app.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset All Settings?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    configurationManager.reset()
                    dismiss()
                }
            } message: {
                Text("This will delete your configuration and return to the welcome screen.")
            }
            .sheet(isPresented: $showingEditWizard) {
                SetupWizardView()
                    .environmentObject(configurationManager)
            }
        }
    }
    
    private func getCarrierDetectionMethod() -> String {
        guard let detectedName = configurationManager.detectedCarrierName else {
            return "Unknown"
        }
        
        if detectedName == "Wi-Fi Calling Active" {
            return "Wi-Fi calling blocked detection"
        } else if detectedName == "Detection Failed" {
            return "All methods failed"
        } else if configurationManager.carrierConfidence == .high {
            return "MNC code mapping"
        } else if configurationManager.carrierConfidence == .medium {
            return "Carrier name matching"
        } else {
            return "Manual selection required"
        }
    }
}

struct ConfigurationRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ConfigurationManager())
    }
}