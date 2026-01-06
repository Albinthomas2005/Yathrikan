pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) {
                "flutter.sdk not set in local.properties"
            }
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
    // Flutter loader
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // ✅ REQUIRED for Flutter 3.38.5
    id("com.android.application") version "8.2.2" apply false

    // Firebase (unchanged)
    id("com.google.gms.google-services") version "4.3.15" apply false

    // Kotlin (safe & supported)
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}


include(":app")
