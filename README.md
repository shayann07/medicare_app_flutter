# 🏥 MediCare — Telehealth, Doctor Appointments & AI Medical Companion

[![Platform](https://img.shields.io/badge/Platform-Flutter_|_Mobile-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Language](https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![State Management](https://img.shields.io/badge/State_Management-GetX-8A2BE2?style=for-the-badge&logo=flutter)](https://pub.dev/packages/get)
[![AI Integration](https://img.shields.io/badge/AI_Engine-OpenAI_GPT--4o--mini-00A67E?style=for-the-badge&logo=openai&logoColor=white)](https://platform.openai.com/)
[![Payments](https://img.shields.io/badge/Payments-Stripe_PaymentSheet-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://stripe.com/)
[![Backend](https://img.shields.io/badge/Backend-Firebase_Realtime_DB-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

> **MediCare** is an all-in-one mobile telehealth platform connecting patients to verified medical specialists with automated calendar slot booking, in-app Stripe payment processing, and an intelligent OpenAI-powered clinical guidance assistant.

---

## 📖 Overview

Access to timely medical consultations and reliable primary triage is essential in modern digital healthcare. **MediCare** unifies digital clinic appointments with conversational AI triage into a reactive, high-performance Flutter mobile application.

Built on the **GetX reactive architecture**, MediCare enables patients to browse medical specialists across disciplines, inspect availability across dynamic 20-minute time intervals, and confirm reservations via native **Stripe PaymentSheet** checkout. For preliminary medical questions, an integrated **OpenAI GPT-4o-mini health assistant** delivers safe, disclaimer-governed health information with automatic emergency redirection.

---

## 🏗️ Architecture & Interaction Flow

```mermaid
flowchart TD
    subgraph Client ["Flutter GetX Client Layer"]
        ABC["AppointmentBookingController"]
        CBC["ChatbotController"]
        UI_Book["Appointment Booking & Slot Grid UI"]
        UI_Chat["AI Chatbot Conversation UI"]
    end

    subgraph Payments ["Stripe Payment Infrastructure"]
        StripeSheet["Stripe PaymentSheet (Native SDK)"]
        PaymentIntent["Stripe PaymentIntent API (/v1/payment_intents)"]
    end

    subgraph Backend ["Firebase Realtime Database"]
        DocTree["/doctors/{specialization}/{docId}"]
        PatTree["/patients/{patientId}"]
        AppTree["/Appointment & /Booked Appointment"]
    end

    subgraph AI ["OpenAI LLM Engine"]
        GPT["GPT-4o-mini Endpoint (/v1/chat/completions)"]
        Guard["Clinical Guardrails & Emergency Triage Filter"]
    end

    UI_Book --> ABC
    UI_Chat --> CBC

    ABC -->|1. Fetch Doctor & Booked Slots| DocTree
    ABC -->|2. Request Client Secret| PaymentIntent
    PaymentIntent --> StripeSheet
    StripeSheet -->|3. On Success| ABC
    ABC -->|4. Atomically Write Records| AppTree
    ABC -->|Sync Patient History| PatTree

    CBC -->|Prompt with Medical System Prompt| Guard
    Guard --> GPT
    GPT -->|Disclaimed Medical Guidance| CBC
    CBC --> UI_Chat
```

### Appointment Booking & Payment Sequence

```mermaid
sequenceDiagram
    autonumber
    actor Patient as 👤 Patient
    participant Controller as AppointmentBookingController
    participant Firebase as Firebase Realtime DB
    participant StripeSDK as Stripe PaymentSheet
    participant StripeAPI as Stripe Backend API

    Patient->>Controller: Select Specialist, Date & Time Slot
    Controller->>Firebase: Query already booked slots for date
    Firebase-->>Controller: Return reserved slot list
    alt Slot is Available
        Controller->>StripeAPI: POST /v1/payment_intents (amount, currency)
        StripeAPI-->>Controller: Return client_secret & ephemeralKey
        Controller->>StripeSDK: initPaymentSheet(client_secret)
        Controller->>StripeSDK: presentPaymentSheet()
        Patient->>StripeSDK: Enter Payment Details & Confirm
        StripeSDK-->>Controller: Payment Success
        Controller->>Firebase: Push Appointment to /doctors and /patients trees
        Firebase-->>Controller: Acknowledged (uniqueKey)
        Controller-->>Patient: Display Success Snackbar & Navigate to Home
    else Slot is Booked
        Controller-->>Patient: Show "Slot Booked" Warning Snackbar
    end
```

---

## ✨ Core Features

- 📅 **Interactive Calendar & Slot Booking**: Rolling 7-day calendar picker paired with automated 20-minute slot matrix (09:00 AM – 03:20 PM) and real-time conflict prevention.
- 💳 **Seamless In-App Stripe Payments**: Native `flutter_stripe` integration supporting `PaymentSheet` modal checkouts with full transaction confirmation.
- 🤖 **AI Medical Companion (GPT-4o-mini)**: Context-aware AI chatbot programmed with strict clinical guardrails, automated disclaimers, and emergency escalation advisories.
- 🔄 **Bidirectional Firebase Synchronization**: Synchronous dual-record creation under both doctor and patient trees for comprehensive consultation history.
- ⚡ **Reactive State Management with GetX**: Ultra-fast UI state mutations, snackbar management, and memory-efficient dependency injection.
- 🩺 **Specialization Taxonomy**: Multi-tier directory categorized by medical specialties with doctor bios, contact data, and consultation rates.

---

## 📱 Key Screens & Modules

| Module / Controller | Primary Responsibility | Technical Details |
|---|---|---|
| **`AppointmentBookingController`** | Doctor details, date/slot matrix, and payment workflow | Queries Firebase `doctors` & `patients` refs, validates slot availability, coordinates Stripe PaymentSheet |
| **`ChatbotController`** | Conversational health triage & OpenAI integration | Implements exponential backoff retry loops, temperature control (0.3), token throttling, and clinical safety system prompts |
| **`AppointmentBookingScreen`** | User date & slot picker interface | Displays horizontal calendar chips, responsive slot grid with dynamic booking status states |
| **`ChatbotScreen`** | Conversational medical chat interface | Reverse-scrolling message list with custom user and assistant speech bubbles and typing indicators |

---

## 🛠️ Technology Stack

| Component / Layer | Technology | Version | Purpose |
|---|---|---|---|
| **Framework** | Flutter | `>=3.0.0` | Cross-platform mobile UI development |
| **Language** | Dart | `>=3.0.0` | Sound null-safety application code |
| **State Management** | `get` (GetX) | `^4.6.6` | Reactive controller binding, routing & snackbars |
| **Payments** | `flutter_stripe` | `^10.1.1` | Native mobile Stripe PaymentSheet integration |
| **AI LLM** | OpenAI REST API (`gpt-4o-mini`) | `v1` | Medical conversational triage and guidance |
| **Cloud Database** | `firebase_database` | `^11.0.0` | Real-time JSON tree doctor and patient storage |
| **HTTP Client** | `http` | `^1.2.0` | REST API communication for Stripe and OpenAI |
| **Date & Time** | `intl` | `^0.19.0` | ISO date formatting and time-slot serialization |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK (3.0.0+)** installed and configured.
- **Android Studio / Xcode** for mobile builds.
- A **Stripe Account** with Publishable and Secret API keys.
- An **OpenAI API Key** with access to `gpt-4o-mini`.
- A **Firebase Realtime Database** instance.

### Configuration

1. **Stripe API Setup**:
   Configure your publishable key in `AppointmentBookingController`:
   ```dart
   Stripe.publishableKey = "pk_test_YOUR_STRIPE_PUBLISHABLE_KEY";
   ```
2. **OpenAI API Setup**:
   Add your OpenAI API key in `ChatbotController` (or bind via secure environment configuration):
   ```dart
   final apiKey = "sk-YOUR_OPENAI_API_KEY";
   ```
3. **Firebase Configuration**:
   Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed in their respective platform directories.

### Build & Run

```bash
# Clone the repository
git clone https://github.com/shayann07/medicare_app_flutter.git
cd medicare_app_flutter

# Install Flutter dependencies
flutter pub get

# Run on an emulator or connected device
flutter run
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) — Copyright (c) 2026 [shayann07](https://github.com/shayann07).
