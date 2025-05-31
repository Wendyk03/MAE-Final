apply plugin: 'com.android.library'

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// These lines are INVALID in Groovy and should be removed
// val newBuildDir... (Kotlin only)

android {
    namespace 'com.github.rushio.flutterimagecompress'  // ✅ Required for AGP 8+
    compileSdkVersion 33

    defaultConfig {
        minSdkVersion 21
    }
}

dependencies {
    implementation 'androidx.annotation:annotation:1.2.0'
}
