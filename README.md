# Say Hi

Flutter MVP for a QR-based social / dating experience: onboarding, zones on a map, stories, chats, and a **Say Hi** action to join venue zones.

## Stack

- Flutter (Material 3)
- [go_router](https://pub.dev/packages/go_router) for navigation (shell + nested routes)
- Maps: `flutter_map` + OSM tiles; location: `geolocator`

Backend (Supabase, etc.) is not wired yet—screens use mock data where needed.

## Requirements

- Flutter SDK compatible with `environment.sdk` in `pubspec.yaml` (see `pubspec.yaml`).

## Run

```bash
flutter pub get
flutter run
```

## Checks (local)

```bash
flutter analyze
flutter test
```

CI runs the same commands on every push and pull request to `main`.

## Release tags (optional)

After meaningful milestones, tag a version (matches `pubspec.yaml` when you bump it):

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## License

Private / unpublished (`publish_to: 'none'` in `pubspec.yaml`).
