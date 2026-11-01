# Pitchbook implementation plan

Pitchbook is an app for iPhone and Android for logging climbing in as much detail as you want, then turning that log into insights and a climbing CV. This plan breaks the work into milestones. Each milestone is a set of GitHub issues, and each issue is one pull request small enough to review in one sitting.

The clickable prototype in [`prototype/index.html`](../prototype/index.html) is the reference for screens and behaviour.

## How the work is reviewed

- One issue = one branch = one pull request. Branches are named `<issue-number>-short-name`, for example `9-grade-conversion`.
- Every PR says what changed, how to test it, and includes screenshots for UI changes.
- Every PR passes analysis, tests and both platform builds in CI before review.
- Milestones are done in order. Within a milestone, issues are built in the order of their code (M2-1, M2-2, and so on) unless an issue says otherwise.
- At the end of each milestone a build goes to TestFlight (iPhone) and Google Play internal testing (Android).

## Tech stack

| Part | Choice | Why |
|---|---|---|
| App | Flutter (Dart), iOS and Android from one codebase | Friends on both platforms can join; strong custom drawing for charts, gear and topos |
| State and navigation | Riverpod, go_router | Testable state, deep links for share links and notifications |
| Local database | SQLite with drift | Typed SQL for stats (GROUP BY, window functions), works offline |
| Sync | PowerSync (Dart SDK) | Offline-first sync between local SQLite and Postgres; also has a web SDK |
| Backend | Supabase: Postgres, Auth, Storage, Edge Functions | Relational data, row-level security, an API any client can call |
| Sign-in | Sign in with Apple and Google | Covers both platforms |
| Charts | fl_chart plus custom painters | Charts that match the design |
| Maps and location | flutter_map or Google Maps, geolocator | Crag maps, location for weather |
| Weather | Open-Meteo (historical and current), called from an Edge Function | Free historical data, same for every client |
| Media | image_picker, video compression, EXIF stripping | Photos and videos on sessions |
| Push | Firebase Cloud Messaging, sent from an Edge Function | One push service for iOS and Android |
| Local reminders | flutter_local_notifications | Gear, shoe, goal and project reminders without a server |
| Crash reports | Sentry or Firebase Crashlytics | See crashes from testers |
| Tests | Dart tests, widget tests, pgTAP for the database | Rules tested in the app and on the server |
| CI and delivery | GitHub Actions for checks; Codemagic or fastlane for store uploads | Build on every PR, upload to TestFlight and Google Play |

Apple Watch, widgets and Health are later additions, written as small native add-ons next to the Flutter app.

## Architecture: API-first

A web version is likely later, so the backend is the shared API for every client: the iPhone and Android app now, a web app later. Supabase already provides this API, so there is no separate server to build:

- **Tables and views** are exposed as a REST API, protected by row-level security. The same rules apply to every client.
- **Postgres functions** carry operations that change several things at once, such as accepting a shared session, merging routes or applying a suggested edit. Every client calls the same function.
- **Edge Functions** (TypeScript) handle anything that talks to the outside world: push notifications, weather lookups and share images.
- **Auth and Storage** are the same for every client.

The rule is: **anything that must be correct lives on the server.** The app runs the same rules locally so it works offline and responds instantly, and the server checks them again when data syncs.

| Logic | Where | Why |
|---|---|---|
| Data integrity: style and tries rules, repeats, gym route expiry, who can see a post | Postgres (constraints, triggers, functions) | No client or app version can break the data |
| Social operations: friend requests, accepting shared sessions, kudos, endorsements, blocking | Postgres functions | One code path for all clients |
| Shared route data: consensus grades, merges, suggested edits | Postgres functions and scheduled jobs | Computed once on the server |
| Grade systems, attribute definitions, gym colour scales | Data in tables | Every client reads the same definitions |
| Stats, insights, skill levels | Shared Dart package on the local database | Must work offline; Flutter web can reuse it |
| Push, weather, share images | Edge Functions | Server-side and the same for every client |

Rules that exist in both Dart and Postgres (style and tries, gym route expiry) share one set of test cases, run against both, so they cannot drift apart. The API itself is documented in `docs/API.md` (issue M11-1).

### Code layout

```text
app/                       Flutter app (iOS and Android): screens, navigation, state
packages/
  pitchbook_core/          Pure Dart: models, grade conversion, ascent rules, stats, insights, XP
  pitchbook_data/          drift schema, migrations, repositories, PowerSync setup
  pitchbook_ui/            Theme tokens, shared widgets, illustrations (gear, shoes, topo, wall)
supabase/
  migrations/              Postgres schema, row-level security, triggers and functions
  functions/               Edge Functions (push, weather, share images)
  tests/                   pgTAP tests for policies and functions
docs/                      This plan, API.md, schema notes
prototype/                 HTML prototype (reference only)
```

