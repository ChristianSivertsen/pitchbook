---
name: review-pr
description: Review a Sva pull request with two independent reviewer agents, one for security and one for code quality, then post the findings on the PR and fix what is in scope. Use when asked to review a PR or as step 8 of ship-ticket.
---

# Review a pull request

Arguments: a PR number. Without one, use the PR for the current branch (`gh pr view --json number`).

## 1. Gather context

```bash
gh pr view <pr> --json number,title,body,headRefName,files,additions,deletions
gh pr diff <pr> > <scratchpad>/pr-<pr>.diff
```

Find the linked issue from `Closes #<n>` and read it with `gh issue view <n>`.

## 2. Spawn two reviewers in parallel

Send both Agent calls in one message so they run at the same time. Give each the PR number, the path to the saved diff, the issue text, and point them at `CLAUDE.md`, `docs/PLAN.md` and `docs/schema.md`. Do not give them your own opinion of the code; they should form their own.

### Security reviewer prompt

> You are the security reviewer for pull request #<pr> in the Sva repository (Flutter app with a Supabase backend; the repository is public). Read `CLAUDE.md` (especially Safety rules), then the diff at `<path>` and any files it touches. Review only what this PR changes or exposes.
>
> Check for: secrets or keys in code, config, tests or history; the Supabase service-role key reachable from the app; tables or views without row-level security, or policies that let a user read or write another user's private rows (consider `visibility`, friendships, blocks); SQL built from strings; unvalidated input from the network, deep links, notifications or files; personal data in logs, crash reports or analytics; photos uploaded with GPS data; insecure storage of tokens on the device; over-broad app permissions; dependencies that are unmaintained, have a non-permissive licence or known vulnerabilities; anything that deletes user data without confirmation.
>
> For each finding give: severity (critical, high, medium, low), file and line, what can go wrong with a concrete scenario, and a specific fix. Verify each finding against the code; drop anything you can't point to. If there is nothing, say so plainly. Do not comment on style. Do not edit files.

### Code quality reviewer prompt

> You are the code reviewer for pull request #<pr> in the Sva repository. Read `CLAUDE.md`, `docs/PLAN.md` and `docs/schema.md`, the linked issue below, then the diff at `<path>` and the surrounding code.
>
> Check that the change: does what the issue asks and nothing outside its scope; follows the package boundaries (`sva_core` pure Dart, no SQL in screens, no business logic in `sva_ui`); matches the schema and naming conventions; is readable (clear names, small functions, no dead code, comments only where the why is not obvious); handles errors and empty states; follows `docs/TESTING.md`: every "Done when" item has a test at the right layer, named with the ticket code, and no test re-checks behaviour that a lower layer already owns (list any overlapping or missing tests explicitly), with edge cases covered; avoids duplication with existing code; uses Dart and Flutter idioms correctly (immutability, async handling, widget rebuilds, disposal); keeps accessibility (semantic labels, text scaling); follows `docs/DESIGN.md` for UI (theme tokens only, no raw colours, one primary action per screen, writing rules); has no hard-coded user-facing text and every new string exists in both English and Norwegian Bokmål, with natural Norwegian; matches the prototype's behaviour.
>
> For each finding give: severity (blocking, should-fix, nit), file and line, the problem, and a specific fix. Verify each against the code; drop anything speculative. Keep nits few. If the PR is good, say so plainly. Do not edit files.
>
> Issue text: <issue body>

## 3. Consolidate

- Merge both lists, remove duplicates, and check each finding yourself against the code. Drop false positives, noting why.
- Post one comment on the PR with the results:

  ```markdown
  ## Review
  **Security:** <n findings or "no issues found">
  **Code quality:** <n findings or "no issues found">

  | Severity | Area | File | Finding | Action |
  |---|---|---|---|---|
  ```

  `gh pr comment <pr> --body-file <file>`

## 4. Act on findings

- **Critical, high, blocking, should-fix inside the ticket's scope:** fix them on the PR branch with `fix(<scope>): …` commits (`Refs #<n>`), run the verify step from `ship-ticket` again, and push.
- **Medium security findings:** fix unless the fix is clearly outside the scope; then stop and ask the user.
- **Low and nits:** fix if trivial, otherwise list under "Follow-ups" in the PR description.
- **Anything outside the scope:** do not build it. List it as a follow-up and mention it to the user.
- Any critical or high security finding that can't be fixed in this PR blocks the merge and goes to the user.

If fixes were substantial (more than a few lines of logic), run the two reviewers again on the new diff, once.

## 5. Report

Update the review comment, or add a short follow-up comment, listing what was fixed and what was deferred. Return a short summary to the caller: findings by severity, what was fixed, whether the PR is ready to merge under the merge policy.
