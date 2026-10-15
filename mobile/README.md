# AI Diet Coach — Flutter app

```bash
flutter pub get
flutter gen-l10n                 # generates lib/l10n/gen/app_localizations.dart
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
# Run without a backend (DEV ONLY, labeled fakes):
flutter run --dart-define=USE_FAKE_API=true
flutter test
```

Android/iOS platform folders: run `flutter create . --org com.bwpexperts --project-name ai_diet_coach`
once locally to generate `android/` and `ios/` scaffolding for your Flutter version
(kept out of this Phase 1 snapshot so they match your installed SDK exactly).
