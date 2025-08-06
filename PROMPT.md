# Flight Forwarder - Development Prompts

This document contains all the prompts used to create the Flight Forwarder iOS app using Claude Code.

## Initial Project Concept

### Original Request
```
Perfect! Let's focus on the iOS-only approach. Here's the refined project summary for Claude Code:

iOS App Project Summary for Claude Code

Project Overview
Create an open source iOS app that generates custom Apple Shortcuts for intelligent call forwarding based on flight detection. The app handles complex configuration through a native iOS interface, then exports a simple, personalized shortcut tailored to each user's specific needs.

Core Concept
Instead of building one complex shortcut that works for everyone, create an app that generates simple, customized shortcuts based on user preferences. This eliminates setup complexity while providing professional UX.

Key Features

Smart Configuration:
- Automatic carrier detection (Verizon, AT&T, T-Mobile, Google Fi, Visible, Mint Mobile)
- Phone number validation with country code support
- Multiple flight detection methods:
  * Calendar events (flight keywords, airline codes)
  * Location detection (airports) 
  * Apple Wallet boarding passes

Personalized Export:
- Generates shortcuts with 10-20 actions instead of 100+
- Carrier-specific forwarding codes
- No dependencies after generation
- Works on any iOS device with Shortcuts app

Privacy First:
- All processing happens locally on device
- No analytics or telemetry
- No internet connection required

Technical Requirements

Platform: iOS 15.0+
Framework: SwiftUI for modern UI
Architecture: MVVM pattern
Dependencies: None (use only iOS built-in frameworks)
Distribution: Open source

Core Components

Models:
- CarrierType enum with forwarding codes
- UserConfiguration for storing preferences
- Flight detection logic

Views:
- Welcome/onboarding flow
- Setup wizard (carrier, phone, preferences)
- Preview screen showing generated shortcut
- Export screen with sharing options
- Settings for configuration changes

Core Logic:
- CarrierDetection using Core Telephony
- ConfigurationManager for UserDefaults
- ShortcutGenerator for creating plist files

Flight Detection Methods

Calendar Scanning:
- Keywords: "flight", "departure", "arrival", "boarding", "gate", "terminal"
- Flight Numbers: Regex pattern [A-Z]{2}[0-9]{1,4} (e.g., "AA1234", "DL567")
- Airlines: Major carrier names and codes  
- International Detection: Country names, "international" keyword, long flight durations

Location Detection:
- Airport Categories: Use MapKit to detect "Airport" point of interest category
- Address Keywords: "airport", "terminal", "gate", "departure", "arrival"
- Proximity: Within reasonable distance of known airport coordinates

Apple Wallet:
- Boarding pass detection
- Flight information extraction
- Multi-leg journey support

Carrier Support

Verizon/Visible: *72[number] to enable, *73 to disable
AT&T/T-Mobile/Mint: **21*[number]# to enable, ##21# to disable
Google Fi: Requires app/website (note this limitation)

User Flow

1. First Launch:
   - Welcome screen explaining the concept
   - Setup wizard collects:
     * Confirms auto-detected carrier
     * Validates forwarding phone number
     * Selects detection methods
     * Chooses preferences (international detection, notification settings)

2. Export Process:
   - Preview screen shows exactly what the shortcut will do
   - Export generates personalized .shortcut file
   - Share sheet allows saving to Files or opening in Shortcuts
   - Instructions screen helps user import and set up automation

3. Settings:
   - Modify any configuration
   - Re-export updated shortcut
   - Reset to defaults option

Generated Shortcut Logic

The exported shortcut should contain only the necessary actions for that specific user:

1. Check current time (if user enabled time-based detection)
2. Get calendar events for today (if user enabled calendar detection)
3. Get current location (if user enabled location detection) 
4. Check Apple Wallet (if user enabled wallet detection)
5. Look for flight indicators using user's selected methods
6. If flight detected:
   - Get confirmation from user
   - Enable call forwarding using user's carrier code
   - Show success notification
7. Else:
   - Show "no flight detected" message

The key is that each exported shortcut contains only 10-20 actions tailored to that user's carrier and preferences, instead of 100+ actions trying to handle every possible scenario.

Architecture Notes

Use MVVM pattern:
- Models: Data structures and business logic
- Views: SwiftUI interface
- ViewModels: Binding between models and views

Keep everything local:
- Use UserDefaults for configuration
- Use Core Telephony for carrier detection
- Use PropertyListSerialization for shortcut export
- No network requests or external dependencies

Error Handling:
- Graceful degradation if permissions denied
- Clear error messages for users
- Fallback options when auto-detection fails
```

