// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Thêm dòng này để kích hoạt Firebase
    id("com.google.gms.google-services") 
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lab_manager"
    compileSdk = flutter.compileSdkVersion
    
    // 1. FIX CỨNG NDK VERSION TẠI ĐÂY
    ndkVersion = "27.0.12077973" 

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.lab_manager"
        
        // 2. FIX CỨNG MIN SDK LÊN 23
        minSdk = 23 
        
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
