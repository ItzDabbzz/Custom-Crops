pipeline {
    agent any
    
    tools {
        // Make sure Jenkins has JDK configured with this name
        jdk 'jdk21'        // Adjust this to match your Jenkins JDK 21 installation name
    }
    
    environment {
        // Use Gradle wrapper provided in the repo
        GRADLE_WRAPPER = './gradlew'
        // Set Gradle options for CI - disable toolchain and use system JDK
        GRADLE_OPTS = '-Xmx1024m -Xms512m -Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Dorg.gradle.configureondemand=true -Dorg.gradle.java.installations.auto-detect=false -Dorg.gradle.java.installations.auto-download=false'
        // Set Git user for version banner functionality
        GIT_AUTHOR_NAME = 'Jenkins Build'
        GIT_AUTHOR_EMAIL = 'jenkins@build.local'
        GIT_COMMITTER_NAME = 'Jenkins Build'
        GIT_COMMITTER_EMAIL = 'jenkins@build.local'
        // Override toolchain to use system JDK
        ORG_GRADLE_PROJECT_toolchainVersion = '21'
    }
    
    options {
        // Keep builds for 30 days
        buildDiscarder(logRotator(daysToKeepStr: '30', numToKeepStr: '50'))
        // Timeout after 45 minutes (longer for compatibility modules)
        timeout(time: 45, unit: 'MINUTES')
        // Add timestamps to console output
        timestamps()
    }
    
    triggers {
        // Poll SCM every 5 minutes for changes (adjust as needed)
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
                // Ensure git is configured for the version banner functions
                bat 'git config user.name "Jenkins Build" || echo "Git config already set"'
                bat 'git config user.email "jenkins@build.local" || echo "Git config already set"'
            }
        }
        
        stage('Build Info') {
            steps {
                script {
                    echo "Building branch: ${env.BRANCH_NAME}"
                    echo "Build number: ${env.BUILD_NUMBER}"
                    echo "Java version check:"
                    bat 'java -version'
                    echo "Gradle version check:"
                    bat "${env.GRADLE_WRAPPER} --version"
                    echo "Project structure:"
                    bat "${env.GRADLE_WRAPPER} projects"
                }
            }
        }
        
        stage('Clean') {
            steps {
                echo 'Cleaning previous builds...'
                bat "${env.GRADLE_WRAPPER} clean"
            }
        }
        
        stage('Compile') {
            steps {
                echo 'Compiling the project...'
                bat "${env.GRADLE_WRAPPER} compileJava"
            }
        }
        
        stage('Build All Modules') {
            steps {
                echo 'Building all modules with proper dependency order...'
                bat "${env.GRADLE_WRAPPER} build --no-daemon --stacktrace"
            }
        }
        
        stage('Package') {
            steps {
                echo 'Packaging the project...'
                bat "${env.GRADLE_WRAPPER} shadowJar --no-daemon"
            }
        }
        
        stage('Install') {
            when {
                anyOf {
                    branch 'master'
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                echo 'Installing to local repository...'
                bat "${env.GRADLE_WRAPPER} publishToMavenLocal"
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            // Archive the built JARs
            archiveArtifacts artifacts: '**/build/libs/*.jar', 
                           fingerprint: true, 
                           allowEmptyArchive: true
            
            // Archive the main plugin JAR specifically
            archiveArtifacts artifacts: 'plugin/build/libs/*.jar', 
                           fingerprint: true, 
                           allowEmptyArchive: true
            
            // Archive compatibility module JARs
            archiveArtifacts artifacts: 'compatibility*/build/libs/*.jar', 
                           fingerprint: true, 
                           allowEmptyArchive: true
            
            // Archive configuration files for reference
            archiveArtifacts artifacts: '**/src/main/resources/**/*.yml', 
                           fingerprint: true, 
                           allowEmptyArchive: true
            
            // Archive the basic pack if it exists
            archiveArtifacts artifacts: 'CustomCrops_*_Basic_Pack.zip', 
                           fingerprint: false, 
                           allowEmptyArchive: true
            
            // Stop any Gradle daemons
            script {
                try {
                    bat "${env.GRADLE_WRAPPER} --stop"
                } catch (Exception e) {
                    echo 'No Gradle daemons to stop'
                }
            }
        }
        
        success {
            echo 'Build completed successfully!'
            script {
                if (env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'main') {
                    echo 'Master/Main branch build succeeded - artifacts are ready for deployment'
                }
            }
        }
        
        failure {
            echo 'Build failed!'
            // You can add notification steps here (email, Slack, etc.)
        }
        
        unstable {
            echo 'Build completed with test failures'
        }
        
        cleanup {
            // Clean up workspace if needed
            deleteDir()
        }
    }
}