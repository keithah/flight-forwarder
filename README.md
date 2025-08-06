# Flight Forwarder 🛫

An open-source iOS app that generates custom Apple Shortcuts for intelligent call forwarding based on flight detection.

![Flight Forwarder Welcome](screenshots/flightforwarder.png)

![Flight Forwarder Setup](screenshots/flightforward2.png)

## ⚠️ WORK IN PROGRESS

**🚧 This app is currently in development and has NOT been tested on real devices yet!**

- ❌ **Not tested on physical iPhone/iPad**
- ❌ **Shortcut generation not fully implemented**
- ❌ **Carrier detection needs real-world testing**
- ❌ **Call forwarding codes may need adjustment**
- ⚠️ **Use at your own risk - test thoroughly before relying on it**

## TODOs

### High Priority
- [ ] **Test on real iPhone devices** - Currently only built/tested in simulator
- [ ] **Implement proper shortcut file generation** - Export functionality is stubbed
- [ ] **Test carrier detection** with real SIM cards and carriers
- [ ] **Verify call forwarding codes** work with actual carriers
- [ ] **Add proper error handling** for edge cases
- [ ] **Test calendar/location/wallet detection** with real data
- [ ] **Test Google Voice integration** - WebView and app detection

### Medium Priority
- [ ] **Add app icon** and proper branding
- [ ] **Improve UI/UX** based on real device testing
- [ ] **Add unit tests** for core functionality
- [ ] **Add internationalization** support
- [ ] **Optimize for iPad** layouts
- [ ] **Add accessibility features**

### Low Priority
- [ ] **Add analytics** (privacy-respecting)
- [ ] **Create documentation** and user guides
- [ ] **Set up CI/CD** pipeline
- [ ] **Add crash reporting**
- [ ] **Performance optimizations**

## Overview

Flight Forwarder solves the complexity of creating advanced Apple Shortcuts by providing a native iOS app that generates simple, personalized shortcuts tailored to each user's specific carrier and preferences. Instead of distributing one complex shortcut that tries to work for everyone, this app creates streamlined shortcuts with only the necessary actions for each user.

## Key Features

### Smart Configuration
- **Multi-Layer Carrier Detection**: 
  - Primary: MNC codes and carrier names for reliable detection
  - Wi-Fi Calling Detection: Handles scenarios where Wi-Fi calling blocks carrier info
  - WHOIS Fallback: Last resort IP-based carrier detection via WHOIS lookup
- **SIM Status Detection**: Checks for unlocked SIM and dual SIM capability
- **Google Voice Integration**: Streamlined 3-step setup with Wi-Fi calling configuration
- **International Phone Support**: Supports international phone numbers with + prefix
- **Custom Carrier Support**: Manual entry for carriers not in predefined list
- **Multiple Flight Detection Methods**: 
  - Calendar events (flight keywords, airline codes)
  - Location detection (airports)
  - Apple Wallet boarding passes
- **Smart Disable Options**: Choose when to automatically disable forwarding after travel

### Personalized Export
- Generates shortcuts with 10-20 actions instead of 100+
- Carrier-specific forwarding codes
- No dependencies after generation
- Works on any iOS device with Shortcuts app

### Privacy First
- All processing happens locally on device
- No analytics or telemetry
- No internet connection required after setup
- Open source under AGPL v3 license
- Transparent device information in Settings

## Installation

### Requirements
- iOS 15.0+
- Xcode 15.0+ (for building from source)
- Apple Developer account (for device installation)

### From Source
1. Clone this repository
   ```bash
   git clone https://github.com/yourusername/flight-forwarder.git
   cd flight-forwarder
   ```

2. Open in Xcode
   ```bash
   open FlightForwarder.xcodeproj
   ```

3. Configure signing
   - Select your development team in Project Settings
   - Update bundle identifier if needed

4. Build and run on your device

## Usage

⚠️ **Note: These steps are theoretical - not yet tested on real devices!**

1. **Initial Setup**
   - Launch the app and check SIM status
   - Complete the 7-step setup wizard:
     - Review SIM status and unlock benefits
     - Confirm your carrier (auto-detected via multiple methods)
     - Enter forwarding phone number or set up Google Voice
     - Select detection methods (calendar, location, wallet)
     - Choose international behavior and prompt styles with examples
     - Configure automatic disable options
     - Review and complete setup

2. **Export Shortcut**
   - Preview your configuration
   - Tap "Export Shortcut"
   - Save to Files or open in Shortcuts
   - Import into Shortcuts app

3. **Set Up Automation** (Optional)
   - In Shortcuts app, create new Automation
   - Choose trigger (arrive at location, time, etc.)
   - Run your exported Flight Forwarder shortcut
   - Enable automation

## Carrier Support

