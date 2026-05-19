# GEMINI.md

## Project Overview

This is a Flutter-based mobile application for farmers, named "Arqgene Farmer App". The application is designed to provide a localized experience with support for English, Hindi, and Tamil. It leverages Firebase for phone number-based user authentication and Isar for local database storage.

### Key Features:
*   **Authentication:** Secure phone number login via Firebase Authentication (OTP).
*   **Clean Architecture:** The app follows Clean Architecture principles to ensure scalability and testability.
*   **Voice Assistant:** Integrated AI Voice Assistant using the **Bhasini API** for speech-to-text (ASR) and translation, allowing farmers to navigate and perform actions using voice commands in their native language.
*   **Listing Management:** Farmers can create product listings by taking photos or videos.
*   **Localization:** Complete support for multiple languages (English, Hindi, Tamil).

### Key Technologies:

*   **Framework:** Flutter
*   **Architecture:** Clean Architecture (Domain, Data, Presentation layers)
*   **State Management:** `Provider`
*   **Dependency Injection:** `GetIt`
*   **Authentication:** Firebase Authentication (Phone OTP)
*   **Local Database:** Isar
*   **Voice AI:** Bhasini API (ASR + Translation)
*   **Localization:** `easy_localization`
*   **Location:** `geolocator` and `geocoding`

### Architecture Structure:

The project is refactored into a feature-based Clean Architecture:

*   `lib/core`: Shared utilities, constants (e.g., `BhasiniConfig`), and base classes (`UseCase`, `Failure`).
*   `lib/features/auth`: Handles authentication logic.
    *   `domain`: Entities (`UserEntity`), Repositories (`AuthRepository`), and UseCases.
    *   `data`: Models (`UserModel`), Datasources (`AuthRemoteDataSource`), and Repository Implementations.
    *   `presentation`: `AuthProvider`, Screens (`LoginScreen`), and Widgets.
*   `lib/features/voice_assistant`: Handles voice interaction.
    *   `services`: `VoiceRecorderService` (Record audio), `BhasiniApiService` (API calls), `CommandProcessor` (Intent mapping).
*   `lib/screens`: Legacy screens being incrementally refactored (e.g., `HomeScreen`, `ProfileScreen`).
*   `lib/db`: Isar database services and schemas.
*   `lib/injection_container.dart`: Service locator setup.

## Building and Running

### Prerequisites:

*   Flutter SDK installed.
*   An Android or iOS emulator/device.
*   A `google-services.json` file for Android and `GoogleService-Info.plist` for iOS.
*   **Bhasini API Credentials:** You must configure your API keys in `lib/core/constants/bhasini_config.dart`.

### Commands:

*   **Get dependencies:**
    ```bash
    flutter pub get
    ```

*   **Run the app:**
    ```bash
    flutter run
    ```

*   **Generate Code (for Isar/Freezed/JsonSerializable):**
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

## Development Conventions

*   **State Management:** Use `Provider` for view models/controllers. Logic should reside in the Domain layer (UseCases) or Presentation Providers, not in the UI widgets.
*   **Dependency Injection:** Always register new services and repositories in `lib/injection_container.dart`.
*   **Voice Integration:** To add new voice commands, update `CommandProcessor` in `lib/features/voice_assistant/services/command_processor.dart`.
*   **Localization:** Add new strings to `assets/translations` JSON files and use `tr()`.