allprojects {
    repositories {
        google()
        mavenCentral()
    }
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

// Fix for plugins that don't have namespace defined
// This runs before evaluation, so we need to use a different approach
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android.namespace == null) {
            android.namespace = "com.${project.name.replace("-", "_").replace(".", "_")}"
        }
        // Set Java compatibility
        android.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
    }
}

// Force Kotlin JVM target to match the Java target for all subprojects
subprojects {
    plugins.withId("org.jetbrains.kotlin.android") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            val android = project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
            val target = android?.compileOptions?.targetCompatibility?.toString() ?: "11"
            val jvmTargetVal = when (target) {
                "1.8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                "8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                "11" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                "17" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
            }
            compilerOptions {
                jvmTarget.set(jvmTargetVal)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
