# Mobile UPSGLAM Architecture

## Overview

The UPSGlam mobile application is built with **Flutter**, designed to provide a premium and responsive user experience on Android. It acts as the client-side interface for the UPSGlam microservices ecosystem, communicating via the API Gateway.

## Application Architecture

The application follows a clean layered architecture, ensuring separation of concerns between UI, business logic, and data handling.

### Tech Stack

*   **Framework**: Flutter (Dart)
*   **State Management**: `ValueNotifier` / `ChangeNotifier` (Native Flutter State Management)
*   **Networking**: `http` package for REST API calls
*   **Local Storage**: `shared_preferences` for session persistence (JWT, Settings)
*   **Backend Integration**: Firebase (Auth/Firestore) & Custom Microservices via Gateway
*   **Media**: `image_picker` for camera/gallery access

---

## Project Structure (`lib/`)

| Directory | Description |
| :--- | :--- |
| `config/` | App initialization and global configuration (e.g., `api_config.dart`, `firebase_initializer.dart`). |
| `models/` | Data classes representing backend resources (User, Post, etc.). |
| `services/` | Logic for communicating with backend APIs and Firebase. |
| `views/` | UI screens organized by feature (Auth, Feed, Profile, etc.). |
| `widgets/` | Reusable UI components used across multiple views. |
| `theme/` | Theme definitions (`upsglam_theme.dart`) and palettes. |
| `navigation/` | Routing configuration (`app_router.dart`). |

---

## Service Details

The logic is encapsulated in service classes found in `lib/services/`.

### AuthService (`auth_service.dart`)
*   **Responsibilities**: Handles user registration and login.
*   **Interactions**:
    *   Communicates with the backend `auth-service` endpoints.
    *   Manages JWT tokens and persists them locally.
    *   Handles Firebase authentication flows (if applicable).

### PostService (`post_service.dart`)
*   **Responsibilities**: Manages post creation, fetching feeds, and interactions.
*   **Interactions**:
    *   `GET /posts/feed`: Fetches the personalized feed.
    *   `POST /posts`: Creates new posts (including image upload logic).
    *   `POST /posts/{id}/likes`: Handles liking posts.

### UserService (`user_service.dart`)
*   **Responsibilities**: User profile management.
*   **Interactions**:
    *   Fetches user profiles and avatars.
    *   Manages followers and following lists.

### RealtimePostStreamService (`realtime_post_stream_service.dart`)
*   **Responsibilities**: Handles operational transformation or realtime updates for the feed (likely via Firestore snapshots or polling).

---

## Key Views (`lib/views/`)

*   **Setup**:
    *   `GatewaySetupView`: First screen if API Gateway URL is not configured. Allows dynamic backend connection.
*   **Auth**:
    *   `SplashScreen`: Checks auth state.
    *   `LoginView` / `RegisterView`: User onboarding.
*   **Feed**:
    *   `FeedView`: Main home screen displaying posts.
*   **Create Post**:
    *   `FilterSelectionView`: UI for applying filters (uses backend CUDA service).
*   **Profile**:
    *   `UserProfileView`: Displays user details, stats, and post grid.

---

## Data Flow

1.  **Configuration**:
    *   On launch, the app checks for a stored API Gateway URL. If missing, prompts the user.
2.  **Authentication**:
    *   User authenticates -> App receives JWT -> Stored in secure storage.
    *   JWT is attached to the `Authorization` header of subsequent HTTP requests.
3.  **Feed Loading**:
    *   App requests feed -> Backend aggregates data -> JSON response mapped to `Post` models -> UI renders list.
4.  **Image Processing**:
    *   User selects image -> App sends to backend/CUDA service -> backend returns processed image URL -> App previews it.

---

## Development & Setup

### Prerequisites
*   Flutter SDK (3.10+)
*   Android Studio / VS Code
*   Android device or emulator

### Running Locally
1.  **Dependencies**: Run `flutter pub get` to install packages.
2.  **Configuration**: Ensure `assets/firebase_options.dart` (or `google-services.json`) is correctly set up for your Firebase project.
3.  **Run**:
    ```bash
    flutter run
    ```
4.  **Connect to Backend**:
    *   Ensure your backend Docker services are running.
    *   In the app's **Gateway Setup** screen, enter your computer's local network IP (e.g., `http://192.168.1.5:8080`), NOT `localhost` (as the emulator has its own localhost).

### Build
To build an APK for Android:
```bash
flutter build apk --release
```
