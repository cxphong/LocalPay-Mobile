# LocalPay Mobile

A premium Flutter application for the **LocalPay Go** payment orchestration engine.

## 🚀 Features
- **VietQR Scanning**: Instant parsing of standard bank transfer QR codes.
- **Crypto Payments**: Pay with USDT, USDC, or SOL via Solana.
- **Real-time FX**: Live quotes from the backend for transparency.
- **Secure Processing**: Built-in state machine for robust transaction handling.

## 🛠 Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Blockchain**: Solana Dart SDK
- **Styling**: Google Fonts (Inter), Custom Dark Theme

## 🚦 Getting Started

1.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

2.  **Configure API**:
    Update the `baseUrl` in `lib/services/api_service.dart`.

3.  **Run**:
    ```bash
    flutter run
    ```

## 🏗 Directory Structure
- `lib/models/`: JSON serialization models.
- `lib/services/`: HTTP client and API wrappers.
- `lib/providers/`: Business logic and state management.
- `lib/screens/`: High-fidelity UI screens.
