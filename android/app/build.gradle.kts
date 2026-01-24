import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.aldamiram"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.aldamiram"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        val localProperties = Properties()
        localProperties.load(rootProject.file("local.properties").inputStream())
        val googleApiKey = localProperties.getProperty("GOOGLE_MAPS_API_KEY") ?: ""

        release {
            signingConfig = signingConfigs.getByName("debug")
            buildConfigField("String", "GOOGLE_MAPS_API_KEY", "\"$googleApiKey\"")
        }
        debug {
            buildConfigField("String", "GOOGLE_MAPS_API_KEY", "\"$googleApiKey\"")
        }
    }
    
    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Keep only the core library desugaring dependency as per Flutter requirements
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
