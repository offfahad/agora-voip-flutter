# Agora VOIP Flutter MVP

This repository contains a Flutter-based MVP for real-time VOIP audio calls using Agora's SDK. It includes three components:

- **Caller App**: Flutter app to initiate call requests.
- **Listener App**: Flutter app to receive and accept calls.
- **Agora Backend**: Node.js/Express server for secure Agora RTC token generation.

The MVP allows callers to request audio calls, notifies listeners via push notifications, and connects the first listener to accept. Firebase handles authentication, Firestore manages call states, and FCM delivers notifications. Call duration tracking and accept/reject dialogs are implemented.

## Features
- Caller: Start call, notify listeners, show duration.
- Listener: Accept/reject calls via dialogs, join first, show duration.
- Backend: Secure token generation.
- Firebase: Auth, Firestore, FCM.

### Caller App
- Email/Password based login (Firebase Auth).
- Trigger call requests with a button.
- Show active register listeners count 
- Send push notifications to listeners.
- Show "waiting for listener" and "call in progress" states.
- First listener to accept joins; others are blocked.
- Display call duration.

### Listener App
- Email/Password login (Firebase Auth).
- Receive call requests via push notifications (foreground/background/terminated).
- Accept/reject calls with dialogs.
- First listener to accept joins; others are blocked.
- Display call duration.

### General
- Uses Agora VOIP SDK for audio calls (no PSTN).
- Backend generates tokens due to client-side errors (`Agora: Error: ErrorCodeType.errTokenExpired,`).
- Firebase for auth, Firestore, and FCM.

## Setup
1. Clone: `git clone https://github.com/your-username/agora-voip-flutter.git`
2. Firebase: Run `firebase init` and `flutterfire configure` in `caller_app`/`listener_app`. Add `google-services.json`, `GoogleService-Info.plist`, and `assets/firebase_service_account.json`.
3. Agora: Add `.env` with `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE`, `API_URL` in apps and backend.
4. Run: `npm start` in `agora_backend`, `flutter run` in apps.

## Contact

For any questions or collaboration inquiries, feel free to reach out via GitHub Issues or connect on LinkedIn.

- Portfolio: [offfahad.netlify.app](https://offfahad.netlify.app/)
- LinkedIn: [linkedin.com/in/offfahad](https://www.linkedin.com/in/offfahad)
- GitHub: [github.com/offfahad](https://github.com/offfahad)
  
