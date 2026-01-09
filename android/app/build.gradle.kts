plugins {
<<<<<<< HEAD
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
=======
    // Android application plugin
    id("com.android.application")

    // Firebase (Google services)
    id("com.google.gms.google-services")

    // ✅ Correct Kotlin plugin (DO NOT use kotlin-android)
    id("org.jetbrains.kotlin.android")

    // Flutter Gradle plugin (must be LAST)
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.busway"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
<<<<<<< HEAD
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.busway"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
=======
        applicationId = "com.example.busway"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName

>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
        multiDexEnabled = true
    }

    buildTypes {
        release {
<<<<<<< HEAD
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
=======
            // Debug signing for now (safe for development)
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
