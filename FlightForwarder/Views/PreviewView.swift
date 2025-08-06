import SwiftUI

struct PreviewView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Shortcut Preview")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Text("This is what your personalized shortcut will do:")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        PreviewStepCard(
                            stepNumber: 1,
                            title: "Flight Detection",
                            description: detectionDescription,
                            icon: "magnifyingglass"
                        )
                        
                        PreviewStepCard(
                            stepNumber: 2,
                            title: "User Confirmation",
                            description: confirmationDescription,
                            icon: "questionmark.circle"
                        )
                        
                        PreviewStepCard(
                            stepNumber: 3,
                            title: "Call Forwarding",
                            description: forwardingDescription,
                            icon: "phone.arrow.right"
                        )
                        
                        PreviewStepCard(
                            stepNumber: 4,
                            title: "Confirmation",
                            description: "You'll receive a notification confirming forwarding is active",
                            icon: "checkmark.circle"
                        )
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Technical Details")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "Shortcut Actions", value: "~15-20 actions")
                            DetailRow(label: "Carrier Code", value: configuration.carrier.forwardingCode)
                            DetailRow(label: "Disable Code", value: configuration.carrier.disableCode)
                            DetailRow(label: "Dependencies", value: "None (standalone)")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    InfoCard(text: "The exported shortcut will work independently without this app installed.")
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    var configuration: UserConfiguration {
        configurationManager.configuration
    }
    
    var detectionDescription: String {
        let methods = configuration.detectionMethods.map { $0.rawValue }.joined(separator: ", ")
        return "The shortcut will check: \(methods)"
    }
    
    var confirmationDescription: String {
        switch configuration.promptStyle {
        case .minimal:
            return "Simple yes/no prompt"
        case .detailed:
            return "Detailed prompt with flight information"
        case .silent:
            return "No prompt (automatic forwarding)"
        }
    }
    
    var forwardingDescription: String {
        if configuration.carrier.requiresAppForForwarding {
            return "Opens \(configuration.carrier.rawValue) app/website for manual setup"
        } else {
            return "Dials \(configuration.carrier.formatForwardingNumber(configuration.forwardingNumber))"
        }
    }
}

struct PreviewStepCard: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                
                Text("\(stepNumber)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                    Text(title)
                        .font(.headline)
                }
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

struct PreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView()
            .environmentObject(ConfigurationManager())
    }
}