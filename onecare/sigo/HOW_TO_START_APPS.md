How to start apps

- Android dev: flutter run --flavor dev -t lib/main.dart
- Android prod: flutter run --flavor prod -t lib/main.dart
- iOS dev: select scheme dev in Xcode, or flutter run --flavor dev -t lib/main.dart
- iOS prod: select scheme Runner, or flutter run --flavor prod -t lib/main.dart

How to build Android

- APK (dev): flutter build apk --flavor dev -t lib/main.dart
- APK (prod): flutter build apk --flavor prod -t lib/main.dart
- AAB (dev): flutter build appbundle --flavor dev -t lib/main.dart
- AAB (prod): flutter build appbundle --flavor prod -t lib/main.dart
