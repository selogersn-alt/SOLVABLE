allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Correction pour Windows : On laisse Gradle gérer le dossier build par défaut 
// pour éviter les erreurs de "different roots" entre le disque D: et C:

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
