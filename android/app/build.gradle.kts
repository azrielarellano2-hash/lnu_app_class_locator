import java.nio.file.Files
import java.nio.file.attribute.DosFileAttributeView

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val projectRoot: File = rootProject.projectDir.parentFile
    ?: error("Could not resolve Flutter project root from android/")

fun clearReadOnlyRecursive(dir: File) {
    if (!dir.exists()) return
    dir.walkTopDown().forEach { f ->
        try {
            Files.getFileAttributeView(f.toPath(), DosFileAttributeView::class.java)?.setReadOnly(false)
        } catch (_: Exception) {
        }
    }
}

fun purgeWindowsJunkFiles() {
    val junkNames = setOf("desktop.ini", "thumbs.db")
    listOf(
        projectRoot,
        layout.buildDirectory.get().asFile,
    ).forEach { root ->
        if (!root.exists()) return@forEach
        root.walkTopDown()
            .maxDepth(20)
            .filter { it.isFile && junkNames.contains(it.name.lowercase()) }
            .forEach { it.delete() }
    }
}

fun prepareWindowsFriendlyBuild() {
    purgeWindowsJunkFiles()
    clearReadOnlyRecursive(File(projectRoot, "assets"))
    val assetIntermediates = layout.buildDirectory.dir("intermediates/assets").get().asFile
    if (assetIntermediates.exists()) {
        clearReadOnlyRecursive(assetIntermediates)
    }
}

tasks.register("purgeWindowsJunk") {
    group = "build setup"
    doLast { prepareWindowsFriendlyBuild() }
}

android {
    namespace = "com.example.lnu_app_class_locator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    androidResources {
        ignoreAssetsPattern += ":desktop.ini:Thumbs.db:~*"
    }

    defaultConfig {
        applicationId = "com.example.lnu_app_class_locator"
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

    packaging {
        resources {
            excludes += setOf(
                "**/desktop.ini",
                "**/Thumbs.db",
                "**/~*",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

gradle.taskGraph.whenReady {
    val prepareBeforePackaging: (org.gradle.api.Task) -> Unit = {
        it.dependsOn("purgeWindowsJunk")
        it.doFirst { prepareWindowsFriendlyBuild() }
    }

    tasks.matching { it.name == "preBuild" }.configureEach(prepareBeforePackaging)
    tasks.matching { it.name.startsWith("merge") && it.name.endsWith("Resources") }.configureEach(prepareBeforePackaging)
    tasks.matching { it.name.startsWith("merge") && it.name.endsWith("Assets") }.configureEach(prepareBeforePackaging)
    tasks.matching { it.name.startsWith("compress") && it.name.endsWith("Assets") }.configureEach(prepareBeforePackaging)
    tasks.matching { it.name.contains("Dex") || it.name.contains("dex") }.configureEach(prepareBeforePackaging)
    tasks.matching { it.name.contains("NativeLib", ignoreCase = true) }.configureEach(prepareBeforePackaging)
}