`pitchbook_core` has no UI, database or Flutter code, so the important rules are easy to test, review and reuse in a future web app.

## Decisions already made

1. **Routes.** One shared route database. Each route has a consensus grade. Each ascent stores the official grade at the time of logging and your personal grade or feel. New routes are checked against nearby routes with similar names to avoid duplicates. Duplicates can be merged later without losing history. Anyone can suggest edits. Private routes exist for secret boulders and projects.
2. **Partner tagging.** Tagging sends a request. When accepted, a linked copy of the session is added to the partner's log, which they edit themselves. On multipitch routes you choose who led each pitch, and each climber's rack is recorded.
3. **Trips.** Optional level above sessions, with a name, dates, place and people.
4. **Gym climbs.** Temporary gym routes identified by wall, colour and date set. They expire after a per-gym number of weeks or when a wall is marked as reset. Tries add up across sessions, so the same style rules work indoors and outdoors. Gym routes never appear in the outdoor route list.
5. **Sync.** Offline-first. Every write goes to the local database, then syncs. Each row has one owner. Shared sessions are linked copies, and shared routes change only through suggested edits. Conflicts on your own data are resolved per field, last edit wins. Deletes are soft. Media uploads in the background.
6. **Privacy.** Each post is public, friends-only or private, with a default in settings. Photo GPS data is stripped on upload, and a crag or boulder location can be hidden.
7. **Style and tries.** Onsight and flash mean 1 try. A redpoint needs at least 2 tries, counting earlier logged attempts on the same route. A route you have sent before logs as a repeat.
8. **Platforms.** Flutter for iPhone and Android. Supabase is the API for every client, including a future web app.

## Milestones

The first ten milestones build a complete personal logbook that works offline with no account. That gets a useful app onto testers' phones early. Accounts, sync and social features come after.

| # | Milestone | What you can test when it is done |
|---|---|---|
| M0 | Foundation | Empty app with tabs, both colour themes, CI, first TestFlight and Android test builds |
| M1 | Data model and grades | No UI change. Schema, migrations, grade conversion, ascent rules, tests |
| M2 | Outdoor logging | Add crags and routes, log outdoor sessions, edit and delete them |
| M3 | Indoor logging | Gyms with walls and colour ranges, temporary gym routes, indoor sessions |
| M4 | Trips | Group sessions into trips |
| M5 | Photos and videos | Add media to sessions and tag routes |
| M6 | History and insights | Overview, calendar, pyramid, progress, explorer, logbook, insights |
| M7 | Climbing CV | Skill levels, style profile, gap matrix, experience, milestones |
| M8 | Projects and goals | Ticklist, project tracking, goals with progress |
| M9 | Gear and shoes | Rack, gear details, rack per climb, shoes, local reminders |
| M10 | Training benchmarks | Strength and mobility tests with history |
| M11 | Accounts, API and sync | API contract, server-side rules, sign-in, profile, sync across devices |
| M12 | Shared route database | Consensus grades, duplicate checks, suggested edits, private routes |
| M13 | Social | Friends, feed, kudos, comments, privacy, shared sessions, endorsements |
| M14 | Notifications | Push for social events, notification centre, settings |
| M15 | Topo maker | Draw topos on photos, pitch tables, share images |
| M16 | Polish and release | Share cards, accessibility, performance, App Store and Google Play readiness |

Not planned yet, tracked with the `future` label: web app, public share pages, importing past climbs, data export, injuries and training load, conditions reports, live sessions with GPS and Apple Watch, OpenBeta import, offline maps.

## Before the first test builds

These need you, because they involve your accounts and payment:

**iPhone (TestFlight)**
1. Install the full Xcode from the App Store, then run `sudo xcode-select -s /Applications/Xcode.app`. Flutter needs it to build for iOS on this Mac. This Mac currently points at the command-line tools only. Codemagic can build in the cloud instead.
2. Join the Apple Developer Program at developer.apple.com/programs (paid yearly).
3. In App Store Connect, create the app record with a bundle ID such as `com.christiansivertsen.pitchbook`. The store name must be unique, so "Pitchbook" may need a variation.
4. Add yourself as an internal tester in TestFlight.
5. Create an App Store Connect API key for automated uploads (issue M0-6 lists the secrets).

**Android (Google Play internal testing)**
1. Create a Google Play Console developer account (one-time fee).
2. Create the app with the package name `com.christiansivertsen.pitchbook`.
3. Create an upload key and a service account for automated uploads (issue M0-7 lists the secrets).

Until the Play Console account exists, Android builds can be shared with friends as an APK file.
