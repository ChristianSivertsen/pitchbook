# Pitchbook implementation plan

Pitchbook is an iPhone app for logging climbing in as much detail as you want, then turning that log into insights and a climbing CV. This plan breaks the work into milestones. Each milestone is a set of GitHub issues, and each issue is one pull request small enough to review in one sitting.

The clickable prototype in [`prototype/index.html`](../prototype/index.html) is the reference for screens and behaviour.

## How the work is reviewed

- One issue = one branch = one pull request. Branches are named `<issue-number>-short-name`, for example `12-grade-conversion`.
- Every PR says what changed, how to test it, and includes screenshots for UI changes.
- Every PR builds and passes tests in CI before review.
- Milestones are done in order. Within a milestone, issues are listed in the order they should be built.
- At the end of each milestone a build goes to TestFlight so you can try it on your phone.

## Tech stack

| Part | Choice | Why |
|---|---|---|
| App | Swift 6, SwiftUI, iOS 18+ | Native, modern concurrency |
| Local database | SQLite with GRDB | Real SQL for stats (GROUP BY, window functions), works offline |
| Charts | Swift Charts | Native, accessible |
| Maps and location | MapKit, CoreLocation | Crag maps, location for weather |
| Weather | WeatherKit | Historical weather for the session's date and place |
| Media | PhotosUI, AVFoundation | Photo and video picking, compression |
| Backend | Supabase (Postgres, Auth, Storage, Edge Functions) | Accounts, social data, row-level security |
| Sync | PowerSync | Offline-first sync between SQLite and Postgres |
| Push | APNs, sent from a Supabase Edge Function | Social notifications |
| Local reminders | UserNotifications | Gear, shoe and goal reminders |
| Tests | Swift Testing | Unit tests for rules, stats and the data layer |
| CI and delivery | GitHub Actions, Xcode Cloud or fastlane | Build on every PR, upload to TestFlight |

### Code layout

```text
Pitchbook/                 Xcode app target (SwiftUI screens, navigation)
Packages/
  PitchbookCore/           Pure Swift: models, grade conversion, ascent rules, stats, insights, XP
  PitchbookData/           GRDB schema, migrations, repositories, sync adapters
  PitchbookUI/             Design tokens, shared components, illustrations (gear, shoes, topo)
supabase/                  SQL migrations, row-level security policies, edge functions
prototype/                 HTML prototype (reference only)
docs/                      This plan and decision notes
```

Core logic lives in `PitchbookCore` with no UI or database code, so the important rules (tries per style, grade conversion, stats) are easy to test and review.

## Decisions already made

1. **Routes.** One shared route database. Each route has a consensus grade. Each ascent stores the official grade at the time of logging and your personal grade or feel. New routes are checked against nearby routes with similar names to avoid duplicates. Duplicates can be merged later without losing history. Anyone can suggest edits. Private routes exist for secret boulders and projects.
2. **Partner tagging.** Tagging sends a request. When accepted, a linked copy of the session is added to the partner's log, which they edit themselves. On multipitch routes you choose who led each pitch, and each climber's rack is recorded.
3. **Trips.** Optional level above sessions, with a name, dates, place and people.
4. **Gym climbs.** Temporary gym routes identified by wall, colour and date set. They expire after a per-gym number of weeks or when a wall is marked as reset. Tries add up across sessions, so the same style rules work indoors and outdoors. Gym routes never appear in the outdoor route list.
5. **Sync.** Offline-first. Every write goes to the local database, then syncs. Each row has one owner. Shared sessions are linked copies, and shared routes change only through suggested edits. Conflicts on your own data are resolved per field, last edit wins. Deletes are soft. Media uploads in the background.
6. **Privacy.** Each post is public, friends-only or private, with a default in settings. Photo GPS data is stripped on upload, and a crag or boulder location can be hidden.
7. **Style and tries.** Onsight and flash mean 1 try. A redpoint needs at least 2 tries, counting earlier logged attempts on the same route. A route you have sent before logs as a repeat.

## Milestones

The first ten milestones build a complete personal logbook that works offline with no account. That gets a useful app onto TestFlight early. Accounts, sync and social features come after.

| # | Milestone | What you can test when it is done |
|---|---|---|
| M0 | Foundation | Empty app with tabs, both colour themes, CI, first TestFlight build |
| M1 | Data model and grades | No UI change. Schema, migrations, grade conversion, tests |
| M2 | Outdoor logging | Add crags and routes, log outdoor sessions, edit and delete them |
| M3 | Indoor logging | Gyms with walls and colour ranges, temporary gym routes, indoor sessions |
| M4 | Trips | Group sessions into trips |
| M5 | Photos and videos | Add media to sessions and tag routes |
| M6 | History and insights | Overview, calendar, pyramid, progress, explorer, logbook, insights |
| M7 | Climbing CV | Skill levels, style profile, gap matrix, experience, milestones |
| M8 | Projects and goals | Ticklist, project tracking, goals with progress |
| M9 | Gear and shoes | Rack, gear details, rack per climb, shoes, local reminders |
| M10 | Training benchmarks | Strength and mobility tests with history |
| M11 | Accounts and sync | Sign in with Apple, profile and picture, sync across devices |
| M12 | Shared route database | Consensus grades, duplicate checks, suggested edits, private routes |
| M13 | Social | Friends, feed, kudos, comments, privacy, shared sessions, endorsements |
| M14 | Notifications | Push for social events, notification centre, settings |
| M15 | Topo maker | Draw topos on photos, pitch tables, share images |
| M16 | Polish and release | Share cards, accessibility, performance, App Store readiness |

Not planned yet, tracked with the `future` label: importing past climbs, injuries and training load, conditions reports, live sessions with GPS and Apple Watch, OpenBeta import, data export, offline maps.

## Before the first TestFlight build

These need you, because they involve your Apple account and payment:

1. Install the full Xcode from the App Store, then run `sudo xcode-select -s /Applications/Xcode.app` so command-line builds use it. This Mac currently points at the command-line tools only.
2. Join the Apple Developer Program at developer.apple.com/programs (paid yearly).
3. In App Store Connect, create the app record with a bundle ID such as `com.christiansivertsen.pitchbook`. The App Store name must be unique, so "Pitchbook" may need a variation.
4. Add yourself as an internal tester in TestFlight.
5. For CI uploads, create an App Store Connect API key and add it as GitHub repository secrets (issue M0-6 lists the exact names).
