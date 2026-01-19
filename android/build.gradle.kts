import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory
import com.android.build.gradle.LibraryExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

// 🔹 Custom global build directory (Flutter compatible)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

// 🔹 Use same build dir structure for all subprojects
subprojects {
    val newSubprojectBuildDir: Directory =
        newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 🔹 Ensure app is evaluated first (required by Flutter)
subprojects {
    project.evaluationDependsOn(":app")
}

// 🔹 Force namespace for plugins that don't define it (AGP 8+ requirement)
subprojects {
    if (name == "on_audio_query_android") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension> {
                namespace = "com.lucasjosino.on_audio_query"
                compileSdk = 33 // matches plugin's original setting
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

buildscript {
    repositories {
        google()
        mavenCentral()
        maven("https://storage.googleapis.com/download.flutter.io")
        maven("https://www.arthenica.com/maven")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://storage.googleapis.com/download.flutter.io")
        maven("https://www.arthenica.com/maven")
    }
}
