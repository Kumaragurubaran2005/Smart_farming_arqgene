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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
// Fix for libraries (like Isar) missing the 'namespace' property
subprojects {
    // Define the fix function
    val fixNamespace = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val baseExt = android as com.android.build.gradle.BaseExtension
                if (baseExt.namespace == null) {
                    baseExt.namespace = project.group.toString()
                }
            } catch (e: Exception) {
                // Ignore incompatibility
            }
        }
    }

    // Apply immediately if already evaluated, otherwise wait
    if (project.state.executed) {
        fixNamespace()
    } else {
        project.afterEvaluate { fixNamespace() }
    }
}