allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix namespace and compileSdk for plugins that use outdated values (e.g. isar_flutter_libs)
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        if (androidExt != null) {
            // Fix missing namespace
            if (androidExt.namespace.isNullOrEmpty()) {
                val manifest = file("${project.projectDir}/src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    val pkg = manifest.readText().let { text ->
                        val regex = Regex("""package="([^"]+)"""")
                        regex.find(text)?.groupValues?.get(1)
                    }
                    if (!pkg.isNullOrEmpty()) {
                        androidExt.namespace = pkg
                    }
                }
            }
            // Fix outdated compileSdk
            if (androidExt.compileSdkVersion.toString().contains("android-30")) {
                androidExt.compileSdk = 35
            }
        }
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
