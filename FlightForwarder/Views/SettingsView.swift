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
                        Text("MIT")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
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