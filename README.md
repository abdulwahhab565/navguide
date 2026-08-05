# NavGuide — UENR Smart Campus Navigation

A production-ready Flutter application providing real-time GPS navigation across the **University of Energy and Natural Resources (UENR)** main campus in Sunyani, Ghana.


##  Features

Feature

 Authentication | Firebase Email/Password Login & Registration with role selection (Student / Staff / Visitor) |
 Interactive Map | Dark-styled Google Maps with all UENR campus buildings pre-pinned |
 Smart Search | Full-text search with auto-suggestions across all campus facilities |
 Live Location | Real-time GPS tracking with campus boundary detection |
 Navigation | Turn-by-turn walking directions with distance & ETA display |
 Route Engine | Google Directions API with A\* offline fallback for no-API environments |
 Category Filters | Filter markers by Academic, Administration, Services, Amenities, Restrooms |
 Bookmarks | Save favourite campus locations, persisted to Firestore |
 Profile | User profile screen with membership info and sign-out |
 Offline Mode | Falls back to local routing graph + AppConfig data when offline |



##  Architecture 

lib/
├── config/
│   ├── app_config.dart          ← API keys, campus bounds, pre-populated locations
│   └── firebase_options.dart    ← Firebase platform configuration
├── models/
│   ├── campus_location.dart     ← Location model with Haversine distance util
│   └── user_model.dart          ← User model with bookmarks list
├── services/
│   ├── auth_service.dart        ← Firebase Auth wrapper
│   ├── firestore_service.dart   ← Firestore CRUD + auto-seed locations
│   ├── location_service.dart    ← Geolocator + simulation mode
│   └── navigation_service.dart  ← Google Directions API + A* fallback
├── presenters/
│   ├── auth_presenter.dart      ← Login / Register business logic
│   ├── map_presenter.dart       ← Map state, routing, markers, bookmarks
│   └── search_presenter.dart    ← Search query + history management
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── map/
│   │   └── map_screen.dart      ← Main screen with map, search, routing UI
│   └── profile/
│       └── profile_screen.dart
└── widgets/
    ├── campus_search_delegate.dart   ← SearchDelegate for showSearch()
    ├── location_bottom_sheet.dart    ← Location detail bottom sheet
    └── route_info_card.dart          ← Active navigation card with step display

##  Setup Instructions

 1. Prerequisites
- Flutter SDK `>=3.0.0` — [Install Flutter](https://docs.flutter.dev/get-started/install)
- Android Studio with Android SDK
- Firebase account
- Google Cloud account (for Maps & Directions API)



### 2. Clone & Install Dependencies

bash
cd "C:\Users\WinOS\final year\navguide"
flutter pub get




### 3. Firebase Setup

#### a) Create a Firebase project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project: **NavGuide-UENR**
3. Enable **Authentication** → Sign-in method → **Email/Password** ✓
4. Enable **Cloud Firestore** → Start in **Production mode**

#### b) Add Android app to Firebase
1. Package name: `com.uenr.navguide`
2. Download `google-services.json`
3. Place it at: `android/app/google-services.json`

#### c) Add Web app to Firebase (for web support)
1. Register a web app in Firebase Console
2. Copy the config values into `lib/config/firebase_options.dart`

#### d) Update firebase_options.dart
dart
// lib/config/firebase_options.dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'IzaSyC_eb7-bYyxd6BIW5rkwAUrHTPb_mbuTUc',
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'navguide-uenr',
  storageBucket: 'navguide-uenr.appspot.com',
);


#### e) Firestore Security Rules
Deploy the rules in `firestore.rules`:
bash
firebase deploy --only firestore:rules




### 4. Google Maps & Directions API Key

#### a) Get an API Key
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Enable these APIs on your project:
   - **Maps SDK for Android**
   - **Maps SDK for iOS** *(optional)*
   - **Maps JavaScript API** *(for web)*
   - **Directions API**
3. Create a credential → **API Key**
4. Restrict key to your Android app's SHA-1 fingerprint + package name

#### b) Set the key — Android
In `android/app/src/main/AndroidManifest.xml`, replace:
xml
android:value="YAIzaSyCpMjOU83HIUWrZVG46mDf4p7I3Z4nxXrE"

with your actual key.

#### c) Set the key — Web
In `web/index.html`, replace:
html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY">

with your actual key.

#### d) Set the key — Build time (recommended for CI)
bash
flutter run --dart-define=MAPS_API_KEY=YOUR_KEY_HERE




### 5. Run the App

bash
# Android (connected device or emulator)
flutter run

# Web
flutter run -d chrome

# Release build (Android)
flutter build apk --dart-define=MAPS_API_KEY=YOUR_KEY_HERE
```


## Campus Locations (Pre-populated)


| `admin_block` | Administration Block | Administration | 7.3495, -2.3435 |
| `engineering_block` | Engineering Block | Academic | 7.3502, -2.3442 |
| `it_directorate` | IT Directorate | Services | 7.3488, -2.3425 |
| `library` | University Library | Academic | 7.3491, -2.3431 |
| `cafeteria` | Campus Cafeteria | Amenities | 7.3475, -2.3432 |
| `clinic` | UENR Campus Clinic | Services | 7.3510, -2.3420 |
| `lecture_hall_a` | Lecture Hall Block A | Academic | 7.3498, -2.3415 |
| `lecture_hall_b` | Lecture Hall Block B | Academic | 7.3505, -2.3430 |
| `science_lecture_hall` | Science Lecture Hall | Academic | 7.3482, -2.3445 |
| `washrooms_library` | Washroom (Near Library) | Restrooms | 7.3490, -2.3429 |
| `washrooms_engineering` | Washroom (Engineering) | Restrooms | 7.3500, -2.3440 |

Locations are auto-seeded to Firestore on first launch. You can edit them in the Firebase Console.


## Firebase Security Rules

See `firestore.rules`. Key rules:
- `users/{uid}` — only the authenticated owner can read/write
- `locations/` — any authenticated user can read; only admin can write
- All unauthenticated access is denied



## Simulation Mode

If GPS is unavailable (emulator, web, denied permission), the app automatically enters **Simulation Mode**:
- User location defaults to UENR campus centre
- Location marker becomes draggable on the map
- Navigation routing still fully works using the local A\* engine


##  Limitations (per project scope)
- Internet required for Firebase sync and Google Directions API
- Offline routing via built-in A\* graph covers all 11 campus facilities
- Android and Web only (iOS config not included but can be added)



- **Stack**: Flutter · Firebase · Google Maps · MVP Architecture · Agile Methodology
