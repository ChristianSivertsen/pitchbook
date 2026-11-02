---
name: project-summary
description: Review what has been built in Sva and write a clear, plain-language summary of the code and the decisions made, for the user. Use when asked for a summary, overview, status, recap or review of the work so far, or "what did we do today".
---

# Project summary

Arguments: optionally a period ("today", "since #105", "M2") or a topic. Without one, cover everything since the last summary the user asked for (or the whole project if there was none), with the newest work first.

The reader is the project's owner. They make the product calls but do not read every diff. Write for them: what exists now, why it is that way, and what is waiting for them. Follow the writing rules in `docs/DESIGN.md`: short sentences, plain words, no hype.

## 1. Gather the facts

Collect these yourself; never summarise from memory alone.

- Merged work: `git log --oneline` for the period, and `gh pr list --state merged --limit 30 --json number,title,mergedAt`.
- Open pull requests and what each waits for: `gh pr list --json number,title,labels,headRefName` and `gh pr checks <n>`. A `needs-user-review` label means it waits for the user.
- Tickets: `gh issue list --state closed` and `--state open` with milestones, to say what is done and what is next.
- The code itself: package layout and sizes (`find packages app -name '*.dart' -not -name '*.g.dart' -not -path '*/generated*' | xargs wc -l`), and the files the period touched (`git diff --stat <from>..main`). Read the main new files enough to describe them correctly.
- Decisions: PR descriptions ("Decisions made here", "Your call", "Follow-ups"), `docs/PLAN.md` decisions and costs, `docs/schema.md`, and decisions the user made in the conversation. Note which decisions were the user's and which were made in the code and are easy to change.

## 2. Write the summary

Use exactly these sections, in this order. Leave a section out only when it would be empty, and say so in one line under "Where things stand".

```
# Sva: <period> in summary

## Where things stand
Two to four sentences: what works now from the user's point of view,
which milestone we are in, and the one thing waiting for the user.

## What was built
A table, newest first:
| Ticket | What you can do now | PR |
One row per ticket. The middle column describes behaviour, not code.

## How the code is organised
A short table of packages (sva_core, sva_data, sva_ui, app) with what
each holds and its rule. Then a few bullets on what is new in each,
naming the main files as links, for example
[session_logger.dart](packages/sva_data/lib/src/repositories/session_logger.dart).

## Decisions
Two groups:
### Yours
Decisions the user made, with the date, and where they are recorded.
### Made in the code (easy to change)
Choices made while building, one bullet each: the choice, why, and what
changing it would take. Group by theme (data, privacy, UI, process).

## Waiting for you
A numbered list of open questions and PRs that need the user, each with
the choice to make and a recommendation. Empty list: say "Nothing".

## Known gaps and follow-ups
Bullets, grouped by the milestone that will handle them.

## Next up
The next one to three tickets, one line each.
```

Rules for the content:

- Lead every bullet with the point, then the reason. One idea per bullet.
- Describe behaviour in the user's words ("logging a known route takes 4 taps"), and code only where it helps to find it.
- Link PRs and issues with full URLs (`https://github.com/ChristianSivertsen/sva/pull/<n>`), and files as relative markdown links.
- Use tables where items share the same fields; use bullets otherwise. No walls of text: no paragraph over four lines.
- Numbers must come from the commands above (tests, lines, PR counts). Do not guess.
- Be honest about state: say what is not merged, not tested on a device, or failing.
- Keep it to what a reader can take in within five minutes, about one screen per section at most.

## 3. Deliver it

Give the summary in the chat. If the user asks for something to share or keep, publish it as a page instead and give the link.
