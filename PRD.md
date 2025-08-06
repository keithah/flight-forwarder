# Flight Forwarder - Product Requirements Document

## Project Overview

Create an open source iOS app that generates custom Apple Shortcuts for intelligent call forwarding based on flight detection. The app handles complex configuration through a native iOS interface, then exports a simple, personalized shortcut tailored to each user's specific needs.

## Core Concept

Instead of building one complex shortcut that works for everyone, create an app that generates simple, customized shortcuts based on user preferences. This eliminates setup complexity while providing professional UX.

## Key Features

### Smart Configuration
- **Automatic carrier detection** (Verizon, AT&T, T-Mobile, Google Fi, Visible, Mint Mobile)
- **Phone number validation** with country code support
- **Multiple flight detection methods:**
  - Calendar events (flight keywords, airline codes)
  - Location detection (airports) 
  - Apple Wallet boarding passes

### Personalized Export
- Generates shortcuts with **10-20 actions** instead of 100+
- Carrier-specific forwarding codes
- No dependencies after generation
- Works on any iOS device with Shortcuts app

### Privacy First
- All processing happens locally on device
- No analytics or telemetry
- No internet connection required

## Technical Requirements

| Requirement | Specification |
|-------------|---------------|
| **Platform** | iOS 15.0+ |
| **Framework** | SwiftUI for modern UI |
| **Architecture** | MVVM pattern |
| **Dependencies** | None (use only iOS built-in frameworks) |
| **Distribution** | Open source |

## Core Components

### Models
- **CarrierType enum** with forwarding codes
- **UserConfiguration** for storing preferences
- **Flight detection logic**

### Views
- Welcome/onboarding flow
- Setup wizard (carrier, phone, preferences)
- Preview screen showing generated shortcut
- Export screen with sharing options
- Settings for configuration changes

### Core Logic
- **CarrierDetection** using Core Telephony
- **ConfigurationManager** for UserDefaults
- **ShortcutGenerator** for creating plist files

## Flight Detection Methods

### 📅 Calendar Scanning
- **Keywords:** "flight", "departure", "arrival", "boarding", "gate", "terminal"
- **Flight Numbers:** Regex pattern `[A-Z]{2}[0-9]{1,4}` (e.g., "AA1234", "DL567")
- **Airlines:** Major carrier names and codes  
- **International Detection:** Country names, "international" keyword, long flight durations

### 📍 Location Detection
- **Airport Categories:** Use MapKit to detect "Airport" point of interest category
- **Address Keywords:** "airport", "terminal", "gate", "departure", "arrival"
- **Proximity:** Within reasonable distance of known airport coordinates

### 💳 Apple Wallet
- Boarding pass detection
- Flight information extraction
- Multi-leg journey support

## Carrier Support

| Carrier | Enable Code | Disable Code | Status |
|---------|-------------|--------------|--------|
| **Verizon/Visible** | `*72[number]` | `*73` | ✅ Supported |
| **AT&T/T-Mobile/Mint** | `**21*[number]#` | `##21#` | ✅ Supported |
| **Google Fi** | App/Website | App/Website | ⚠️ Limited Support |

## User Flow

### 1. First Launch
- **Welcome screen** explaining the concept
- **Setup wizard** collects:
  - Confirms auto-detected carrier
  - Validates forwarding phone number
  - Selects detection methods
  - Chooses preferences (international detection, notification settings)

### 2. Export Process
- **Preview screen** shows exactly what the shortcut will do
- **Export** generates personalized `.shortcut` file
- **Share sheet** allows saving to Files or opening in Shortcuts
- **Instructions screen** helps user import and set up automation

### 3. Settings
- Modify any configuration
- Re-export updated shortcut
- Reset to defaults option

## Generated Shortcut Logic

The exported shortcut should contain only the necessary actions for that specific user:

1. **Check current time** (if user enabled time-based detection)
2. **Get calendar events** for today (if user enabled calendar detection)
3. **Get current location** (if user enabled location detection) 
4. **Check Apple Wallet** (if user enabled wallet detection)
5. **Look for flight indicators** using user's selected methods
6. **If flight detected:**
   - Get confirmation from user
   - Enable call forwarding using user's carrier code
   - Show success notification
7. **Else:**
   - Show "no flight detected" message

> 🎯 **Key Innovation:** Each exported shortcut contains only 10-20 actions tailored to that user's carrier and preferences, instead of 100+ actions trying to handle every possible scenario.

## Architecture Notes

### MVVM Pattern
- **Models:** Data structures and business logic
- **Views:** SwiftUI interface
- **ViewModels:** Binding between models and views

### Local-First Design
- Use **UserDefaults** for configuration
- Use **Core Telephony** for carrier detection
- Use **PropertyListSerialization** for shortcut export
- **No network requests** or external dependencies

### Error Handling
- **Graceful degradation** if permissions denied
- **Clear error messages** for users
- **Fallback options** when auto-detection fails

## Success Metrics

### Technical Goals
- ✅ Clean compilation with zero warnings
- ✅ Sub-second export generation
- ✅ 100% local processing (no network calls)
- ✅ Memory usage under 50MB

### User Experience Goals
- ⏱️ Setup completion in under 2 minutes
- 🎯 Generated shortcuts work on first try
- 📱 Intuitive interface requiring no documentation
- 🔒 Zero data leaves the device

## Future Enhancements

### Phase 2 Features
- [ ] **International carrier support**
- [ ] **Multiple forwarding numbers**
- [ ] **Scheduled forwarding** (time-based rules)
- [ ] **Integration with other travel apps**

### Phase 3 Features
- [ ] **watchOS companion app**
- [ ] **Siri Shortcuts integration**
- [ ] **Advanced flight detection** (airline APIs)
- [ ] **Group/family management**

---

*This PRD serves as the complete specification for the Flight Forwarder iOS app, defining all requirements, features, and technical implementation details.*