# Release APK

`encore-release.apk` is the release build of the Encore Android app.

This build talks to the API at `http://10.0.2.2:3000`, which is the host computer when the app runs in the Android emulator. Start the backend first:

```bash
cd backend
npm install
npm start
```

For a real phone, deploy the backend (see `render.yaml`) and build again with its address:

```bash
cd app
flutter build apk --release --dart-define=API_URL=https://your-api.onrender.com
```
