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
    
    // Fix for image_gallery_saver namespace issue
    afterEvaluate {
        if (project.name == "image_gallery_saver") {
            try {
                val android = project.extensions.getByName("android")
                val androidClass = android.javaClass
                val namespaceField = androidClass.getDeclaredField("namespace")
                namespaceField.isAccessible = true
                val currentNamespace = namespaceField.get(android) as String?
                if (currentNamespace.isNullOrEmpty()) {
                    namespaceField.set(android, "com.example.image_gallery_saver")
                }
            } catch (e: Exception) {
                // If reflection fails, the PowerShell script should have already fixed it
                println("Note: Namespace fix for image_gallery_saver - if build fails, run fix_image_gallery_saver.ps1")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
