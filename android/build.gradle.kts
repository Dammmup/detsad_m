allprojects {
    extra.set("kotlin_version", "2.1.0")
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.activity:activity:1.9.3")
            force("androidx.activity:activity-ktx:1.9.3")
            force("androidx.fragment:fragment:1.8.5")
            force("androidx.fragment:fragment-ktx:1.8.5")
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
            force("androidx.lifecycle:lifecycle-viewmodel:2.8.7")
            force("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
            force("androidx.lifecycle:lifecycle-runtime:2.8.7")
            force("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
            
            // Force Kotlin libraries to match the compiler version
            force("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.0")
            force("org.jetbrains.kotlin:kotlin-reflect:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-common:2.1.0")
            force("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        }
    }
}