| Carrier | Enable Code | Disable Code | Detection Method | Status |
|---------|------------|--------------|------------------|--------|
| Verizon | *72[number] | *73 | MNC code / WHOIS | ⚠️ Needs testing |
| AT&T | **21*[number]# | ##21# | MNC code / WHOIS | ⚠️ Needs testing |
| T-Mobile | **21*[number]# | ##21# | MNC code / WHOIS | ⚠️ Needs testing |
| Google Fi | App/Website | App/Website | Name / WHOIS | ⚠️ Needs testing |
| Visible | *72[number] | *73 | MNC code / WHOIS | ⚠️ Needs testing |
| Mint Mobile | **21*[number]# | ##21# | T-Mobile network | ⚠️ Needs testing |
| Other (Custom) | [Custom code] | [Custom code] | Manual entry | ⚠️ Needs testing |

### Carrier Detection Methods

**Primary Detection:**
- **MNC Code Mapping**: Uses Mobile Network Code for high-confidence detection
- **Carrier Name Matching**: Fallback using carrier name from SIM

**Advanced Detection:**
- **Wi-Fi Calling Detection**: Identifies when Wi-Fi calling blocks carrier info
- **WHOIS IP Lookup**: Last resort method using cellular IP and WHOIS databases
- **Dual SIM Support**: Detects carriers on both SIM slots

**Detection Flow:**
1. Try MNC code mapping (highest confidence)
2. Try carrier name matching 
3. Check for Wi-Fi calling interference
4. Fallback to WHOIS IP lookup (cellular interface → IP → carrier ownership)
5. Show technical details for troubleshooting

## Architecture

### Project Structure
```
FlightForwarder/
├── Models/
│   ├── CarrierType.swift          # Carrier definitions and codes
│   └── UserConfiguration.swift   # User settings model
├── Views/
│   ├── ContentView.swift         # Main navigation
│   ├── WelcomeView.swift         # First-time user onboarding
│   ├── SetupWizardView.swift     # 7-step configuration wizard
│   ├── GoogleVoiceSetupView.swift # Google Voice integration flow
│   ├── PreviewView.swift         # Show generated shortcut preview
│   ├── ExportView.swift          # Share shortcut with instructions
│   └── SettingsView.swift        # Device info and configuration
├── Core/
│   ├── ConfigurationManager.swift # Handle user preferences
│   ├── CarrierDetection.swift     # Automatic carrier detection via MNC
│   ├── SIMStatusDetector.swift    # SIM unlock and dual SIM detection
│   └── ShortcutGenerator.swift    # Generate shortcut actions
└── FlightForwarderApp.swift       # Main app entry point
```

### Technical Stack
- **SwiftUI** for modern, declarative UI
- **Core Telephony** for primary carrier detection
- **Network Framework** for advanced carrier detection
- **System Configuration** for network interface analysis
- **WHOIS Integration** for IP-based carrier lookup
- **UserDefaults** for storing user preferences
- **ShareSheet** for shortcut export
- **iOS 15+** for modern Shortcuts features

## Flight Detection Methods

### Calendar Scanning
- Keywords: "flight", "departure", "arrival", "boarding", "gate", "terminal"
- Flight Numbers: Regex pattern [A-Z]{2}[0-9]{1,4} (e.g., "AA1234", "DL567")
- Airlines: Major carrier names and codes
- International Detection: Country names, "international" keyword, long flight durations

### Location Detection
- Airport Categories: Use MapKit to detect "Airport" point of interest category
- Address Keywords: "airport", "terminal", "gate", "departure", "arrival"
- Proximity: Within reasonable distance of known airport coordinates

### Apple Wallet
- Boarding pass detection
- Flight information extraction
- Multi-leg journey support

## Contributing

🚧 **This project is in early development!** Contributions are welcome, especially:

- **Real device testing** and bug reports
- **Carrier code verification** for different providers
- **UI/UX improvements** based on actual usage
- **Additional carrier support**
- **Internationalization**
- **Documentation improvements**

### Development Setup
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Disclaimer

⚠️ **IMPORTANT**: This app is experimental and unfinished. Do not rely on it for critical travel situations without thorough testing. Call forwarding can interfere with important calls, and this app may not work as expected.

- Test thoroughly in a safe environment first
- Verify call forwarding codes work with your specific carrier
- Have backup plans for important calls during travel
- The developers are not responsible for missed calls or carrier charges

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Apple Shortcuts team for the powerful automation framework
- Business travelers who provided the initial use case
- Contributors and testers from the iOS community
- Envisioned by @keithah, written by Claude via Claude Code

---

**Made with ❤️ for the iOS community** (but not tested yet! 😅)

⚠️ **Remember: This is a work in progress - test everything before depending on it!**