# Mobile POS Subscription App (Offline-First + Cloud Sync)

A modern, offline-first Mobile Point-of-Sale (POS) and Subscription application built with **Flutter** (Client) and **NestJS** (Cloud Backend), supporting Android phones, tablets, Sunmi/iMin POS terminals, and Windows desktop.

---

## 🌟 Key Features

### 1. Free Plan (100% Offline-First)
- **Local SQLite Engine**: High-performance local storage powered by Drift (SQLite) with ACID transactions.
- **Adaptive POS Sales UI**:
  - Landscape Split-View for Tablets, Sunmi/iMin POS Terminals, and Desktop.
  - Portrait Single-View with Bottom Cart Sheet for Smartphones.
- **Hardware & Printing**:
  - ESC/POS thermal receipt formatting for **58mm** and **80mm** paper sizes.
  - On-screen visual receipt preview before printing.
- **Daily Z-Report**:
  - End-of-day gross revenue, cash drawer audit, digital payments, and credit sales breakdown.
  - Printable Z-Report audit slip.

### 2. Pro & Custom Plan (Telegram Subscription Flow)
- **Telegram Licensing**:
  - In-app Shop ID 1-tap copy.
  - Direct connection to Telegram Admin (`@khantlin0000`) for license purchase.
  - 1-click License Key activation (`PRO-2026-DEMO-TEST`).
- **Cloud Delta Sync**:
  - Batch upload pending transactions, products, categories, customers, and debt ledgers.
  - Incremental pull for multi-device sync and multi-store management.

---

## 🏗️ Tech Stack & Architecture

- **Mobile & Desktop Client**: [Flutter](https://flutter.dev/) (Dart 3.x), [Riverpod](https://riverpod.dev/), [Drift](https://drift.simonbinder.eu/) (SQLite).
- **Cloud Backend**: [NestJS](https://nestjs.com/) (TypeScript), [Prisma ORM](https://www.prisma.io/).
- **Database**: SQLite (local client-side & cloud dev environment) / PostgreSQL (production ready).

```
mobile pos subscription/
├── pos_app/               # Flutter Client App (Android, Tablets, Windows)
│   ├── lib/
│   │   ├── core/          # Database (Drift), DAOs, Sync Service, Hardware Print
│   │   ├── features/      # POS Sales, Cart, Reports (Z-Report), Subscription
│   │   └── main.dart
│   └── test/              # 9 Unit and Widget Test Suites
│
├── backend/               # NestJS Cloud Sync & Subscription Server
│   ├── prisma/            # Schema, Migrations, Seeders
│   ├── src/               # SubscriptionModule, SyncModule, PrismaService
│   └── test_e2e.js        # End-to-End API Test Suite
└── README.md
```

---

## 🚀 Getting Started

### 1. Backend Server Setup
```bash
cd backend
npm install
npx prisma db push
npx ts-node prisma/seed.ts
npm run start:prod
# Cloud Server running on http://localhost:8085
```

### 2. Flutter POS Client Setup
```bash
cd pos_app
flutter pub get
flutter run -d windows
# or for Android devices:
# flutter run -d <device-id>
```

### 🔑 Demo License Keys
- **Pro Plan (1 Year)**: `PRO-2026-DEMO-TEST`
- **Custom Plan (2 Years)**: `CUSTOM-2026-ENTERPRISE`

---

## 🧪 Testing & Verification
- **Flutter Analysis**: `flutter analyze` (0 errors, 0 warnings)
- **Flutter Unit Tests**: `flutter test` (All 9 tests pass)
- **Backend API Tests**: `node backend/test_e2e.js` (All endpoints pass)
