# SignalGrid - Netlify Deployment Guide

## 📋 Setup Instructions

### 1. Add Files to Your Repository

Copy these files to the **root** of your SignalGrid repository on the `mobile_lead` branch:

- `netlify.toml` - Netlify configuration
- `build.sh` - Flutter build script

### 2. Commit and Push

```bash
git add netlify.toml build.sh
git commit -m "Add Netlify deployment configuration"
git push origin mobile_lead
```

### 3. Netlify Build Settings

In your Netlify deployment configuration, use these settings:

- **Branch to deploy:** `mobile_lead`
- **Base directory:** (leave empty)
- **Build command:** `chmod +x ./build.sh && ./build.sh`
- **Publish directory:** `build/web`

### 4. Environment Variables (if needed)

If your Flutter app uses environment variables, add them in Netlify:

Example:
- `API_KEY` = `your-api-key`
- `API_URL` = `https://api.example.com`

Then access them in Flutter using:
```dart
const apiKey = String.fromEnvironment('API_KEY');
```

And build with:
```bash
flutter build web --dart-define=API_KEY=$API_KEY
```

## 🎯 What These Files Do

### netlify.toml
- Configures the build command and publish directory
- Sets up URL redirects for Flutter routing
- Adds security headers and caching rules

### build.sh
- Installs Flutter on Netlify's build server
- Enables web support
- Runs `flutter pub get`
- Builds your app with `flutter build web --release`

## 🔧 Customization Options

### Web Renderer

The build script uses `canvaskit` renderer by default. You can change this to `html` if needed:

```bash
flutter build web --release --web-renderer html
```

### Flutter Version

To use a specific Flutter version, modify `FLUTTER_VERSION` in `build.sh`:

```bash
FLUTTER_VERSION="3.16.0"  # or "stable", "beta", "dev"
```

## 🚀 Deploy

Once files are committed and pushed:

1. Go to your Netlify dashboard
2. Click "Deploy SignalGrid"
3. Monitor the build logs
4. Your app will be live at `https://signalgrid.netlify.app`

## 🐛 Troubleshooting

**Build fails?**
- Check Netlify build logs for specific errors
- Ensure `build.sh` has execute permissions
- Verify your `pubspec.yaml` is valid

**Routing issues?**
- The `netlify.toml` includes redirects for Flutter routing
- All routes will redirect to `index.html`

**Slow initial load?**
- CanvasKit renderer is larger but more performant
- Consider using `html` renderer for smaller bundle size

## 📚 Resources

- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Netlify Documentation](https://docs.netlify.com/)
