# Genres

Each entry gives the register, the shape, and the rules that differ from the
defaults in SKILL.md. Where a genre is silent on a rule, the default applies.

## Email

**Register:** direct and warm. Closer to speech than any other genre here.
**Shape:** subject line that states the thing, the ask or news in the first
sentence, supporting detail after, one clear next step at the end.
**Length:** as short as the content allows. Most email is twice as long as it
needs to be. Cut words, not information. If the reader would otherwise have to
ask a follow-up question, the answer belongs in the email.

Overrides:

- `please` is correct here. Google bans it in instructions but permits it when
  what you are asking benefits you, inconveniences the reader, or signals a
  problem. That covers most email requests. "Please send the numbers by Friday"
  is right. "Please click Save" is not.
- Contractions are correct. Avoiding them reads as stiff.
- Time anchors are fine. Email is dated by nature.
- Put the ask in the subject line when there is one. "Deploy freeze March 3-7"
  beats "Upcoming changes".
- Never bury the ask below the fold. If the reader stops after one sentence,
  they should still know what you need.
- Bad news uses the de-emphasizing passive. "Over 50 conflicts were found"
  rather than "You created over 50 conflicts."

## Blog post

**Register:** your own voice, informed and specific. Personality is the point.
**Shape:** a claim or a concrete hook up front, evidence in the middle, an
honest assessment at the end. Sentence-case title.
**Length:** whatever the argument needs. Do not pad to a word count.

Overrides:

- Time anchors are correct. "We migrated last spring", "this is now the
  default". Google explicitly exempts blog posts from timeless writing.
- First person is correct, singular or plural.
- The title takes sentence case, same as every other heading. This is the most
  common miss, because title case looks normal in a blog context.
- Specificity beats adjectives. "p95 dropped to 640ms" carries the weight that
  "much faster" does not.
- Figurative language is the failure mode for this genre specifically. Aiming
  for a conversational tone is exactly when metaphors and idioms get in. Watch
  for them hardest when the writing feels like it is going well.

## Announcement and release notes

**Register:** neutral and factual. Slightly more formal than email.
**Shape:** what changed, who it affects, what they need to do, when.
**Length:** short. Detail goes in a linked document.

Overrides:

- Time anchors are correct and expected.
- Lead with the change, not the context. The reader is scanning for whether
  this affects them.
- State required reader action explicitly, or state that none is required.
  Silence on this point generates replies.

## Documentation and README

**Register:** a knowledgeable colleague explaining something to you.
**Shape:** what this is, who it is for, then the task the reader came to do.
**Length:** as long as needed, broken up with descriptive headings.

Overrides:

- Timeless writing applies in full. Strip `new`, `now`, `currently`, `soon`,
  `latest`, `existing`. The reader has no idea what was new when you wrote it.
- Second person throughout. `you`, never `the user`.
- Imperative mood in numbered steps, but not in running prose. A bare
  imperative in the middle of an explanation reads as an order from nowhere.
- State the prerequisite before the instruction, every time.
- Do not document unshipped work.

## Proposal and design document

**Register:** measured, and explicit about uncertainty.
**Shape:** the problem, the constraints, the options considered, the
recommendation with its tradeoff, the risks.
**Length:** front-loaded. Assume most readers stop after the summary.

Overrides:

- Use `must`, `can`, and `might` precisely. Avoid `should`, which hides whether
  something is a requirement or a preference. This distinction is the whole
  value of the genre.
- Name the tradeoff of your recommendation. A proposal with no downside listed
  reads as unexamined.
- Attribute claims. "The load test showed 4k rps" beats "it can handle 4k rps".

## Commit message

**Register:** terse and mechanical.
**Shape:** imperative subject under about 50 characters, blank line, body
wrapped at 72 explaining why rather than what. Match the repository's existing
convention, including Conventional Commits if in use.

Overrides:

- Apply word choice and punctuation only. Skip register, structure, and the
  assumptions line.
- Imperative mood: "Fix the race condition", not "Fixed" or "Fixes".
- The diff already shows what changed. The body exists to explain why.

## Pull request description

**Register:** factual, aimed at a reviewer with no context.
**Shape:** what this changes and why, then anything the reviewer needs in order
to evaluate it: risk, testing performed, deliberate omissions.
**Length:** short. Link to the issue rather than restating it.

Overrides:

- Apply word choice and punctuation only.
- Lead with the reason. A reviewer who understands why can evaluate how.
- Flag what you did not do and why, so it does not read as an oversight.

## Issue writeup

**Register:** factual and reproducible.
**Shape:** what you expected, what happened, how to reproduce it, environment.
**Length:** complete over brief. A missing reproduction step costs a round trip.

Overrides:

- Apply word choice and punctuation only.
- Separate observation from diagnosis. Say what you saw, then say what you
  think it means, and keep the two distinguishable.

## Code comment

**Register:** none. This is not prose for an audience.
**Shape:** one line where possible.

Overrides:

- Apply word choice and punctuation only.
- Explain why, never what. A hidden constraint, a workaround, a subtle
  invariant. Well-named identifiers cover the rest.
- Do not reference the current task, ticket, or pull request.
- If the comment explains what the code does, delete the comment and rename
  the identifiers instead.

## Chat message

**Register:** conversational, and shorter than feels natural.
**Shape:** the point first. Context only if asked.

Overrides:

- Apply word choice only.
- Put the question in the first line. Do not send "quick question" alone and
  make the reader wait.
- One topic per message.
