pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
<<<<<<< HEAD
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
=======
            require(flutterSdkPath != null) {
                "flutter.sdk not set in local.properties"
            }
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
<<<<<<< HEAD
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

=======
    // Flutter loader
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // ✅ REQUIRED for Flutter 3.38.5
    id("com.android.application") version "8.2.2" apply false

    // Firebase (unchanged)
    id("com.google.gms.google-services") version "4.3.15" apply false

    // Kotlin (safe & supported)
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}


>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
include(":app")
