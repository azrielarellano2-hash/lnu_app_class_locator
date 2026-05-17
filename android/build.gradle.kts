import java.io.File
import java.nio.file.Files
import java.nio.file.attribute.DosFileAttributeView

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val flutterRoot: File = rootProject.projectDir.parentFile
    ?: error("Could not resolve Flutter project root from android/")

fun clearReadOnlyRecursive(dir: File) {
    if (!dir.exists()) return
    dir.walkTopDown().forEach { f ->
        try {
            Files.getFileAttributeView(f.toPath(), DosFileAttributeView::class.java)
                ?.setReadOnly(false)
        } catch (_: Exception) {
        }
    }
}

fun purgeWindowsJunkFiles(vararg roots: File) {
    val junkNames = setOf("desktop.ini", "thumbs.db")
    roots.forEach { root ->
        if (!root.exists()) return@forEach
        root.walkTopDown()
            .maxDepth(30)
            .filter { it.isFile && junkNames.contains(it.name.lowercase()) }
            .forEach { it.delete() }
    }
}

fun deleteRecursivelySafe(dir: File) {
    if (!dir.exists()) return
    clearReadOnlyRecursive(dir)
    try {
        dir.deleteRecursively()
    } catch (_: Exception) {
        dir.walkBottomUp().forEach { f ->
            try {
                f.delete()
            } catch (_: Exception) {
            }
        }
    }
}

fun prepareWindowsFriendlyBuild(vararg roots: File) {
    purgeWindowsJunkFiles(*roots)
    roots.forEach { clearReadOnlyRecursive(it) }
}

fun scrubNativeLibIntermediates(buildDir: File) {
    val intermediates = buildDir.resolve("intermediates")
    deleteRecursivelySafe(intermediates.resolve("merged_native_libs"))
    deleteRecursivelySafe(intermediates.resolve("stripped_native_libs"))
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.whenTaskAdded {
        val n = name
        val buildDir = layout.buildDirectory.get().asFile
        val needsPurge =
            n == "preBuild" ||
                n.contains("Dex", ignoreCase = true) ||
                n.contains("dex") ||
                n.contains("NativeLib", ignoreCase = true) ||
                (n.startsWith("merge") &&
                    (n.contains("Lib") ||
                        n.contains("Global") ||
                        n.contains("Assets") ||
                        n.contains("Native")))
        if (!needsPurge) return@whenTaskAdded
        doFirst {
            prepareWindowsFriendlyBuild(
                flutterRoot,
                flutterRoot.resolve("build"),
                buildDir,
            )
            if (n.contains("NativeLib", ignoreCase = true)) {
                scrubNativeLibIntermediates(buildDir)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
