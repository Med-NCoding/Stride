# Stride Local Configuration Setup

To avoid hardcoding sensitive secrets (like API keys) into files tracked by Git, this project uses a dynamic `.plist` loading system for configuration variables.

## How it works

1. **`Config-Template.plist`**: A tracked template file containing placeholder keys.
2. **`Config.plist`**: A local file ignored by Git (`.gitignore` rules) where you store your actual credentials.
3. **`AppConfig.swift`**: Dynamically loads values from `Config.plist` at runtime, falling back to placeholders if the file or keys are missing.

---

## Local Configuration Setup Instructions

If you need to connect to your own Supabase instance:

1. Locate `Stride/Config.plist` in your project folder.
2. Open it in Xcode (or any text editor) and configure the following keys:
   * **`SUPABASE_URL`**: Your Supabase project URL (e.g. `https://xyz.supabase.co`).
   * **`SUPABASE_ANON_KEY`**: Your Supabase client anonymous API key.

### Example XML configuration (`Config.plist`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SUPABASE_URL</key>
	<string>https://your-real-project.supabase.co</string>
	<key>SUPABASE_ANON_KEY</key>
	<string>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.your-real-key</string>
</dict>
</plist>
```

---

## Verifying compilation
Once you configure these values, compile the project using Xcode or build via the command line:
```bash
xcodebuild build -project Stride.xcodeproj -scheme Stride -sdk iphonesimulator -destination 'generic/platform=iOS Simulator'
```
The build system will bundle `Config.plist` into the app resources, and `AppConfig.swift` will read it automatically.
