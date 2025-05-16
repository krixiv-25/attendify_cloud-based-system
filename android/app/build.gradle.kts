plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ❌ Removed: apply(plugin = "com.google.gms.google-services")

android {
    namespace = "com.example.attendanceapp_cloud"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Explicitly setting to avoid future NDK issues

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.attendanceapp_cloud"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ❌ Removed Firebase dependencies
}
