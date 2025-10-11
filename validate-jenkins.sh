#!/bin/bash
# Jenkins Build Validation Script for Custom-Crops
# This script validates that the project is ready for Jenkins CI/CD

echo "=== Custom-Crops Jenkins Build Validation ==="
echo

# Check if we're in the right directory
if [ ! -f "build.gradle.kts" ]; then
    echo "❌ Error: build.gradle.kts not found. Are you in the Custom-Crops root directory?"
    exit 1
fi

echo "✅ Found build.gradle.kts"

# Check for Jenkinsfile
if [ ! -f "Jenkinsfile" ]; then
    echo "❌ Error: Jenkinsfile not found"
    exit 1
fi

echo "✅ Found Jenkinsfile"

# Check for JENKINS.md
if [ ! -f "JENKINS.md" ]; then
    echo "⚠️  Warning: JENKINS.md not found (documentation)"
else
    echo "✅ Found JENKINS.md"
fi

# Check Gradle wrapper
if [ ! -f "gradlew" ] && [ ! -f "gradlew.bat" ]; then
    echo "❌ Error: Gradle wrapper not found"
    exit 1
fi

echo "✅ Found Gradle wrapper"

# Check if Git is initialized
if [ ! -d ".git" ]; then
    echo "❌ Error: Git repository not initialized"
    exit 1
fi

echo "✅ Git repository initialized"

# Test Gradle wrapper
echo "🔧 Testing Gradle wrapper..."
if command -v ./gradlew &> /dev/null; then
    ./gradlew --version > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Gradle wrapper is working"
    else
        echo "❌ Error: Gradle wrapper test failed"
        exit 1
    fi
elif command -v gradlew.bat &> /dev/null; then
    # On Windows
    echo "✅ Gradle wrapper (Windows) detected"
else
    echo "❌ Error: Cannot execute Gradle wrapper"
    exit 1
fi

# Check for required Java (optional check)
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    echo "✅ Java found: $JAVA_VERSION"
else
    echo "⚠️  Warning: Java not found in PATH (Jenkins will need JDK configured)"
fi

# Validate project structure
echo "🔧 Validating project structure..."
EXPECTED_MODULES=("api" "plugin" "compatibility")
for module in "${EXPECTED_MODULES[@]}"; do
    if [ -d "$module" ]; then
        echo "✅ Module found: $module"
    else
        echo "⚠️  Warning: Expected module not found: $module"
    fi
done

# Check compatibility modules
echo "🔧 Checking compatibility modules..."
COMPATIBILITY_MODULES=(
    "compatibility-asp-r1"
    "compatibility-asp-r2"
    "compatibility-itemsadder-r1"
    "compatibility-itemsadder-r2"
    "compatibility-oraxen-r1"
    "compatibility-oraxen-r2"
    "compatibility-craftengine-r1"
    "compatibility-crucible-r1"
    "compatibility-nexo-r1"
)

for module in "${COMPATIBILITY_MODULES[@]}"; do
    if [ -d "$module" ]; then
        echo "✅ Compatibility module found: $module"
    else
        echo "⚠️  Compatibility module not found: $module"
    fi
done

echo
echo "=== Validation Summary ==="
echo "🎉 Custom-Crops appears to be Jenkins-ready!"
echo
echo "Next steps:"
echo "1. Commit and push the Jenkinsfile and JENKINS.md to your repository"
echo "2. Configure Jenkins with the instructions in JENKINS.md"
echo "3. Create a new Pipeline job pointing to your repository"
echo "4. Set up webhooks for automatic builds"
echo "5. Consider which compatibility modules you need and ensure their dependencies are available"
echo
echo "For detailed setup instructions, see JENKINS.md"