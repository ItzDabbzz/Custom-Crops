// Declarative Jenkins pipeline for building Custom-Crops using the Gradle wrapper
pipeline {
    agent any

    tools {
        // Assumes Jenkins has a JDK installation named 'jdk21' configured in Global Tool Configuration
        // Adjust to 'jdk17' or 'jdk11' based on your Jenkins setup and project requirements
        jdk 'jdk21'
    }

    environment {
        // Use Gradle wrapper provided in the repo
        GRADLE_WRAPPER = './gradlew'
        // Set Git user for version banner functionality
        GIT_AUTHOR_NAME = 'Jenkins Build'
        GIT_AUTHOR_EMAIL = 'jenkins@build.local'
        GIT_COMMITTER_NAME = 'Jenkins Build'
        GIT_COMMITTER_EMAIL = 'jenkins@build.local'
        // Gradle options for CI
        GRADLE_OPTS = '-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Dorg.gradle.configureondemand=true'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                // Ensure git is configured for the version banner functions
                bat 'git config user.name "Jenkins Build" || echo "Git config already set"'
                bat 'git config user.email "jenkins@build.local" || echo "Git config already set"'
            }
        }

        stage('Validate') {
            steps {
                // Validate the Gradle wrapper and project structure
                bat "${env.GRADLE_WRAPPER} --version"
                bat "${env.GRADLE_WRAPPER} projects"
            }
        }

        stage('Clean') {
            steps {
                bat "${env.GRADLE_WRAPPER} clean"
            }
        }

        stage('Build') {
            steps {
                // Run build with all subprojects including compatibility modules. Use --no-daemon for CI stability.
                bat "${env.GRADLE_WRAPPER} build --no-daemon --stacktrace"
            }
        }

        stage('Shadow JAR') {
            steps {
                // Build the shadow JAR which is typically the main deliverable
                bat "${env.GRADLE_WRAPPER} shadowJar --no-daemon"
            }
        }

        stage('Build Compatibility Modules') {
            parallel {
                stage('ASP R1 & R2') {
                    steps {
                        bat "${env.GRADLE_WRAPPER} :compatibility-asp-r1:build :compatibility-asp-r2:build --no-daemon"
                    }
                }
                stage('ItemsAdder R1 & R2') {
                    steps {
                        bat "${env.GRADLE_WRAPPER} :compatibility-itemsadder-r1:build :compatibility-itemsadder-r2:build --no-daemon"
                    }
                }
                stage('Oraxen R1 & R2') {
                    steps {
                        bat "${env.GRADLE_WRAPPER} :compatibility-oraxen-r1:build :compatibility-oraxen-r2:build --no-daemon"
                    }
                }
                stage('Other Compatibility') {
                    steps {
                        bat "${env.GRADLE_WRAPPER} :compatibility-craftengine-r1:build :compatibility-crucible-r1:build :compatibility-nexo-r1:build --no-daemon"
                    }
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                // Archive all JAR files and important build artifacts
                archiveArtifacts artifacts: '**/build/libs/*.jar', fingerprint: true, allowEmptyArchive: true
                
                // Archive the main plugin JAR specifically
                archiveArtifacts artifacts: 'plugin/build/libs/*.jar', fingerprint: true, allowEmptyArchive: true
                
                // Archive compatibility module JARs
                archiveArtifacts artifacts: 'compatibility*/build/libs/*.jar', fingerprint: true, allowEmptyArchive: true
                
                // Archive configuration files and resources
                archiveArtifacts artifacts: '**/src/main/resources/**/*.yml', fingerprint: false, allowEmptyArchive: true
                archiveArtifacts artifacts: '**/src/main/resources/**/*.properties', fingerprint: false, allowEmptyArchive: true
                
                // Archive the basic pack if it exists
                archiveArtifacts artifacts: 'CustomCrops_*_Basic_Pack.zip', fingerprint: false, allowEmptyArchive: true
            }
        }

        stage('Package Distribution') {
            steps {
                // Create a distribution package with main plugin and compatibility modules
                script {
                    bat '''
                        mkdir -p dist
                        copy "plugin\\build\\libs\\*.jar" "dist\\" 2>nul || echo "No plugin JAR found"
                        copy "compatibility*\\build\\libs\\*.jar" "dist\\" 2>nul || echo "No compatibility JARs found"
                        copy "CustomCrops_*_Basic_Pack.zip" "dist\\" 2>nul || echo "No basic pack found"
                    '''
                }
                archiveArtifacts artifacts: 'dist/**', fingerprint: true, allowEmptyArchive: true
            }
        }

        stage('Publish') {
            when {
                // Only publish on main/master branch or release branches
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'release/*'
                }
            }
            steps {
                echo 'Publishing artifacts...'
                // Add your publish steps here (e.g., Maven, Nexus, etc.)
                // Example: bat "${env.GRADLE_WRAPPER} publish"
            }
        }
    }

    post {
        always {
            // Clean up workspace and stop any Gradle daemons
            echo 'Cleaning up...'
            script {
                try {
                    bat "${env.GRADLE_WRAPPER} --stop"
                } catch (Exception e) {
                    echo 'No Gradle daemons to stop'
                }
            }
        }
        success {
            echo 'Custom-Crops build succeeded!'
            // Add success notifications here (Slack, Discord, etc.)
        }
        failure {
            echo 'Custom-Crops build failed!'
            // Add failure notifications here
        }
        unstable {
            echo 'Custom-Crops build is unstable!'
        }
        changed {
            echo 'Custom-Crops build status changed!'
        }
    }
}