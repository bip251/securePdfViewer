# Secure PDF Viewer

A professional, production-grade Flutter application that renders PDFs from URLs with an emphasis on secure viewing. It provides a simple, single-call API to open a viewer with granular security options and a master toggle to enable/disable all protections at once.

Note: No backend is required for this app. If you want to add Firebase or Supabase later, open the corresponding panel in Dreamflow and complete the guided setup there.

## Highlights
- Lightweight, pure Flutter UI with native PDF rendering on Android
- Granular security options with a single master toggle
- Screenshot blocking on Android via FLAG_SECURE
- No text selection or built-in sharing/printing actions in the viewer UI
- Animated page transitions, fullscreen mode, gesture navigation, and smooth zoom/pan
- Web fallback using an iframe

## Quick Start
Open a secure PDF viewer from anywhere in your app:

```dart
import 'package:inkwell/secure_pdf_viewer.dart';

await SecurePdfViewer.open(
  context,
  url: 'https://example.com/your.pdf',
  title: 'Secure PDF',
  // Master toggle: enable or disable all protections in one shot
  options: SecurePdfSecurityOptions.all(true),
);
```

### Granular Security Options
Use fine-grained controls when needed. If `enforceAll` is true, it turns on all protections regardless of individual flags.

```dart
await SecurePdfViewer.open(
  context,
  url: 'https://example.com/your.pdf',
  title: 'Confidential Report',
  options: const SecurePdfSecurityOptions(
    enforceAll: false,        // set to true to enable all protections at once
    blockScreenshots: true,   // Android only via FLAG_SECURE
    blockCopy: true,          // UI avoids selectable text
    blockShare: true,         // UI omits share/export actions
    blockPrint: true,         // UI omits print actions
    blockSaveToFiles: true,   // UI omits save-to-files actions
  ),
);
```

API reference (lib/secure_pdf_viewer.dart):
- SecurePdfViewer.open(context, {required String url, String? title, SecurePdfSecurityOptions options})
- SecurePdfSecurityOptions
  - enforceAll: If true, all protections are applied
  - blockScreenshots: On Android, uses FLAG_SECURE
  - blockCopy, blockShare, blockPrint, blockSaveToFiles: Enforced by UI/logic, not exposed as actions
  - factory SecurePdfSecurityOptions.all(bool enabled)

## Platform Notes
- Android: Screenshot blocking is enforced using FLAG_SECURE when security is enabled.
- iOS: There is no public API to fully block screenshots. The viewer does not expose sharing/printing actions and renders as images to reduce copyability.
- Web: The PDF is displayed in an iframe. Platform-level screenshot prevention is not possible on the web.

## App Configuration
- App name: "Secure PDF Viewer"
  - Android: android/app/src/main/AndroidManifest.xml (android:label)
  - iOS: ios/Runner/Info.plist (CFBundleDisplayName)
  - Web: web/index.html <title> and manifest.json
- Permissions
  - Android: INTERNET, ACCESS_NETWORK_STATE
  - iOS: App Transport Security is enabled to allow arbitrary loads for demo. Update ATS rules to your production requirements.
- Icons
  - Configure Flutter Launcher Icons in pubspec.yaml (flutter_launcher_icons). Provide production-ready assets before publishing.

## Publishing Checklist (Play Store & App Store)
- Update app name, bundle identifiers, and versioning
- Provide final app icons and splash assets
- Ensure a valid privacy policy that reflects your data practices
- Verify permissions and network security rules (ATS on iOS)
- Test on physical devices across orientations and screen sizes
- Prepare store listing: title, description, screenshots, and promotional graphics
- Run a final QA pass for error states (e.g., offline, invalid URLs)

## Demo Screen
lib/screens/home_page.dart provides a simple UI to paste a URL, toggle security, and open the viewer.

## Limitations and Guidance
- The app intentionally omits features like share, print, and system-wide save controls to reduce data exfiltration paths.
- No solution can absolutely prevent all forms of copying (e.g., taking a photo of the screen). This app focuses on practical protections.

