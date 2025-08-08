# rICE qc (Flutter skeleton)

This is a minimal Flutter app skeleton for offline rice/paddy quality analysis.
- Android-first (APK build)
- Branded with your logo & green theme
- TFLite hook integrated (mock mode by default until you drop a real model)

## How to build APK
1) Install Flutter SDK and Android Studio.
2) Create a fresh Flutter project:
   ```bash
   flutter create rice_qc
   ```
3) Copy **pubspec.yaml**, **lib/**, and **assets/** from this package into your project root (replace existing lib/ and pubspec).
4) In project root:
   ```bash
   flutter pub get
   flutter build apk --release
   ```
   APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Add your TFLite model
- Place your model at `assets/model/rice_qc.tflite` (create the folder).
- Uncomment the asset line in `pubspec.yaml` under `flutter/assets`.
- The app will automatically switch from mock mode to real inference if the asset is present.

## Notes
- Current analyzer uses **mock detections** so you can test UI flow now.
- When you send your labeled dataset, we can train and ship a .tflite model to drop into assets.
