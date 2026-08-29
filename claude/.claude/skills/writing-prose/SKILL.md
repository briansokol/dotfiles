---
name: writing-prose
description: Use when writing or editing prose that another person will read, including drafting or revising emails, blog posts, announcements, release notes, documentation, README content, proposals, design docs, commit messages, pull request descriptions, issue writeups, code comments, and chat messages.
---

# Writing prose

## Overview

Clarity is mechanical and always applies. Voice is genre-dependent and gets
preserved. A blog post and a deploy-freeze email should sound like different
pieces of writing, and both should be free of hedging, idiom, and ambiguity.

Rules below come from the Google developer documentation style guide, adapted
for general prose.

## Start here

1. Identify the genre in the router. Read `references/genres.md` for that row.
2. State the assumptions in one line, then draft immediately:
   `Assuming: internal team, informative, neutral-direct, ~120 words.`
   Ask a question first only when a missing fact would change the whole piece,
   such as an unknown audience or an unknown ask.
3. Run the self-check against the draft before returning it.

**Short-form exception.** For commit messages, pull request descriptions, issue
writeups, code comments, and chat messages: skip the assumptions line, apply
only the word choice and punctuation rules, and do not announce this skill.
These are already part of a larger task and the ceremony is noise.

## Genre router

| Genre | Register | Notable override |
|---|---|---|
| Email | Direct, warm, contractions | `please` is correct when asking a favor or delivering bad news |
| Blog post | Your own voice, specific | Time anchors correct; sentence-case the title |
| Announcement, release notes | Neutral, factual | Time anchors correct; lead with the change |
| Docs, README | Knowledgeable colleague | Timeless: strip `new`, `now`, `currently`, `soon` |
| Proposal, design doc | Measured, explicit on uncertainty | Use `must` and `might` precisely; never `should` |
| Commit, PR, issue | Terse, mechanical | Why over what; word choice and punctuation only |
| Code comment | None | Why over what; word choice and punctuation only |
| Chat | Conversational, short | Point first; word choice only |

## The six that actually get missed

Baseline testing showed models already handle active voice, `simply`, `just`,
and `please` well. These six are where drafts reliably fail. Check them first.

1. **Sentence case in the title.** Subheadings usually come out right and the
   title comes out in title case. "Six months after moving our API to GraphQL",
   not "Six Months After Moving Our API to GraphQL". No trailing period.
2. **Figurative language.** Idioms and metaphors enter precisely when the
   writing is going well, because reaching for a conversational tone is what
   summons them. `learned the hard way`, `killed the concern`, `move the
   needle`, `deep dive`, `low-hanging fruit`, `unlock`, `supercharge`. Replace
   with the literal claim.
3. **Dangling `this` and `that`.** Put a noun after them. "which is why this
   stayed maintainable" gives the reader nothing. If you cannot name the noun,
   the sentence needs rewriting, not a noun.
4. **Phrasal verbs.** `reach out` becomes `contact`. `go out` becomes `ship` or
   `deploy`. `makes use of` becomes `uses`. Established technical ones stay:
   `set up`, `log in`, `sign in`.
5. **Sentence length and semicolons.** Stay under 26 words. A semicolon joining
   two independent clauses is usually two sentences, and screen readers often
   skip it. Split instead.
6. **Incomplete dates.** Give the four-digit year and spell out the month:
   `March 3-7, 2026`. Never `03/07/26`, which means different dates in
   different countries.

## Always on

**Sentence mechanics.** Active voice, except to emphasize the object, to avoid
assigning blame, or when the actor is irrelevant. Condition before instruction:
"To delete the document, click Delete." Most important information first.
Restore dropped `that` and `then`. Use `can`, `might`, and `must` precisely.

**Word choice.** Cut the kill-list. Use one term per concept, never a synonym
for variety. Use `because`, not `as` or `since`. Keep `only` next to what it
limits. Use inclusive language. Replace `above` and `below` with `preceding`
and `following`. See `references/word-list.md`.

**Structure.** Descriptive sentence-case headings, no gerund in first position.
Introduce a list with a complete sentence, not a fragment the items finish.
Parallel syntax across list items. Numbered lists for sequences only. Link text
that makes sense alone, never `click here` or `this document`.

**Punctuation.** Serial commas. No em dashes, per CLAUDE.md; use a comma,
colon, semicolon, or parentheses. No exclamation marks.

## Self-check

Run against the draft before returning it. Fix what fails.

- [ ] Title and headings in sentence case, no trailing period
- [ ] No idioms, metaphors, or cultural references
- [ ] Every `this` and `that` has a noun after it
- [ ] No sentence over 26 words
- [ ] Dates spelled out with a four-digit year
- [ ] No word from the kill-list survived
- [ ] Time anchors match the genre: stripped for docs, kept for announcements
- [ ] Reader knows what they need to do, if anything
- [ ] No em dashes

## References

- `references/genres.md` for the full entry on the genre you are writing
- `references/word-list.md` for words to cut, swap, and use precisely
- `references/examples.md` for before and after pairs when a rule is ambiguous

## Common mistakes

| Mistake | Fix |
|---|---|
| Applying doc rules to a personal blog post | Register is genre-dependent. Only the clarity rules are universal. |
| Stripping `new` and `now` from an announcement | Timeless writing applies to docs, not to anything dated by nature. |
| Asking the reader four questions before drafting | Infer, state the assumption in one line, draft. Let them correct it. |
| Announcing this skill before writing a code comment | Short-form genres get the rules silently. |
| Swapping a non-inclusive word into an awkward sentence | Rewrite the sentence instead. "allow requests from a range of IPs" beats "allowlist a range". |
