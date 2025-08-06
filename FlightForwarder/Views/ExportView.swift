import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Environment(\.dismiss) var dismiss
    @State private var exportState: ExportState = .ready
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    @State private var errorMessage = ""
    
    enum ExportState {
        case ready, exporting, success, error
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                switch exportState {
                case .ready:
                    readyView
                case .exporting:
                    exportingView
                case .success:
                    successView
                case .error:
                    errorView
                }
            }
            .padding()
            .navigationTitle("Export Shortcut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(exportState == .exporting)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    var readyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Ready to Export")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your custom shortcut is ready to be exported to the Shortcuts app")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: exportShortcut) {
                    Label("Export Shortcut", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Text("The shortcut will be saved to your Files app and can be imported into Shortcuts")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    var exportingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Generating Shortcut...")
                .font(.headline)
            
            Text("Creating your personalized shortcut with \(configurationManager.configuration.detectionMethods.count) detection methods")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    var successView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Export Successful!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your shortcut has been created")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: { showingShareSheet = true }) {
                    Label("Share Shortcut", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Next Steps:")
                        .font(.headline)
                    
                    NextStepRow(number: 1, text: "Tap 'Share Shortcut' above")
                    NextStepRow(number: 2, text: "Choose 'Save to Files' or 'Open in Shortcuts'")
                    NextStepRow(number: 3, text: "In Shortcuts app, tap the shortcut to test it")
                    NextStepRow(number: 4, text: "Set up automation for airports (optional)")
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("Export Failed")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: { exportState = .ready }) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
    
    func exportShortcut() {
        exportState = .exporting
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            do {
                let generator = ShortcutGenerator(configuration: configurationManager.configuration)
                let shortcutData = try generateShortcutData(generator: generator)
                
                let fileName = "FlightForwarder_\(Date().formatted(.dateTime.year().month().day())).shortcut"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                try shortcutData.write(to: tempURL)
                
                exportedFileURL = tempURL
                exportState = .success
            } catch {
                errorMessage = "Failed to generate shortcut: \(error.localizedDescription)"
                exportState = .error
            }
        }
    }
    
    func generateShortcutData(generator: ShortcutGenerator) throws -> Data {
        let shortcutDict: [String: Any] = [
            "WFWorkflowName": "Flight Call Forwarding",
            "WFWorkflowActions": [],
            "WFWorkflowClientVersion": "1230.1"
        ]
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return try PropertyListSerialization.data(fromPropertyList: shortcutDict, format: .binary, options: 0)
    }
    
    func createMockActions() -> [ShortcutAction] {
        return [
            ShortcutAction(
                identifier: UUID().uuidString,
                type: "is.workflow.actions.comment",
                parameters: ["WFCommentActionText": "Generated by Flight Forwarder"]
            )
        ]
    }
}

struct NextStepRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportView()
            .environmentObject(ConfigurationManager())
    }
}