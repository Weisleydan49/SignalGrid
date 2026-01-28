#!/bin/bash

set -e

echo "🚀 Starting Flutter Web Build for Netlify"

# Define Flutter version (you can change this to a specific version if needed)
FLUTTER_VERSION="stable"
FLUTTER_HOME="${HOME}/flutter"

# Check if Flutter is already installed
if [ ! -d "$FLUTTER_HOME" ]; then
    echo "📦 Installing Flutter..."
    
    # Clone Flutter repository
    git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION $FLUTTER_HOME
    
    # Add Flutter to PATH
    export PATH="$FLUTTER_HOME/bin:$PATH"
    
    echo "✅ Flutter installed successfully"
else
    echo "✅ Flutter already installed"
    export PATH="$FLUTTER_HOME/bin:$PATH"
fi

# Display Flutter version
echo "📱 Flutter version:"
flutter --version

# Enable web support
echo "🌐 Enabling Flutter web..."
flutter config --enable-web

# Get dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Build for web
echo "🔨 Building Flutter web app..."
flutter build web --release --web-renderer canvaskit

echo "✨ Build completed successfully!"
