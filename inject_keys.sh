#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found. Please create one with your API keys."
  exit 1
fi

# Check if GOOGLE_MAPS_API_KEY is set
if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
  echo "GOOGLE_MAPS_API_KEY not found in .env. Please add it."
  exit 1
fi

echo "Injecting GOOGLE_MAPS_API_KEY into native files..."

# Inject into AndroidManifest.xml
ANDROID_MANIFEST_PATH="./android/app/src/main/AndroidManifest.xml"
if [ -f "$ANDROID_MANIFEST_PATH" ]; then
  sed -i '' "s|android:value="YOUR_GOOGLE_MAPS_API_KEY"|android:value="$GOOGLE_MAPS_API_KEY"|" "$ANDROID_MANIFEST_PATH"
  echo "Updated AndroidManifest.xml"
else
  echo "AndroidManifest.xml not found at $ANDROID_MANIFEST_PATH"
fi

# Inject into AppDelegate.swift
APP_DELEGATE_SWIFT_PATH="./ios/Runner/AppDelegate.swift"
if [ -f "$APP_DELEGATE_SWIFT_PATH" ]; then
  sed -i '' "s|GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")|GMSServices.provideAPIKey("$GOOGLE_MAPS_API_KEY")|" "$APP_DELEGATE_SWIFT_PATH"
  echo "Updated AppDelegate.swift"
else
  echo "AppDelegate.swift not found at $APP_DELEGATE_SWIFT_PATH"
fi

echo "Key injection complete."
