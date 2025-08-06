import SwiftUI

struct ContentView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @State private var showingSetupWizard = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack {
                if configurationManager.configuration.isValid {
                    MainView()
                } else {
                    WelcomeView(showingSetupWizard: $showingSetupWizard)
                }
            }
            .navigationTitle("Flight Forwarder")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if configurationManager.configuration.isValid {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSetupWizard) {
                SetupWizardView()
                    .environmentObject(configurationManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(configurationManager)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MainView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @State private var showingPreview = false
    @State private var showingExport = false
    
    var body: some View {
        VStack(spacing: 24) {
            ConfigurationSummaryCard()
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button(action: { showingPreview = true }) {
                    Label("Preview Shortcut", systemImage: "eye.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: { showingExport = true }) {
                    Label("Export Shortcut", systemImage: "square.and.arrow.up.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HelpSection()
                .padding()
        }
        .sheet(isPresented: $showingPreview) {
            PreviewView()
                .environmentObject(configurationManager)
        }
        .sheet(isPresented: $showingExport) {
            ExportView()
                .environmentObject(configurationManager)
        }
    }
}

struct ConfigurationSummaryCard: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    
    var config: UserConfiguration {
        configurationManager.configuration
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Configuration")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("Carrier: \(config.carrier.rawValue)")
                }
                
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("Forward to: \(config.forwardingNumber)")
                }
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    Text("Detection: \(config.detectionMethods.map { $0.rawValue }.joined(separator: ", "))")
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: "airplane")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    Text("International: \(config.internationalBehavior.rawValue)")
                }
            }
            .font(.system(.body, design: .rounded))
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct HelpSection: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Need Help?")
                .font(.headline)
            
            Text("After exporting your shortcut, you can set up automations in the Shortcuts app to run it automatically when you arrive at airports.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ConfigurationManager())
    }
}