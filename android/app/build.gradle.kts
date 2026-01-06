plugins {
    // Android application plugin
    id("com.android.application")

    // Firebase (Google services)
    id("com.google.gms.google-services")

    // ✅ Correct Kotlin plugin (DO NOT use kotlin-android)
    id("org.jetbrains.kotlin.android")

    // Flutter Gradle plugin (must be LAST)
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
        applicationId = "com.example.busway"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Debug signing for now (safe for development)
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
