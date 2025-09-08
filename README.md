# MacBeacon - macOS Security Monitoring & Compliance Tool

<img width="128" height="128" alt="128" src="https://github.com/user-attachments/assets/327846d1-3f1d-4edc-aa5e-0b80cd0cb3d1" />


**MacBeacon** is a comprehensive macOS security monitoring and compliance application built with SwiftUI. It provides real-time security monitoring, compliance reporting, and enterprise device management capabilities.

## 🚀 Features

### 🔒 Security Monitoring
- **Real-time Security Dashboard** - Comprehensive overview of system security status
<img width="1918" height="1080" alt="Screenshot 2025-09-07 at 23 39 57" src="https://github.com/user-attachments/assets/dd34ede7-8c66-47e6-b614-b49b76553511" />

- **Apple Services Monitoring** - Track Apple service configurations and status

<img width="1891" height="1071" alt="Screenshot 2025-09-07 at 23 40 35" src="https://github.com/user-attachments/assets/46afb3ce-b21a-41cd-85ae-5a42a735e963" />

- **Network Security** - Monitor network configurations and connections
- **Application Monitoring** - Track running applications and their security posture
- **System Health Monitoring** - Monitor system performance and health metrics
- **Endpoint Security** - Process, file, and network event monitoring

<img width="2032" height="1077" alt="Screenshot 2025-09-07 at 23 39 34" src="https://github.com/user-attachments/assets/9e1397bb-7ba8-41e9-8d8c-a00acb8612a3" />

### 📊 Compliance Reporting
- **CIS Level 1 Compliance** - Comprehensive CIS benchmark reporting with HTML dashboards
- **NIST 800-171 Compliance** - NIST Cybersecurity Framework implementation
- **GDPR Compliance** - Data protection and privacy compliance reporting
- **Interactive HTML Reports** - Rich, detailed compliance reports with visual dashboards
<img width="1895" height="1065" alt="Screenshot 2025-09-07 at 23 42 17" src="https://github.com/user-attachments/assets/23467d98-996c-44d3-bcab-7edf8b3164f2" />
<img width="2032" height="1077" alt="Screenshot 2025-09-07 at 23 44 04" src="https://github.com/user-attachments/assets/99a89f93-6711-4097-b222-893eb0906e8d" />

### 🏢 Enterprise Features
- **Azure Log Analytics Integration** - Centralized logging and reporting
- **MDM Support** - Enterprise deployment and configuration management
- **Local Mode Operation** - Complete data privacy with local-only processing
- **Configuration Management** - Flexible configuration via plist, XML, or mobileconfig files

### 🛡️ Data Privacy
- **Local Processing Mode** - All security monitoring performed locally
- **No Data Transmission** - Optional cloud integration with full user control
- **Privacy-First Design** - Your data stays on your device by default
<img width="1624" height="977" alt="Screenshot 2025-09-08 at 00 20 33" src="https://github.com/user-attachments/assets/6c9be2e3-8de5-490b-abcc-636769bc8f95" />

## 📋 Requirements

- **macOS 15.5+** (Sequoia or later)
- **Xcode 16.0+** (for building from source)
- **Swift 5.9+**

## 🚀 Installation

### Option 1: Download Pre-built Package
1. Download the latest `.pkg` file from [Releases](https://github.com/pathaksomesh06/MacBeacon/releases)
2. Double-click the `.pkg` file to install
3. Launch MacBeacon from Applications folder

### Option 2: Build from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/pathaksomesh06/MacBeacon.git
   cd MacBeacon
   ```
2. Open `MacBeacon.xcodeproj` in Xcode
3. Build and run the project

## ⚙️ Configuration

### Local Mode (Default)
MacBeacon runs in local mode by default, ensuring complete data privacy. No configuration is required.
<img width="1580" height="933" alt="Screenshot 2025-09-08 at 00 20 56" src="https://github.com/user-attachments/assets/d6562557-e173-4c19-8020-6892baba993a" />

### Azure Log Analytics Integration
To enable centralized logging:

1. **Create Azure Log Analytics Workspace**
2. **Deploy Configuration via Intune** 
3. **Or manually configure** using the provided configuration files

### Configuration Files
- `MacBeaconConfig.mobileconfig` - Apple Configuration Profile

## 🏢 Enterprise Deployment

### Microsoft Intune Deployment

1. **Deploy the Application**
   - Upload `MacBeacon.pkg` to Intune
   - Configure deployment settings

2. **Deploy Configuration Profile**
   - Use `MacBeaconConfig.mobileconfig` for Configuration Profiles
<img width="1505" height="774" alt="Screenshot 2025-09-08 at 16 32 04" src="https://github.com/user-attachments/assets/74a75463-6682-4862-8cdf-934b5fc6db25" />

3. **Configure Azure Log Analytics**
   - Update configuration with your workspace details
   - Deploy via Intune Configuration Profiles


## 📊 Compliance Frameworks

### CIS Level 1 Benchmark
- Comprehensive macOS security configuration checks
- Interactive HTML dashboard with risk assessment
- Detailed remediation guidance
- Real-time compliance scoring
  <img width="1624" height="977" alt="Screenshot 2025-09-08 at 00 22 04" src="https://github.com/user-attachments/assets/a0856ce1-ad0f-468d-bce1-a99094c0db92" />
<img width="1624" height="977" alt="Screenshot 2025-09-08 at 00 21 54" src="https://github.com/user-attachments/assets/38f8ab18-35f6-496d-92df-c3d17004e7d4" />


### NIST 800-171 Cybersecurity Framework
- Identify, Protect, Detect, Respond, Recover functions
- Detailed control mapping and assessment
- Visual framework representation
- Compliance scoring and reporting
<img width="2032" height="1077" alt="Screenshot 2025-09-07 at 23 43 20" src="https://github.com/user-attachments/assets/a25e6176-77dd-4e83-acc4-a9f69a902cb0" />

### GDPR Compliance
- Data protection principle assessment
- Privacy by design verification
- Data subject rights compliance
- Security of processing evaluation
<img width="2032" height="1077" alt="Screenshot 2025-09-07 at 23 43 57" src="https://github.com/user-attachments/assets/edef1ba0-3675-465e-8376-fa2fe43a2d21" />

## 🔧 Development

### Project Structure
```
MacBeacon/
├── MacBeacon/                 # Main application source
│   ├── Resources/            # Scripts and configuration files
│   ├── Assets.xcassets/      # App icons and assets
│   └── *.swift              # Swift source files
├── MacBeacon.xcodeproj/      # Xcode project file
└── README.md                 # This file
```

### Building Compliance Reports
The application includes shell scripts for generating compliance reports:
- `cis_compliance_script.sh` - CIS Level 1 benchmark
- `nist_audit_script.sh` - NIST 800-171 framework
- `gdpr_audit_script.sh` - GDPR compliance assessment

## 🤝 Special Thanks

Thankyou [@oktay-sari ](https://github.com/oktay-sari) for your insights & contribution to the project


**MacBeacon** - Keeping your Mac secure, one scan at a time. 🛡️
