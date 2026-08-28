# MicroLend — Solo Lending Management Suite

MicroLend is a local-first, offline-capable micro-lending management application for solo operators. It includes automated loan amortization scheduling, credit risk assessment, local state persistence with write queueing, dashboard portfolio analytics, and repayment tracking.

This repository contains both the **React Web Application** and the **Flutter Mobile Application** (Android & iOS).

---

## 📱 Flutter Mobile Application (`flutter_app/`)

Reimplemented in Dart/Flutter with local-first on-device storage (`shared_preferences`), `fl_chart` analytics, and full feature parity with the web suite.

### Running the Mobile App
```bash
cd flutter_app
flutter pub get
flutter run
```

### Running Mobile Unit Tests
```bash
cd flutter_app
flutter test
```

### Building Release Packages
- **Android APK**: `cd flutter_app && flutter build apk`
- **iOS App Bundle**: `cd flutter_app && flutter build ipa`

---

## 💻 Web Application (React + Vite)

Local-first React SPA using Tailwind CSS, Recharts, and `useSyncExternalStore` bound to LocalStorage.

### Running the Web App
```bash
npm install
npm run dev
```

### Running Web Unit Tests
```bash
npm test
```

---

## 📊 Core Business & Financial Logic

Both platforms share identical financial calculations and business rules:
- **Amortization Schedule (`generateSchedule`)**: Standard equal-monthly-payment calculation with month-over-month due dates and rounding drift correction on final installment.
- **Installment Status (`getScheduleWithStatus`)**: Sequential payment allocation tracking `paid`, `partial`, `overdue`, `pending`, and `cancelled` statuses.
- **Credit & Risk Assessment (`assessBorrower`)**: Derives credit score and Debt-to-Income (DTI %) from borrower income, active loan obligations, and payment history to assign `low`, `medium`, or `high` risk ratings.
- **Local-First Write Queue**: Off-grid operations are queued and drained during simulated or remote synchronization (`syncAll`).
