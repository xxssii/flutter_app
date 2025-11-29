plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.flutter_app"
    // ✅ 수정됨: 35로 설정 (최신 라이브러리 지원을 위해)
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        // ✅ Desugaring 활성화
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.flutter_app"
        // ✅ 23 유지
        minSdk = flutter.minSdkVersion
        targetSdk = 36 // compileSdk와 맞춤
        versionCode = 1
        versionName = "1.0"
        
        // ✅ Multidex 활성화
        multiDexEnabled = true
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
    // ✅ Desugaring 라이브러리 (flutter_local_notifications 요구사항: 2.1.4+)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))
    implementation("com.google.firebase:firebase-analytics")

    // ✅ Multidex
    implementation("androidx.multidex:multidex:2.0.1")
}
