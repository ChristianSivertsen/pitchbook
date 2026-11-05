# Sva: working rules

Sva is a Flutter app (iOS and Android) with a Supabase backend. Read these before changing anything:

- [docs/PLAN.md](docs/PLAN.md): stack, API-first architecture, decisions, milestones
- [docs/schema.md](docs/schema.md): the data model, shared by drift and Postgres
- [docs/TESTING.md](docs/TESTING.md): test layers, one test per "Done when" item, how to avoid overlapping tests
- [docs/DESIGN.md](docs/DESIGN.md): the Sva design language (colour, type, components, writing). Wins over the prototype on look and feel
- [prototype/index.html](prototype/index.html): reference for screens and behaviour
- `docs/API.md` once it exists (M11-1): the contract every client uses

## Workflow

- Work happens one GitHub issue at a time, using the `ship-ticket` skill. Reviews use the `review-pr` skill.
- One issue = one branch = one pull request. Branch name: `<issue-number>-<short-slug>`, for example `9-grade-conversion`.
- Tickets are built in milestone order, and in code order within a milestone, unless the issue says otherwise.
- Stay inside the ticket's scope. Anything else found along the way goes in the PR description under "Follow-ups" and is raised with the user, not built.
- When something in a ticket is unclear or a decision belongs to the user, stop and ask. Do not guess on product behaviour, data model changes or anything that costs money.

## Merge policy

After both review agents pass and CI is green:

- **Routine PRs:** Claude merges with a squash merge and continues to the next ticket.
- **Stop for the user's review** when a PR touches any of these:
  - the data schema or migrations (drift or Supabase)
  - security: auth, row-level security, permissions, secrets, tokens
  - sync (PowerSync rules, conflict handling)
  - deleting user data, account deletion
  - payments, store submissions, signing and release pipelines
  - a new third-party service or a dependency with native code

  Label these PRs `needs-user-review`, ask the user, and wait. Independent tickets may continue on separate branches meanwhile.

## Commits

- Conventional Commits: `feat(scope): summary`, `fix(scope): …`, `test(scope): …`, `chore(scope): …`, `docs(scope): …`, `refactor(scope): …`.
- Scope is the package or area: `core`, `data`, `ui`, `app`, `supabase`, `ci`.
- Summary in the imperative, under 72 characters. Body explains why, not what. Reference the issue: `Refs #12` in commits, `Closes #12` in the PR.
- End every commit message with:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
- End every PR description with:
  `🤖 Generated with [Claude Code](https://claude.com/claude-code)`
- Small, focused commits. Never commit generated build output.

## Safety rules (never break these)

- Never commit secrets: API keys, service-role keys, keystores, `.p8` files, `.env` files, Firebase service accounts. Use GitHub secrets and local untracked files. The repository is public.
- The Supabase service-role key never goes into the app. The app only ever uses the anon key plus the user's session.
- Every Supabase table has row-level security enabled, with a pgTAP test for who can read and write.
- Never edit a migration that has been merged. Add a new one.
- Never force-push `main`, never rewrite published history, never merge with failing checks.
- No logging of personal data (locations, names, notes, tokens). No analytics without the user's say.
- Strip GPS data from photos before upload.
- Input from the network or the user is validated at the boundary.

## Dependencies

- Prefer the Dart and Flutter standard library and packages already in use.
- A new package needs: active maintenance, a permissive licence (MIT, BSD, Apache 2.0), wide use, and a reason in the PR. Pin versions with a caret constraint and commit `pubspec.lock` for the app.
- New packages with native code, or new external services, need the user's review (see merge policy).

## Code standards

- `sva_core` is pure Dart: no Flutter, no database, no I/O. Rules, grade conversion, stats maths, insights and XP live here, with unit tests.
- `sva_data` owns drift tables, migrations, repositories and sync. Screens never write SQL.
- `sva_ui` holds theme tokens, shared widgets and illustrations. No business logic.
- `app/` holds screens, navigation and Riverpod providers.
- Rules that also exist on the server (style and tries, gym route expiry) use shared JSON test cases run against both Dart and Postgres.
- Every behaviour change has tests, following `docs/TESTING.md`: each "Done when" item gets a test at the layer named in the ticket, with the ticket code at the start of the test description (`M1-4: ...`). Each behaviour is tested once, at the lowest layer that can test it. Bug fixes start with a failing test.
- Units are SI in storage; convert only for display. Enumerations are stable keys such as `hold.crimp`.
- All user-facing text is in `app/lib/l10n/app_en.arb` and `app_nb.arb` (Norwegian Bokmål), never hard-coded. A test fails if a key is missing in either language. Widgets in `sva_ui` take their text as parameters.
- UI follows `docs/DESIGN.md`: only theme tokens, never raw colours or font sizes in screens; one primary action per screen; writing rules for all text.
- Accessibility: every interactive widget has a semantic label; respect text scaling.

## Commands

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test                      # in app/ and each package
tool/check.sh                     # everything CI runs (except flow tests)
cd packages/sva_data && dart run build_runner build   # after changing drift tables
cd packages/sva_data && dart run drift_dev schema dump lib/src/database/sva_database.dart drift_schemas/sva/   # after bumping schemaVersion
cd packages/sva_data && dart run drift_dev schema generate drift_schemas/sva/ test/generated_migrations/sva/generated/   # then this
cd app && flutter run --dart-define-from-file=mapbox.json   # with the map; mapbox.json is untracked
swift tool/render_app_icons.swift   # after changing assets/brand/sva-app-icon.svg (macOS)
swift tool/render_brand_pngs.swift  # after changing any SVG in assets/brand (macOS)
```

Add new commands here as tooling is set up.
