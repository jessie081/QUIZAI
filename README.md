# QuizPDF AI

QuizPDF AI is a Flutter study app with:

- real AI chat through a Groq-backed Node backend
- PDF upload and real text extraction
- PDF-grounded AI chat
- AI quiz generation from PDF text
- local quiz saving and review
- offline-first manual quiz creation and cached study history

The app is structured as:

`Flutter app -> Node backend -> Groq API`

## Current State

- AI chat uses the real backend only
- PDF chat uses the same real backend with PDF context
- quiz generation uses the same real backend
- PDF extraction now uses `syncfusion_flutter_pdf`
- saved quizzes are stored locally through `shared_preferences`
- connectivity is tracked with `connectivity_plus`
- cached AI conversations are restored offline
- the last processed PDF is restored offline
- manual quiz building works fully offline

## Important Android Note

This workspace currently does **not** contain an `android/` folder.

Before you can run on Android or build an APK, generate the Android platform
files on a machine with Flutter installed:

```bash
flutter create . --platforms=android,web
```

After Flutter recreates the Android platform, apply the Android networking
settings described below.

## Install Flutter Dependencies

```bash
flutter pub get
```

## Run the Backend

```bash
cd backend
npm install
npm run dev
```

The backend should start on:

```text
http://localhost:8080
```

## Run Flutter with the Backend

### Web

```bash
flutter run --dart-define=QUIZPDF_API_BASE_URL=http://localhost:8080
```

### Android Emulator

```bash
flutter run --dart-define=QUIZPDF_API_BASE_URL=http://10.0.2.2:8080
```

### Real Android Phone on Local Network

Replace `192.168.1.23` with your computer's LAN IP:

```bash
flutter run --dart-define=QUIZPDF_API_BASE_URL=http://192.168.1.23:8080
```

### Release Build with Hosted Backend

For a real installed application, use a public HTTPS backend:

```bash
flutter build apk --release --dart-define=QUIZPDF_API_BASE_URL=https://your-backend-domain.com
```

## Android Networking Setup

After generating the `android/` folder, update these files.

### `android/app/src/main/AndroidManifest.xml`

Add internet permission near the top:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Inside `<application>`, allow local HTTP during development:

```xml
<application
    android:label="quizpdf_ai"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config">
</application>
```
```

### `android/app/src/main/res/xml/network_security_config.xml`

Create this file:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true" />
</network-security-config>
```

Use HTTPS only for production deployments.

## Production Readiness Checklist

- `backend/.env` contains a real `GROQ_API_KEY`
- backend starts with `npm run dev`
- `/health` reports provider working
- Flutter runs with `QUIZPDF_API_BASE_URL`
- PDF upload works
- extracted text is non-empty for real PDFs
- general AI chat returns live responses
- PDF AI chat returns grounded responses
- quiz generation returns structured questions
- quizzes save and reopen locally
- Android platform folder exists
- `flutter analyze` passes
- `flutter build apk --release` succeeds

## Deployment

The backend is prepared for Render deployment. See:

- [backend/README.md](backend/README.md)
- [render.yaml](render.yaml)
