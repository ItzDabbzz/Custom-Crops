pipeline {
    agent any
    
    tools {
        // Make sure Jenkins has JDK configured with this name
        jdk 'jdk21'        // Adjust this to match your Jenkins JDK 21 installation name
    }
    
    environment {
        // Use Gradle wrapper provided in the repo
        GRADLE_WRAPPER = './gradlew'
        // Set Gradle options for CI
        GRADLE_OPTS = '-Xmx1024m -Xms512m -Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Dorg.gradle.configureondemand=true'
        // Set Git user for version banner functionality
        GIT_AUTHOR_NAME = 'Jenkins Build'
        GIT_AUTHOR_EMAIL = 'jenkins@build.local'
        GIT_COMMITTER_NAME = 'Jenkins Build'
        GIT_COMMITTER_EMAIL = 'jenkins@build.local'
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
        
        stage('Build Core') {
            steps {
                echo 'Building core modules...'
                bat "${env.GRADLE_WRAPPER} :api:build :plugin:build --no-daemon --stacktrace"
            }
        }

        stage('Build Compatibility Modules') {
            parallel {
                stage('ASP R1 & R2') {
                    steps {
                        echo 'Building ASP compatibility modules...'
                        bat "${env.GRADLE_WRAPPER} :compatibility-asp-r1:build :compatibility-asp-r2:build --no-daemon"
                    }
                }
                stage('ItemsAdder R1 & R2') {
                    steps {
                        echo 'Building ItemsAdder compatibility modules...'
                        bat "${env.GRADLE_WRAPPER} :compatibility-itemsadder-r1:build :compatibility-itemsadder-r2:build --no-daemon"
                    }
                }
                stage('Oraxen R1 & R2') {
                    steps {
                        echo 'Building Oraxen compatibility modules...'
                        bat "${env.GRADLE_WRAPPER} :compatibility-oraxen-r1:build :compatibility-oraxen-r2:build --no-daemon"
                    }
                }
                stage('Other Compatibility') {
                    steps {
                        echo 'Building other compatibility modules...'
                        bat "${env.GRADLE_WRAPPER} :compatibility-craftengine-r1:build :compatibility-crucible-r1:build :compatibility-nexo-r1:build --no-daemon"
                    }
                }
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