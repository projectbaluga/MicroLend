# MicroLend Flutter Application

A local-first, offline-capable micro-lending management suite built with Flutter for Android, iOS, and Windows Desktop.

## Features

- **Dashboard**: Portfolio overview metrics, 6-month expected cash flow chart, overdue repayments tracker, and recent loans progress bars.
- **Borrowers Management**: Full borrower CRUD, searchable/filterable table, risk badges, and automated credit scoring derived from loan repayment history and Debt-to-Income (DTI) ratio.
- **Loans Portfolio**: Issue loans, view schedule previews, support for upfront deduction fees (fixed amount or percentage), approval workflows, and installment payment tracking.
- **Settings & Preferences**: Currency formatting (USD, EUR, PHP, GBP), theme mode toggle (light/dark), customizable default interest rates/terms, JSON data export, file-based backup/restore, and sample data restoration.
- **Local-First & Offline Capable**: Built with `shared_preferences` local persistence requiring no external account or cloud dependency.
- **Backup & Restore**: Easily back up borrower and loan records to a local JSON file, share backup files via the native system share sheet (e.g., to Google Drive or Email), and restore data from picked backup files.

---

## Branding & Assets

MicroLend uses a centralized master asset strategy to generate app icons, splash screens, and web metadata for all target platforms:
- Master Icon & Splash: `flutter_app/assets/branding/app_icon.png` and `flutter_app/assets/branding/splash_logo.png`.
- Re-generating Platform Icons & Splash:
  ```bash
  cd flutter_app
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create
  ```
- Dynamic CI/CD Branding: In GitHub Actions (`workflow_dispatch`), you can optionally pass `app_name`, `app_description`, `brand_color`, or a custom `icon_url` to generate white-label builds automatically.

---

## Windows Desktop Support

MicroLend natively runs on Windows Desktop with a responsive desktop layout featuring a side `NavigationRail` on wide screens.

### Prerequisites for Windows Desktop Development

To run or build MicroLend on Windows:
1. **Flutter SDK**: Installed and configured in PATH.
2. **Visual Studio**: Visual Studio 2022 (or 2019) with the **"Desktop development with C++"** workload installed (includes MSVC C++ compiler, CMake, and Windows 10/11 SDK).
3. Verify setup:
   ```bash
   flutter doctor
   ```
   Ensure `[√] Windows toolchain - develop for Windows` shows a checkmark.

### Running on Windows

To launch the app in Windows desktop debug mode:
```bash
cd flutter_app
flutter run -d windows
```

### Building for Windows Release

To generate an optimized, standalone Windows executable:
```bash
cd flutter_app
flutter build windows --release
```

The release build output (containing `microlend.exe` and required Flutter/C++ DLLs) will be generated at:
```
flutter_app/build/windows/x64/runner/Release/
```

---

## Mobile & Cross-Platform

- **Android Build**:
  ```bash
  flutter build apk --release
  flutter build appbundle --release
  ```
- **iOS Build**:
  ```bash
  flutter build ios --release --no-codesign
  ```

---

## Testing & Code Quality

Run tests and static analysis from `flutter_app/`:
```bash
flutter analyze
flutter test
```
