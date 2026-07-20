# Advance Company Mobile

A Flutter mobile app for **Advance Company**, a SACCO (Savings and Credit Co-operative Organisation). Members manage their savings contributions, deposits, beneficiaries, and membership/loan applications; admins review and approve deposits, applications, and beneficiary verifications.

## Features

**Member**
- Email/password authentication with optional 2FA and biometric (Face ID / fingerprint) sign-in
- Dashboard — account balance, monthly deposit limit, recent deposits, quick actions
- Deposits — make a new deposit (M-Pesa / bank transfer / cash) and view deposit history
- Beneficiaries — add, list, and manage account beneficiaries
- Applications — submit and track membership/loan-related applications
- Documents — upload and view verification documents
- Notifications and profile/account settings

**Admin**
- Analytics dashboard (member stats, deposit trends)
- Pending deposit approvals
- Application review (approve/reject/mark under review)
- Beneficiary verification

## Tech stack

- **Flutter** (Dart >=3.0.0) with [Riverpod](https://riverpod.dev/) for state management
- [go_router](https://pub.dev/packages/go_router) for navigation, with an auth-aware redirect
- [Dio](https://pub.dev/packages/dio) for networking against a Django REST Framework backend
- `flutter_secure_storage` for JWT access/refresh tokens
- `local_auth` for biometric login
- Firebase Crashlytics for crash reporting (Android; iOS pending Firebase console setup — see [Known gaps](#known-gaps))

## Project structure

```
lib/
  config/            App-wide config (API base URL, feature flags, theme)
  core/               Constants, network client, secure storage, utils
  data/
    models/           JSON-serializable domain models
    repositories/      API access + response parsing per domain
    providers/         Riverpod providers/state notifiers
  presentation/
    navigation/        go_router setup + bottom-nav shell
    screens/            One folder per feature area (auth, dashboard, financial, ...)
    widgets/            Shared UI components
```

## Getting started

### Prerequisites
- Flutter SDK (channel stable)
- For Android: Android Studio + an emulator or device (`minSdk` 23)
- For iOS: Xcode, an Apple Development Team for device builds (`flutter build ios --simulator` works without one)

### Setup

```bash
flutter pub get
flutter run
```

The app talks to a live backend by default — see [`lib/config/api_config.dart`](lib/config/api_config.dart). To point at a local backend instead, set `_isProduction = false` there (uses `10.0.2.2` on the Android emulator, `localhost` elsewhere).

### Running tests

```bash
flutter test
```

## Configuration notes

- **Environment banner**: the yellow "STAGING" banner and app-title suffix in [`lib/config/app_config.dart`](lib/config/app_config.dart) are derived from `kReleaseMode`, not a manual flag — they disappear automatically in `--release` builds.
- **Android signing**: release builds are signed via `android/key.properties`, which points at a keystore that is intentionally **not** committed (see `.gitignore`). You'll need your own `key.properties` + keystore to produce a signed release build.
- **Firebase**: `android/app/google-services.json` is present (gitignored) for Android Analytics/Crashlytics. iOS has no Firebase config yet — add an iOS app in the Firebase console and drop the resulting `GoogleService-Info.plist` into `ios/Runner/` to enable it.

## Known gaps

- Bundle/application ID is still the Flutter template default (`com.example.advance_company_mobile`) — intentionally left as-is until ready to re-register with Firebase under a real identifier.
- iOS crash reporting is inactive until a `GoogleService-Info.plist` is added.
- No CI pipeline configured yet.
