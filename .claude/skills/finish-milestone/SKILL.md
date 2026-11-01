---
name: finish-milestone
description: Close a Sva milestone once all its tickets are merged - verify main, tag a release, write release notes and send test builds to TestFlight and Android testing. Use when the last ticket of a milestone is merged or when asked to release a milestone.
---

# Finish a milestone

Arguments: the milestone code, for example `M2`. Without one, use the lowest open milestone.

## 1. Check it is done

```bash
gh issue list --milestone "<milestone title>" --state open --json number,title
```

- Open issues other than `future` ones: stop and tell the user which are left.
- Open PRs labelled `needs-user-review` for this milestone: stop and remind the user.

## 2. Verify main

```bash
git checkout main && git pull --ff-only
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Run the flow tests (`cd app && flutter test integration_test`) and check that every closed ticket in the milestone has tests named with its code (`grep -rn "M<m>-" packages app supabase`). Then run the app on an iOS simulator and an Android emulator and walk through the manual "Done when" items. Note anything broken as a new issue (label `bug`, same milestone) and fix it with `ship-ticket` before releasing.

## 3. Release notes

Write a short changelog entry in `CHANGELOG.md` under a new version heading. Versions: `0.<milestone number>.0`, for example M2 is `0.2.0`. List what testers can now do, in plain language, plus known issues.

Commit on a branch, open a PR, merge it under the normal merge policy.

## 4. Tag and build

Release pipelines need the user's say under the merge policy. Ask before the first release; after that, releases for completed milestones can go ahead.

```bash
git tag -a v0.<m>.0 -m "Milestone <m>: <title>"
git push origin v0.<m>.0
```

The tag triggers the TestFlight (M0-6) and Android testing (M0-7) pipelines once they exist. Watch the runs with `gh run list --limit 5` and `gh run watch <id>`.

## 5. Close and report

```bash
gh api -X PATCH repos/{owner}/{repo}/milestones/<number> -f state=closed
```

Tell the user: the version, what to test, where the builds are, and known issues.
