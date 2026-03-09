# Agent Workflow

Run as four separate Claude Code sessions, one per step. Each session gets a fresh context so paste the full prompt each time.

## The Flow

```
1. Plan        →  2. Implement     →  3. QA & Test     →  4. Review
(new session)     (new session)       (new session)       (new session)
     ↓                  ↓                   ↓                  ↓
  JSON plan        Production code      Audit + tests     Approve/Reject
```

## Step by Step

### 1. Plan

Open a new Claude Code session. Paste the contents of `prompts/technical_approach.md` followed by your feature description:

```
[contents of technical_approach.md]

Feature: Users can set their weekly training frequency and the app
recommends the best weather windows based on forecast data.
```

Review the JSON it saves to `output/`. This is your source of truth — tweak it before moving on if anything's off.

### 2. Implement

New session. Paste the contents of `prompts/implement_plan.md`:

```
[contents of implement_plan.md]

Implement the plan in agents/output/weather_scoring.json
```

Commit when it's done. This gives the code reviewer a clean diff.

### 3. QA & Test

New session. Paste the contents of `prompts/qa_tests.md`:

```
[contents of qa_tests.md]

QA the implementation of agents/output/weather_scoring.json
```

If the audit flags issues, you have two options:
- Go back to step 2 and fix them.
- Fix them yourself and re-run QA.

Commit when tests pass.

### 4. Review

New session. Paste the contents of `prompts/code_review.md`:

```
[contents of code_review.md]

Review the changes for weather scoring (plan: agents/output/weather_scoring.json)
```

If **REJECTED** — fix the blockers and re-run the review.
If **APPROVED** — merge to master.

## Tips

- **Always review the plan JSON before implementing.** It's much cheaper to fix a bad plan than bad code.
- **One feature per cycle.** Don't batch multiple features into one plan.
- **Commit between steps** so the code review has a clean diff and you have rollback points.
- **You can skip steps.** Small bug fix? Skip straight to implement and review. No need to plan a one-line change.
- **The plan is the contract.** QA and review both check against it, so if you change direction mid-implement, update the JSON too.
