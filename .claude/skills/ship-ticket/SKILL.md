---
name: ship-ticket
description: Plan, build, test and open a pull request for one Sva GitHub issue, staying inside its scope and following CLAUDE.md. Use when asked to work on, ship or implement a ticket, issue number or the next ticket.
---

# Ship a ticket

Arguments: an issue number, or nothing to take the next open ticket in milestone and code order.

Read `CLAUDE.md` first. Its rules win over anything here.

## 1. Pick and understand the ticket

1. If no number was given, find the next ticket:
   `gh issue list --state open --milestone "<lowest open milestone>" --json number,title`
   and take the lowest code (`[M2-1]` before `[M2-2]`). Skip issues labelled `future` or `needs-user-review`.
2. Read the issue: `gh issue view <n> --json title,body,milestone,labels`.
3. Read what it depends on: the relevant parts of `docs/PLAN.md`, `docs/schema.md`, `docs/API.md` if present, `docs/DESIGN.md` for any UI work, and the matching screen in `prototype/index.html`.
4. Check that earlier tickets it builds on are merged. If one is still open in review, branch from that PR's branch and say so in the PR, or pick an independent ticket.

## 2. Decide the scope

Write down, before coding:

- **In scope:** each bullet from the issue's Scope and Done-when lists.
- **Out of scope:** anything nearby that the issue does not ask for.
- **Questions:** anything ambiguous about product behaviour, data model, money or third-party services.

If there are questions, stop and ask the user with the AskUserQuestion tool. Do not guess. Work that can't wait goes on hold; continue only with parts the answer does not affect.

If the ticket is too large for one reviewable PR (roughly over 600 changed lines excluding generated code and tests), propose a split to the user before starting.

## 3. Plan

Write a short plan: files to add or change, tests to write, risks. Keep it in the session's task list. For logic in `sva_core`, write tests first.

## 4. Branch

```bash
git checkout main && git pull --ff-only
git checkout -b <n>-<short-slug>
```

## 5. Build

- Follow the package boundaries and code standards in `CLAUDE.md`.
- Match the prototype's behaviour unless the issue says otherwise. Look, feel and wording follow `docs/DESIGN.md`.
- New dependencies only under the rules in `CLAUDE.md`, with the reason noted for the PR.
- Never put secrets in code, config or tests.
- Commit in small steps with Conventional Commit messages, each with `Refs #<n>` and the co-author trailer.

## 6. Verify

Run everything that applies and fix failures before continuing:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test        # in app/ and every touched package
```

Plus, when relevant: build for Android (`flutter build apk --debug`), build for iOS (`flutter build ios --no-codesign`) if Xcode is available, Supabase tests (`supabase test db`). For UI tickets, run the app in a simulator or emulator and take screenshots of each new screen in light and dark.

Check every item in the issue's "Done when" list. Anything not met is either fixed or explained.

## 7. Open the pull request

Push and open a PR:

```bash
git push -u origin HEAD
gh pr create --title "<type>(<scope>): <summary> (#<n>)" --body-file <file>
```

The body follows `.github/pull_request_template.md`: summary, `Closes #<n>`, what changed, how to test, screenshots, "Done when" checklist with each item ticked or explained, new dependencies with reasons, follow-ups, and the Claude Code footer.

Add the label `needs-user-review` if the merge policy in `CLAUDE.md` says so.

## 8. Review and merge

1. Run the `review-pr` skill on the PR.
2. Wait for CI to pass: `gh pr checks <pr> --watch`.
3. Then follow the merge policy in `CLAUDE.md`:
   - Routine: `gh pr merge <pr> --squash --delete-branch`, then `git checkout main && git pull --ff-only`.
   - `needs-user-review`: tell the user what to look at, and wait. Meanwhile, continue with an independent ticket if there is one.
4. Report in two or three sentences: what shipped, the PR link, anything left as a follow-up.

## When to stop and ask

- The issue is ambiguous, or the prototype and the issue disagree.
- The work needs a schema change not described in `docs/schema.md`.
- A new paid service, account, secret or native dependency is needed.
- A reviewer finding can't be fixed inside the ticket's scope.
- CI fails for reasons outside the change.