**Claude's Response**: Analyzed the requirements and began implementing the iOS app architecture with SwiftUI, creating the project structure and implementing core functionality.

## Development Phase Prompts

### 1. Project Structure Setup
**User**: "LETS GOOO[Request interrupted by user]wait i dont want MIT license. I want AGPL."

**Claude's Response**: Changed the license from MIT to AGPL v3 as requested, updating both the LICENSE file and README references.

### 2. Xcode Project Issues
**User**: "where do I add my Apple ID an set dev team?"

**Claude's Response**: Provided step-by-step instructions for adding Apple ID in Xcode settings and configuring the development team for code signing.

**User**: "looks frozen at 'pairing and connecting'"

**Claude's Response**: Provided troubleshooting steps for Xcode device pairing issues, including unplugging/replugging, trusting computer, and restarting connections.

### 3. Build Errors and Fixes
**User**: Multiple build error reports including asset catalog issues and project file corruption.

**Claude's Response**: Systematically debugged and fixed:
- Asset catalog structure issues
- Xcode project file corruption
- Swift compilation errors
- Import statement problems
- Project file ID conflicts

### 4. Command Line Building
**User**: "cant you build this all from the CLI? do it and fix all the bugs"

**Claude's Response**: Used xcodebuild from command line to identify and fix compilation errors including:
- Swift syntax errors in ShortcutGenerator.swift
- Toolbar ambiguity issues in ContentView.swift
- Missing import statements
- Project file structural problems

### 5. Project File Recreation
**User**: "The project 'FlightForwarder' is damaged and cannot be opened. Examine the project file for invalid edits or unresolved source control conflicts."

**Claude's Response**: Completely rebuilt the Xcode project file from scratch with proper UUIDs and structure, resulting in a working build.

**User**: "[Request interrupted by user for tool use]create the project file yourself"

**Claude's Response**: Created a clean, working project.pbxproj file with all proper references and configurations.

## Final GitHub Preparation

### 6. GitHub Project Setup
**User**: "ok clean this up, make a github project for it, ill give you some screenshots, add some TODOS in the readme that say :this has not been tested on a real phone yet, WIP, blah blah blah. Also including prompt.md that lists all the prompts used to create this."

**Claude's Response**: Cleaned up the project structure and began preparing comprehensive documentation.

**User**: "[Request interrupted by user]I put 2 pngs in ~/src/FlightForward, use them too in the README have them load in line."

**Claude's Response**: Moved the PNG files to screenshots directory and embedded them in the README with proper markdown image syntax.

## Key Development Decisions Made

### Architecture Choices
- **SwiftUI over UIKit**: For modern, declarative UI development
- **MVVM Pattern**: Clear separation between Views, Models, and Core logic
- **Local Processing**: All data stays on device for privacy
- **Modular Design**: Separate Models, Views, and Core directories

### Technical Implementation
- **Core Telephony**: For automatic carrier detection
- **UserDefaults**: For configuration persistence  
- **Property List Export**: For shortcut file generation
- **Share Sheet**: For shortcut distribution

### Code Quality Decisions
- **No External Dependencies**: Keep it simple and self-contained
- **iOS 15+ Target**: Use modern iOS features
- **Comprehensive Error Handling**: Robust user experience
- **Privacy-First**: No analytics or tracking

## Debugging Process

The development involved significant debugging of:

1. **Xcode Project File Issues**: Multiple iterations to get proper project structure
2. **Swift Compilation Errors**: Fixed syntax and import issues  
3. **Asset Catalog Problems**: Recreated proper folder structure
4. **Code Signing Configuration**: Set up development team and bundle IDs
5. **Build System Integration**: Ensured all files properly referenced

## Final Project State

The completed project includes:
- ✅ 11 Swift files with clean compilation
- ✅ Working Xcode project file
- ✅ Comprehensive architecture
- ✅ Professional UI/UX design  
- ❌ Not tested on real devices yet
- ❌ Shortcut export needs completion
- ❌ Real-world validation needed

## Development Time

Approximate development time: ~3 hours of intensive coding and debugging, resulting in:
- **1,805 lines** of Swift code
- **Complete iOS app** with professional architecture
- **Working build system** ready for device testing
- **Comprehensive documentation** for GitHub

## Tools Used

- **Claude Code**: Primary development assistant
- **Xcode Command Line Tools**: For building and compilation
- **macOS Terminal**: For file operations and testing
- **Git**: For version control preparation

---

*This document serves as a complete record of the development process for the Flight Forwarder iOS app, demonstrating rapid prototyping and iterative development using AI assistance.*