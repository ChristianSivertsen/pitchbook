# Pitchbook

An app for iPhone and Android for logging climbing in detail, outdoors and in the gym, and turning that log into insights and a climbing CV. Friends can follow, give kudos, comment and share sessions.

- [Implementation plan](docs/PLAN.md): milestones, decisions and how work is reviewed
- [Prototype](prototype/index.html): clickable HTML prototype of the screens (open it in a browser)
- Issues: one issue per pull request, grouped into milestones M0 to M16

Built with Flutter and Supabase. See the plan for the full stack and the API-first architecture.

## Development

Requires Flutter (stable channel). Building for iOS also needs Xcode; building for Android needs Android Studio.

```bash
flutter pub get          # resolve the workspace
tool/check.sh            # formatting, analysis and all tests, same as CI
dart format .            # fix formatting
cd app && flutter run    # run the app on a simulator, emulator or device
```

Analysis rules live in the root `analysis_options.yaml` and apply to the app and every package.
