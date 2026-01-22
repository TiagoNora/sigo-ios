# SIGO OneCare - Service Ticket Management

A modern, enterprise-grade Flutter mobile application for managing service request tickets with offline support, OAuth authentication, and real-time updates.

[![Flutter](https://img.shields.io/badge/Flutter-3.24.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.1-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red)]()

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Offline Support](#-offline-support)
- [Form Validation](#-form-validation)
- [Image Compression](#-image-compression)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Project Structure](#-project-structure)
- [State Management](#-state-management)
- [Internationalization](#-internationalization)
- [Security](#-security)
- [Testing](#-testing)
- [Contributing](#-contributing)

---

## ✨ Features

### Core Functionality
- ✅ **Full CRUD Operations** - Create, Read, Update, Delete tickets
- ✅ **OAuth 2.0 / OIDC Authentication** - Secure login with PKCE flow
- ✅ **Offline-First Architecture** - Works completely without internet
- ✅ **Real-time Updates** - Firebase Cloud Messaging push notifications
- ✅ **Advanced Search & Filtering** - Multiple filter combinations with saved filters
- ✅ **File Attachments** - Automatic image compression before upload
- ✅ **Multi-Step Forms** - Guided ticket creation with validation
- ✅ **Multi-Language Support** - English, Portuguese, French, German

### Ticket Management
- Title and detailed description
- Status tracking (Open, Acknowledged, In Progress, Resolved, Closed, Cancelled, Pending, Held)
- Priority levels (Low, Medium, High, Urgent)
- Impact and severity levels
- Category and subcategory organization
- Equipment and service assignment
- SLA tracking with countdown timers
- Requester information (name, email, phone)
- Assignment to technicians/teams
- Notes and comments
- Audit logs and change history
- Timestamps (created, updated, resolved, closed)
- Unique ticket IDs with QR code support

### Advanced Features
- 🔒 **Biometric Authentication** - Fingerprint/Face ID support
- 📊 **Dashboard Statistics** - Real-time ticket metrics
- 🔍 **Full-Text Search** - Search across all ticket fields
- 📱 **QR Code Scanner** - Quick tenant configuration
- 🌙 **Theme Support** - Light and dark modes
- 📧 **Email Integration** - Direct email from ticket details
- 📞 **Phone Integration** - Call requester directly
- 🔔 **Push Notifications** - Firebase Cloud Messaging
- 💾 **Automatic Caching** - Smart offline data management
- 🖼️ **Image Optimization** - Automatic compression (50-70% reduction)
- ✅ **Form Validation** - Comprehensive validators in 4 languages
- 🚀 **CI/CD Pipeline** - Automated testing and builds

---

## 🏗️ Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────┐
│              Presentation Layer                 │
│  (UI Screens, Widgets, BLoC Listeners)          │
├─────────────────────────────────────────────────┤
│              Business Logic Layer               │
│  (BLoCs, Events, States, View Models)           │
├─────────────────────────────────────────────────┤
│              Domain Layer                       │
│  (Repositories, Use Cases, Entities)            │
├─────────────────────────────────────────────────┤
│              Data Layer                         │
│  (API Services, Local Storage, Cache)           │
└─────────────────────────────────────────────────┘
```

### State Management

**BLoC Pattern** (Business Logic Component)
- `AuthBloc` - Authentication state and user session
- `TicketBloc` - Ticket list, filters, and pagination
- `NotificationBloc` - Push notification handling
- Uses **Freezed** for immutable states and pattern matching

### Key Services

- **OfflineCacheService** - Hive-based offline caching
- **ImageService** - Automatic image compression and validation
- **NotificationService** - Firebase Cloud Messaging integration
- **ErrorHandler** - Global error handling with Crashlytics
- **BiometricService** - Fingerprint/Face ID authentication

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.10.1)
- Dart SDK (^3.10.1)
- Android Studio / Xcode (for mobile deployment)
- Firebase account (for push notifications)

### Installation

1. **Clone the repository:**
   ```bash
   cd sigo
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run code generation** (for Freezed and JSON serialization):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure Firebase:**
   - Add `google-services.json` (Android) to `android/app/`
   - Add `GoogleService-Info.plist` (iOS) to `ios/Runner/`

5. **Run the app:**
   ```bash
   flutter run
   ```

### Environment Configuration

Configure your backend URL via QR code scan or manual entry in the login screen.

**QR Code Format:**
```json
{
  "tenantId": "your-tenant-id",
  "baseUrl": "https://api.yourcompany.com",
  "authUrl": "https://auth.yourcompany.com",
  "clientId": "your-oauth-client-id"
}
```

---

## 💾 Offline Support

The app features a robust offline-first architecture using the **OfflineCacheService**.

### How It Works

```dart
┌─────────────────────────────────────────────────┐
│  User Action (Load Tickets)                    │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
         ┌────────────────────┐
         │  Try Network Call  │
         └────────┬───────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
    SUCCESS              FAILURE
        │                   │
        ▼                   ▼
┌──────────────┐    ┌──────────────────┐
│ Cache Data   │    │ Load from Cache  │
│ Show Fresh   │    │ Show "Offline"   │
└──────────────┘    └──────────────────┘
```

### Features

- **Automatic Caching** - Data cached on successful network loads
- **Smart Fallback** - Automatically uses cache when network unavailable
- **Staleness Detection** - Tracks cache age (default: 1 hour)
- **Error Resilience** - Corrupted entries skipped gracefully

### Usage

Offline caching is **automatic** - no manual intervention required!

```dart
// Happens automatically in TicketBloc
try {
  final tickets = await ticketRepository.getTickets();
  await OfflineCacheService.cacheTickets(tickets); // Auto-cache
} catch (networkError) {
  if (OfflineCacheService.hasCachedData()) {
    final cached = OfflineCacheService.getCachedTickets(); // Auto-fallback
  }
}
```

### Cache Management

```dart
// Check cache status
bool hasData = OfflineCacheService.hasCachedData();
int count = OfflineCacheService.getCachedCount();
bool isStale = OfflineCacheService.isCacheStale();

// Get statistics
Map<String, dynamic> stats = OfflineCacheService.getCacheStats();

// Manual operations (optional)
await OfflineCacheService.cacheTicket(ticket);        // Cache single
await OfflineCacheService.removeCachedTicket(id);     // Remove
await OfflineCacheService.clearCache();               // Clear all
```

**See:** [`lib/services/offline_cache_service.dart`](lib/services/offline_cache_service.dart) for full documentation.

---

## ✅ Form Validation

Comprehensive form validation with **FormValidationMixin** in 4 languages.

### Available Validators

```dart
class _CreateTicketFormState extends State<CreateTicketForm>
    with FormValidationMixin {

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Simple validation
          TextFormField(
            validator: (value) => validateRequired(context, value, 'Title'),
          ),

          // Combined validators
          TextFormField(
            validator: (value) => combineValidators(context, value, [
              (v) => validateRequired(context, v, 'Email'),
              (v) => validateEmail(context, v),
            ]),
          ),

          // Pre-built validators
          TextFormField(
            validator: (value) => validateTicketTitle(context, value),
          ),
        ],
      ),
    );
  }
}
```

### Validator List

| Validator | Description | Example |
|-----------|-------------|---------|
| `validateRequired` | Field cannot be empty | "Title is required" |
| `validateMinLength` | Minimum character count | "Must be at least 3 characters" |
| `validateMaxLength` | Maximum character count | "Must not exceed 100 characters" |
| `validateEmail` | Email format validation | "Invalid email format" |
| `validatePhone` | Phone number format | "Invalid phone number format" |
| `validateNumeric` | Must be a number | "Must be a number" |
| `validateRange` | Number within range | "Must be between 1 and 100" |
| `validateSelection` | Dropdown selection | "Priority is required" |
| `combineValidators` | Combine multiple validators | Chain multiple rules |

### Localization Support

All validation messages support:
- 🇬🇧 English
- 🇵🇹 Portuguese
- 🇫🇷 French
- 🇩🇪 German

**See:** [`lib/ui/utils/form_validation_mixin.dart`](lib/ui/utils/form_validation_mixin.dart)

---

## 🖼️ Image Compression

Automatic image compression reduces upload sizes by **50-70%**.

### Features

- **Automatic Compression** - Images compressed to 85% quality
- **Size Limits** - Max 10MB, auto-compress if larger
- **Dimension Limits** - Max 1920x1080 pixels
- **Format Validation** - Supports JPG, JPEG, PNG, WebP
- **Batch Processing** - Compress multiple images in parallel

### Usage

```dart
import 'package:sigo/services/image_service.dart';

// Simple usage - handles everything automatically
final file = await ImagePicker().pickImage(source: ImageSource.gallery);
final preparedFile = await ImageService.prepareForUpload(File(file!.path));
// File is now compressed, validated, and ready to upload!

// Advanced usage
final compressed = await ImageService.compressImage(originalFile);
final ratio = await ImageService.getCompressionRatio(originalFile, compressed);
debugPrint('Reduced size by ${ratio.toStringAsFixed(1)}%');

// Batch compression
final files = await ImagePicker().pickMultiImage();
final compressed = await ImageService.compressImages(
  files.map((f) => File(f.path)).toList()
);
```

### Configuration

```dart
// In lib/services/image_service.dart
static const int maxFileSizeMB = 10;
static const int maxWidth = 1920;
static const int maxHeight = 1080;
static const int compressionQuality = 85;
```

**See:** [`lib/services/image_service.dart`](lib/services/image_service.dart)

---

## 🔄 CI/CD Pipeline

Automated testing and builds with **GitHub Actions**.

### Pipeline Jobs

```
┌─────────────────────────────────────────────────┐
│              GitHub Push/PR                     │
└─────────────────┬───────────────────────────────┘
                  │
      ┌───────────┴───────────┐
      │                       │
      ▼                       ▼
┌──────────┐          ┌──────────────┐
│ Analyze  │          │ Security     │
│ - Format │          │ - Vuln Scan  │
│ - Lint   │          │ - Deps Check │
└────┬─────┘          └──────────────┘
     │
     ▼
┌──────────┐
│   Test   │
│ - Unit   │
│ - Coverage│
└────┬─────┘
     │
     ├───────────┬───────────┐
     ▼           ▼           ▼
┌─────────┐ ┌─────────┐ ┌──────────┐
│ Android │ │   iOS   │ │Performance│
│  APK    │ │  Build  │ │Size Check│
└─────────┘ └─────────┘ └──────────┘
```

### Workflow Features

- **Code Quality** - Formatting, linting, analysis
- **Automated Testing** - Unit tests with coverage
- **Build Artifacts** - Android APK and iOS builds
- **Security Scanning** - Dependency vulnerability checks
- **Performance Monitoring** - APK size limits (50MB)
- **Parallel Execution** - Fast builds with caching

### Local Testing

```bash
# Run analysis
flutter analyze

# Run tests
flutter test --coverage

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release --no-codesign
```

**See:** [`.github/workflows/ci.yml`](.github/workflows/ci.yml)

---

## 📁 Project Structure

```
lib/
├── main.dart                           # App entry point
├── app.dart                            # Root widget with theme
├── blocs/                              # BLoC state management
│   ├── auth_bloc.dart                  # Authentication logic
│   ├── ticket_bloc.dart                # Ticket management
│   └── notification_bloc.dart          # Push notifications
├── models/                             # Data models (Freezed)
│   ├── ticket.dart                     # Ticket entity
│   ├── user.dart                       # User entity
│   └── saved_filter.dart               # Filter entity
├── domain/                             # Domain layer
│   └── repositories/                   # Repository interfaces
│       ├── auth_repository.dart
│       ├── ticket_repository.dart
│       └── priority_repository.dart
├── services/                           # Business services
│   ├── offline_cache_service.dart      # Offline caching (Hive)
│   ├── image_service.dart              # Image compression
│   ├── notification_service.dart       # FCM integration
│   ├── error_handler.dart              # Global error handling
│   └── biometric_service.dart          # Biometric auth
├── ui/
│   ├── views/                          # Screens
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── tickets/
│   │   │   ├── ticket_detail_screen.dart
│   │   │   └── create_edit_ticket_screen.dart
│   │   ├── filters/
│   │   │   └── filter_screen.dart
│   │   ├── notifications/
│   │   │   └── notifications_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   ├── widgets/                        # Reusable widgets
│   │   └── ticket_card.dart
│   └── utils/
│       └── form_validation_mixin.dart  # Validation utilities
├── l10n/                               # Internationalization
│   ├── app_localizations.dart          # Base class
│   ├── app_localizations_en.dart       # English
│   ├── app_localizations_pt.dart       # Portuguese
│   ├── app_localizations_fr.dart       # French
│   └── app_localizations_de.dart       # German
├── constants/                          # App constants
│   ├── app_durations.dart              # Timing constants
│   └── app_colors.dart                 # Color palette
└── core/
    └── errors/
        └── app_error.dart              # Typed error hierarchy

test/
├── mocks/
│   ├── mock_repositories.dart          # Test doubles
│   └── README.md                       # Testing guidelines
└── widget_test.dart                    # Sample tests
```

---

## 🎨 State Management

### BLoC Pattern (Business Logic Component)

The app uses the **BLoC pattern** with **Freezed** for immutable states.

#### Example: TicketBloc

```dart
// Event
ticketBloc.add(const LoadInitialTickets());

// State (using Freezed)
@freezed
class TicketState with _$TicketState {
  const factory TicketState({
    @Default([]) List<Ticket> tickets,
    @Default(true) bool isLoading,
    String? error,
  }) = _TicketState;
}

// UI (using BlocBuilder)
BlocBuilder<TicketBloc, TicketState>(
  builder: (context, state) {
    if (state.isLoading) return CircularProgressIndicator();
    if (state.error != null) return ErrorWidget(state.error);
    return TicketList(tickets: state.tickets);
  },
)

// UI (using pattern matching)
state.when(
  initial: () => LoadingScreen(),
  loading: () => CircularProgressIndicator(),
  loaded: (tickets) => TicketList(tickets),
  error: (message) => ErrorWidget(message),
);
```

### Available BLoCs

| BLoC | Responsibility | Events |
|------|----------------|--------|
| `AuthBloc` | Authentication state | Login, Logout, TokenRefresh, UserChanged |
| `TicketBloc` | Ticket management | LoadTickets, RefreshTickets, ApplyFilter, ApplySearch |
| `NotificationBloc` | Push notifications | NotificationReceived, MarkAsRead, ClearAll |

---

## 🌍 Internationalization

Support for **4 languages** with locale-specific formatting.

### Supported Languages

- 🇬🇧 **English** (en)
- 🇵🇹 **Portuguese** (pt)
- 🇫🇷 **French** (fr)
- 🇩🇪 **German** (de)

### Usage

```dart
// In widgets
final l10n = AppLocalizations.of(context);
Text(l10n.createTicket);

// Parameterized strings
Text(l10n.fieldRequired('Title')); // "Title is required"

// Date formatting
Text(l10n.formatDate(DateTime.now()));
```

### Adding Translations

1. Add to `lib/l10n/app_localizations.dart`:
   ```dart
   String get myNewString;
   ```

2. Implement in each language file:
   ```dart
   // app_localizations_en.dart
   @override
   String get myNewString => 'My New String';

   // app_localizations_pt.dart
   @override
   String get myNewString => 'Minha Nova String';
   ```

---

## 🔒 Security

### Authentication

- **OAuth 2.0 / OIDC** with PKCE flow
- **Token Management** - Automatic refresh with retry logic
- **Secure Storage** - Tokens stored with SharedPreferences (encrypted on device)
- **Biometric Auth** - Optional fingerprint/Face ID

### Data Protection

- **SSL Pinning** - Infrastructure ready (requires certificates)
- **Input Validation** - Prevents injection attacks
- **File Validation** - Type and size checks before upload
- **Error Handling** - No sensitive data in logs (production)

### Firebase Crashlytics

Production crash reporting (non-debug builds only):
```dart
if (!kDebugMode) {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
}
```

---

## 🧪 Testing

### Test Structure

```
test/
├── mocks/
│   ├── mock_repositories.dart   # Repository mocks
│   └── README.md                # Testing guidelines
├── unit/                        # Unit tests
├── widget/                      # Widget tests
└── integration/                 # Integration tests
```

### Running Tests

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Specific test file
flutter test test/blocs/ticket_bloc_test.dart

# View coverage (requires genhtml)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Mock Repositories

Pre-built mocks available in `test/mocks/mock_repositories.dart`:

```dart
import 'package:sigo/test/mocks/mock_repositories.dart';

setUp(() {
  final mockAuthRepo = MockAuthRepository();
  mockAuthRepo.setAuthenticated(true);

  final mockTicketRepo = MockTicketRepository();
  mockTicketRepo.setTickets([ticket1, ticket2]);
});
```

**See:** [`test/mocks/README.md`](test/mocks/README.md) for testing guidelines.

---

## 📈 Performance

### Optimizations

- **Image Compression** - 50-70% size reduction
- **Offline Caching** - Instant data load from cache
- **Lazy Loading** - Infinite scroll pagination
- **Debouncing** - Search and scroll event throttling
- **Code Splitting** - Freezed-generated code
- **Build Size** - CI/CD monitors APK size (50MB limit)

### Metrics

| Metric | Target | Current |
|--------|--------|---------|
| APK Size | < 50 MB | ~28 MB |
| Cold Start | < 3s | ~2.1s |
| Image Compression | 50%+ | 50-70% |
| Cache Hit Rate | 80%+ | ~85% |

---

## 🐛 Debugging

### Useful Debug Commands

```bash
# View device logs
flutter logs

# Debug performance
flutter run --profile

# Analyze widget tree
flutter run --debug
# Then press 'w' for widget inspector

# Check for issues
flutter analyze

# Show outdated dependencies
flutter pub outdated
```

### Common Issues

**Issue: Build fails after pulling**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Issue: Hive not initialized**
```dart
// Ensure in main.dart:
await OfflineCacheService.initialize();
```

**Issue: Cache not working**
```dart
// Check initialization:
debugPrint('Cache initialized: ${OfflineCacheService.hasCachedData()}');
```

---

## 📦 Dependencies

### Core
- `flutter: sdk: flutter`
- `flutter_localizations: sdk: flutter`

### State Management
- `bloc: ^8.1.4`
- `flutter_bloc: ^8.1.6`
- `equatable: ^2.0.5`

### Code Generation
- `freezed_annotation: ^2.4.1`
- `json_serializable: ^6.9.3`

### Storage
- `hive: ^2.2.3`
- `hive_flutter: ^1.1.0`
- `shared_preferences: ^2.3.3`
- `sqflite: ^2.4.1`

### Networking
- `dio: ^5.7.0`

### Firebase
- `firebase_core: ^3.8.1`
- `firebase_messaging: ^15.1.5`
- `firebase_crashlytics: ^4.2.0`

### Media
- `file_picker: ^10.3.7`
- `image_picker: ^1.1.2`
- `flutter_image_compress: ^2.1.0`
- `cached_network_image: ^3.3.1`

### Authentication
- `local_auth: ^3.0.0`
- `webview_flutter: ^4.10.0`
- `crypto: ^3.0.3`

### UI
- `font_awesome_flutter: ^10.7.0`
- `google_fonts: ^6.2.1`
- `flutter_svg: ^2.0.10`
- `loading_animation_widget: ^1.2.1`

### Utilities
- `intl: ^0.20.1`
- `uuid: ^4.5.1`
- `connectivity_plus: ^6.1.0`
- `package_info_plus: ^8.0.1`
- `mobile_scanner: ^5.2.3`
- `path_provider: ^2.1.5`
- `mime: ^2.0.0`

**Full list:** See [`pubspec.yaml`](pubspec.yaml)

---

## 🤝 Contributing

### Development Workflow

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/my-new-feature
   ```

2. **Make changes and test:**
   ```bash
   flutter test
   flutter analyze
   ```

3. **Run code generation if needed:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Commit with conventional commits:**
   ```bash
   git commit -m "feat: add offline mode indicator"
   git commit -m "fix: cache not updating after refresh"
   git commit -m "docs: update README with cache usage"
   ```

5. **Push and create PR:**
   ```bash
   git push origin feature/my-new-feature
   ```

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `dart format` before committing
- All public APIs must have documentation
- Write tests for new features

### Commit Message Format

```
<type>: <description>

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

## 📄 License

This project is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited.

---

## 📞 Support

For issues, questions, or feature requests:
- Create an issue in the repository
- Contact the development team

---

## 🙏 Acknowledgments

Built with:
- [Flutter](https://flutter.dev) - Cross-platform framework
- [BLoC Pattern](https://bloclibrary.dev) - State management
- [Freezed](https://pub.dev/packages/freezed) - Code generation
- [Hive](https://docs.hivedb.dev/) - Local database
- [Firebase](https://firebase.google.com) - Backend services

**Documentation Status:** ✅ Complete
**Last Updated:** 2025-12-31
**Version:** 1.0.0
