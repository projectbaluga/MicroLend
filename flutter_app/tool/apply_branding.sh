#!/usr/bin/env bash
set -euo pipefail

# Apply Branding Overrides Script
# Environment variables expected:
# - ICON_URL: (optional) URL to custom PNG app icon
# - APP_NAME: (optional) Custom application name
# - APP_DESCRIPTION: (optional) Custom app description
# - BRAND_COLOR: (optional) Hex theme/background color (e.g. #18181B)

echo "=== Applying Branding Overrides ==="

# 1. ICON & SPLASH GENERATION (FIRST)
if [ -n "${ICON_URL:-}" ]; then
  echo "Downloading custom app icon from: ${ICON_URL}"
  mkdir -p assets/branding
  if curl -fsSL "${ICON_URL}" -o assets/branding/app_icon.png; then
    cp assets/branding/app_icon.png assets/branding/splash_logo.png
    echo "Generating app icons..."
    dart run flutter_launcher_icons || echo "Warning: flutter_launcher_icons failed"
    echo "Generating splash screens..."
    dart run flutter_native_splash:create || echo "Warning: flutter_native_splash failed"
  else
    echo "Warning: Failed to download icon from ${ICON_URL}. Skipping launcher icon regeneration."
  fi
fi

# 2. APP NAME OVERRIDES
if [ -n "${APP_NAME:-}" ]; then
  echo "Setting App Name: ${APP_NAME}"

  # Android
  if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    sed -i -E "s/android:label=\"[^\"]*\"/android:label=\"${APP_NAME}\"/g" android/app/src/main/AndroidManifest.xml
  fi

  # iOS Info.plist
  if [ -f "ios/Runner/Info.plist" ]; then
    if [ -x "/usr/libexec/PlistBuddy" ]; then
      /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '${APP_NAME}'" ios/Runner/Info.plist || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '${APP_NAME}'" ios/Runner/Info.plist
      /usr/libexec/PlistBuddy -c "Set :CFBundleName '${APP_NAME}'" ios/Runner/Info.plist || /usr/libexec/PlistBuddy -c "Add :CFBundleName string '${APP_NAME}'" ios/Runner/Info.plist
    else
      # Fallback for non-macOS environments (using python or sed regex pattern)
      python3 -c "
import re, sys
path = 'ios/Runner/Info.plist'
with open(path, 'r') as f:
    content = f.read()
content = re.sub(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', r'\g<1>' + sys.argv[1] + r'\2', content)
content = re.sub(r'(<key>CFBundleName</key>\s*<string>)[^<]*(</string>)', r'\g<1>' + sys.argv[1] + r'\2', content)
with open(path, 'w') as f:
    f.write(content)
" "${APP_NAME}"
    fi
  fi

  # Windows Runner.rc & main.cpp
  if [ -f "windows/runner/Runner.rc" ]; then
    sed -i -E "s/VALUE \"FileDescription\", \"[^\"]*\"/VALUE \"FileDescription\", \"${APP_NAME}\"/g" windows/runner/Runner.rc
    sed -i -E "s/VALUE \"InternalName\", \"[^\"]*\"/VALUE \"InternalName\", \"${APP_NAME}\"/g" windows/runner/Runner.rc
    sed -i -E "s/VALUE \"OriginalFilename\", \"[^\"]*\"/VALUE \"OriginalFilename\", \"${APP_NAME}.exe\"/g" windows/runner/Runner.rc
    sed -i -E "s/VALUE \"ProductName\", \"[^\"]*\"/VALUE \"ProductName\", \"${APP_NAME}\"/g" windows/runner/Runner.rc
  fi

  if [ -f "windows/runner/main.cpp" ]; then
    python3 -c "
import re, sys
path = 'windows/runner/main.cpp'
with open(path, 'r') as f:
    content = f.read()
content = re.sub(r'window\.Create\(L\"[^\"]*\"', 'window.Create(L\"' + sys.argv[1] + '\"', content)
with open(path, 'w') as f:
    f.write(content)
" "${APP_NAME}"
  fi

  # Web
  if [ -f "web/index.html" ]; then
    sed -i -E "s/<title>.*<\/title>/<title>${APP_NAME}<\/title>/g" web/index.html
    sed -i -E "s/<meta name=\"apple-mobile-web-app-title\" content=\"[^\"]*\">/<meta name=\"apple-mobile-web-app-title\" content=\"${APP_NAME}\">/g" web/index.html
  fi
  if [ -f "web/manifest.json" ]; then
    sed -i -E "s/\"name\": \"[^\"]*\"/\"name\": \"${APP_NAME}\"/g" web/manifest.json
    sed -i -E "s/\"short_name\": \"[^\"]*\"/\"short_name\": \"${APP_NAME}\"/g" web/manifest.json
  fi
fi

# 3. APP DESCRIPTION OVERRIDES
if [ -n "${APP_DESCRIPTION:-}" ]; then
  echo "Setting App Description..."
  if [ -f "web/index.html" ]; then
    sed -i -E "s/<meta name=\"description\" content=\"[^\"]*\">/<meta name=\"description\" content=\"${APP_DESCRIPTION}\">/g" web/index.html
  fi
  if [ -f "web/manifest.json" ]; then
    sed -i -E "s/\"description\": \"[^\"]*\"/\"description\": \"${APP_DESCRIPTION}\"/g" web/manifest.json
  fi
fi

# 4. BRAND COLOR OVERRIDES
if [ -n "${BRAND_COLOR:-}" ]; then
  echo "Setting Brand Color: ${BRAND_COLOR}"
  if [ -f "web/manifest.json" ]; then
    sed -i -E "s/\"background_color\": \"[^\"]*\"/\"background_color\": \"${BRAND_COLOR}\"/g" web/manifest.json
    sed -i -E "s/\"theme_color\": \"[^\"]*\"/\"theme_color\": \"${BRAND_COLOR}\"/g" web/manifest.json
  fi
fi

# 5. VERIFICATION LOGGING
echo "=== Branding Verification Output ==="
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
  echo "Android Label:"
  grep "android:label" android/app/src/main/AndroidManifest.xml || true
fi

if [ -f "ios/Runner/Info.plist" ]; then
  echo "iOS Info.plist:"
  if [ -x "/usr/libexec/PlistBuddy" ]; then
    /usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" ios/Runner/Info.plist || true
    /usr/libexec/PlistBuddy -c "Print :CFBundleName" ios/Runner/Info.plist || true
  else
    grep -A 1 "CFBundleDisplayName" ios/Runner/Info.plist || true
    grep -A 1 "CFBundleName" ios/Runner/Info.plist || true
  fi
fi

if [ -f "windows/runner/Runner.rc" ]; then
  echo "Windows Runner.rc:"
  grep "VALUE" windows/runner/Runner.rc | grep -E "FileDescription|InternalName|OriginalFilename|ProductName" || true
fi

if [ -f "windows/runner/main.cpp" ]; then
  echo "Windows main.cpp Window Title:"
  grep "window.Create" windows/runner/main.cpp || true
fi

if [ -f "web/index.html" ]; then
  echo "Web title:"
  grep "<title>" web/index.html || true
fi

echo "=== Branding Applied Successfully ==="
