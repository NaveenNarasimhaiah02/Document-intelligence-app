# SmartScan: Intelligent AI Document Classifier

SmartScan is a high-performance Flutter application designed to snap, scan, and classify documents locally on-device. It uses advanced OCR and rule-based AI to extract key metadata while ensuring industry-standard security and privacy.

---

## 🚀 Setup Instructions

### Prerequisites
- **Flutter SDK**: ^3.10.0
- **Android Studio / VS Code** with Flutter extensions.
- **Physical Device**: Required for camera-based scanning (Emulator camera may vary).

### Installation Steps
1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd ai_document_classifier
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Permissions**:
   - **Android**: Ensure `AndroidManifest.xml` includes `CAMERA` and `READ_MEDIA_IMAGES`.
   - **iOS**: (If applicable) Add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` to `Info.plist`.

4. **Run the App**:
   ```bash
   flutter run
   ```

---

## 🏗️ Architecture Overview

SmartScan follows a **Service-Oriented Architecture** to ensure modularity and high performance:

- **State Management**: Uses Flutter's `StatefulWidget` and `setState` for high-speed local UI updates, combined with service-based logic.
- **Storage Layer (`StorageService`)**: Powered by **Hive**, a lightning-fast NoSQL database. It includes an **in-memory caching layer** to prevent UI jank during document sorting.
- **Security Module**: Utilizes **AES-256 Encryption** for all document data. Encryption keys are stored in the system’s native **Secure Storage (Keystore/Keychain)** via `flutter_secure_storage`.
- **Theme Engine (`AC`)**: Custom design tokens for a premium, consistent visual identity (Glassmorphism + Vibrant Accents).

---

## 🧠 AI Approach

### On-Device Optical Character Recognition (OCR)
SmartScan leverages **Google ML Kit Text Recognition** for heavy-lifting. This ensures:
- **Zero Latency**: No cloud round-trips; processing happens on a separate thread locally.
- **Privacy**: No document images or data ever leave the user’s device.

### Intelligent Extraction & Classification
Once text is digitized, the app uses a **Multi-Stage RegEx Engine**:
1.  **Classification**: Scans for "Key Anchor Words" (e.g., "AADHAAR", "TAX INVOICE", "PRESCRIPTION") to determine the document type.
2.  **Entity Extraction**: Parses complex patterns to identify:
    - Dates (multiple formats DD-MM-YYYY, Month DD, etc.)
    - Amounts (detects currency symbols and picks the highest total)
    - Providers (Company names, Hospitals, or Government bodies)

---

## ⚖️ Trade-offs and Future Improvements

### Trade-offs
- **RegEx vs. LLM**: We chose optimized Regex over local LLMs to maintain a small binary size (~10MB) and ensure instant classification on low-end devices.
- **On-Device vs. Cloud**: By choosing local processing, we prioritize privacy and offline access, though cloud-based OCR might offer slightly higher accuracy for very blurred text.

### Future Improvements
- **Local LLM Integration**: Incorporating a small TFLite model to handle unstructured "handwritten" documents more accurately.
- **Auto-Cropping**: Adding a custom camera overlay that automatically detects document edges and crops perspectives.
- **Cloud Sync (Optional)**: Implementing end-to-end encrypted backup to Google Drive or OneDrive.

---

## 🔒 Privacy

Your privacy is our priority. SmartScan is designed to work entirely offline, ensuring no data ever leaves your device. For more details, see our [Privacy Policy](PRIVACY_POLICY.md).

---

**Snap. Scan. Done.**
