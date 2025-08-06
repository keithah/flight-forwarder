import SwiftUI

struct WelcomeView: View {
    @Binding var showingSetupWizard: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Welcome to\nFlight Forwarder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Generate custom shortcuts for intelligent call forwarding based on your flights")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "wand.and.stars",
                    title: "Simple Setup",
                    description: "Configure once, export a personalized shortcut"
                )
                
                FeatureRow(
                    icon: "airplane.departure",
                    title: "Smart Detection",
                    description: "Automatically detect flights from calendar, location, or wallet"
                )
                
                FeatureRow(
                    icon: "lock.shield.fill",
                    title: "Privacy First",
                    description: "Open source, no tracking, works offline"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: { showingSetupWizard = true }) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(showingSetupWizard: .constant(false))
    }
}