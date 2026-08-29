# Word list

Words to cut, swap, or use precisely. Sourced from the Google developer
documentation style guide, filtered to entries that matter for general prose.

## Cut these

Delete the word. The sentence almost always means the same thing without it.

| Word | Why | Fix |
|---|---|---|
| `just` | Filler. Deletable without changing meaning. | "BigQuery skips the row." not "BigQuery just skips the row." |
| `simply`, `simple` | What is simple for you may not be simple for the reader. | Delete it. Never assert that the task you are assigning is easy. |
| `easy`, `easily` | Same problem. | Delete it. |
| `quick`, `quickly` | Same problem. | Delete it. |
| `obviously`, `clearly`, `of course` | If it were obvious the reader would not be reading. | Delete it. |
| `please note`, `note that` | Placeholder phrase carrying no information. | Delete it, or state the point directly. |
| `at this time` | Time anchor plus filler. | Delete it. |
| `basically`, `actually`, `really` | Hedges. | Delete it. |

`just` has one legitimate use: conveying that one approach is simpler than
another. Prefer `just` over `simply` in that narrow case.

## Direct swaps

| Do not use | Use instead |
|---|---|
| `in order to` | `to` (keep `in order to` only when dropping it garbles the parse) |
| `utilize`, `utilization` | `use` (keep `utilization` for quantity of a resource consumed) |
| `leverage` | `use`, `build on`, `take advantage of` |
| `allows you to`, `enables you to` | `lets you` |
| `via` | `through`, `by`, `using` |
| `e.g.` | `for example`, `such as` |
| `i.e.` | `that is` |
| `vs.` | `versus` |
| `aka` | `also known as`, or parentheses, or `or` |
| `etc.`, `and so on`, `and so forth` | Rewrite with `such as` or `including`, which already signal a partial list |
| `vice versa` | State both directions explicitly |
| `comprise` | `consist of`, `contain`, `include` |
| `desire`, `desired`, `wish` | `want`, `need` |
| `learnings` | `what we learned`, `findings` |
| `and/or` | Pick one, or write `A, B, or both` |
| `impact` (verb) | `affect` |
| `access` (verb) | `see`, `edit`, `find`, `use`, `view` |
| `surface` (verb) | `expose`, `make available` |
| `functionality` | `features`, `capabilities` |
| `performant` | A precise term: `fast`, `accurate`, `memory-efficient` |
| `actionable` | `useful`, `that you can act on` |
| `for instance` | `for example`, `such as` |
| `N/A` | `not available` or `not applicable`, spelled out |
| `tl;dr` | `To summarize` |
| `single pane of glass` | `unified interface` |

## Ambiguous words

| Word | Problem | Fix |
|---|---|---|
| `as` | Can mean `because` or `while`. | Use `because` for causation. |
| `since` | Can mean `because` or `from that time`. | Use `because` for causation. |
| `once` | Can mean `after` or `one time`. | Use `after` for sequence. |
| `while` | Can mean `although` or `during`. | Use `although` for contrast. |
| `this`, `that` | Dangling reference. | Put a noun after it: "this migration", not "this". |
| `each` | Not a synonym for `all`. | "a list of all the items", not "a list of each item". |
| `either` | Needs parallel syntax, and only works for two things. | "Do either option 1 or option 2." |
| `neither` | Pairs with `nor`. | `neither A nor B` |
| `using` | Can attach to the wrong noun. | Use `by using` or `that use`. |
| `with` | Vague for ownership or instrument. | "A handset that has 2 GB of RAM", not "with 2 GB". |
| `per` | Only for rate units. | `requests per day`, but `according to the style guide`. |
| `only` | Must sit next to what it limits. | "Request only one token", not "Only request one token". |

## Modal verbs

Precision about obligation.

| Word | Means |
|---|---|
| `can` | Permission, ability, or a possible outcome. |
| `might` | Possibility or uncertain outcome. |
| `must` | A hard requirement. |
| `should` | Avoid. Ambiguous between recommendation and requirement. Say `we recommend` or `must`. |
| `may` | Avoid except for policy and legal. Use `can` or `might`. |
| `will`, `would` | Avoid. Write in present tense. |

## Time anchors

Genre-conditional. Strip these from anything meant to be read for months
(documentation, README, policy, onboarding). Keep them in anything dated by
nature (blog posts, release notes, announcements, incident updates).

`currently`, `now`, `soon`, `eventually`, `as of this writing`, `does not yet`,
`in the future`, `new`, `newer`, `latest`, `existing`, `old`, `older`,
`presently`, `at present`

Timeless: "Windows is not supported." Dated: "Windows is not currently supported."

One exception even in timeless text: an explicit past-to-present comparison.
"In versions earlier than 1.10 you could use only the default value, but now
you can assign a custom value."

## Inclusive language

### Gendered

| Do not use | Use instead |
|---|---|
| `he`, `she` for an unknown person | `they`, `their` (takes a plural verb) |
| `guys`, `you guys` | `everyone`, `folks`, `all` |
| `manpower` | `staff`, `workforce` |
| `man-hours` | `person-hours` |
| `manmade` | `artificial`, `manufactured`, `synthetic` |
| `manned` | `staffed`, `crewed` |
| `mankind` | `humanity`, `people` |
| `man-in-the-middle` | `on-path attacker`, `person-in-the-middle` |
| `male`/`female` connector | `plug`/`socket` |
| `grandma test`, `girlfriend test` | `beginner user test`, `novice user test` |

### Ableist

| Do not use | Use instead |
|---|---|
| `sanity check` | `quick check`, `confidence check`, `coherence check` |
| `sane` | `valid`, `sensible` |
| `crazy`, `insane` | `baffling`, `surprising`, `extreme` |
| `blind to`, `turn a blind eye` | `ignore`, `unaware of`, `disregard` |
| `cripple` | `slow down`, `degrade` |
| `dumb down` | `simplify` |
| `dummy variable` | `placeholder` |
| `lame` | A precise term for the actual deficiency |
| `healthy` (of a system) | `working`, `passing checks` |
| `normal` (of a person) | `nondisabled`, `sighted`, `neurotypical` |

`see` is explicitly fine, including "see the following section".

When writing about disability: avoid `the disabled` and `a quadriplegic`
(use `people with disabilities`, `a quadriplegic person`), avoid `victim of`,
`suffering from`, and `wheelchair-bound` (use `experiencing`, `living with`,
`uses a wheelchair`), and avoid `special`, `differently abled`, `handi-capable`.
Some communities prefer identity-first language, notably autistic, blind, and
Deaf communities. Follow the community's own usage where you know it.

### Age

Avoid `the elderly`, `the aged`, `seniors`, `senior citizens`, `80 years young`.
Use `older adults`, `aging population`, or state the relevant age directly.

### Violent and graphic

| Do not use | Use instead |
|---|---|
| `abort`, `kill`, `terminate` | `stop`, `exit`, `cancel`, `end` |
| `nuke` | `remove`, `delete` |
| `hang`, `hung` | `stop responding`, `not responding` |
| `hit` (a button) | `click`, `press`, `type` |
| `blast radius` | `affected area`, `scope of impact` |
| `demilitarized zone`, `DMZ` | `perimeter network` |
| `break-glass` | `emergency access`, `manual fallback` |
| `final solution` | `solution`, `definitive solution` |
| `slice and dice` | `segment`, `break into smaller parts` |

### Socially charged

| Do not use | Use instead |
|---|---|
| `blacklist` | `denylist`, `blocklist`, `excludelist` |
| `whitelist` | `allowlist`, `trustlist`, `safelist` |
| `master`/`slave` | `primary`/`secondary`, `primary`/`replica`, `leader`/`follower`, `controller`/`worker`, `active`/`standby` |
| `grandfathered` | `exempt`, `legacy`, `made an exception` |
| `black hat`/`white hat` | `illegal`, `unethical`, `in violation of rules` |
| `white glove` | `high-touch`, `premium` |
| `white label` | `unbranded`, `unlabeled` |
| `ghetto` | `clumsy`, `inelegant`, `a workaround` |
| `gypsy` | `Romani`, `Roma`, `Traveller` |
| `guru`, `ninja`, `rockstar` | `expert` |
| `sherpa` | `guide` |
| `brown bag` | `learning session`, `lunch and learn` |
| `native` (of people) | Name the actual attribute |
| `native` (of software) | `built-in` |
| `first-class citizen` | `fully supported` |
| `shift left` | `shift earlier`, `move to an earlier phase` |

Two escape hatches Google grants explicitly:

1. **Name the established term once.** If replacing a term would confuse
   readers, use the inclusive term and put the old one in parentheses on first
   use, then use only the inclusive term: "add them to an allowlist (sometimes
   called a whitelist)".
2. **Rewrite instead of substituting.** Often the sentence improves more from
   restructuring than from a word swap. "You can allow requests from a range of
   IP addresses by entering a CIDR block" beats "You can allowlist a range".

## Addressing the reader

- `you` for the reader. Not `the user`, not `the reader`, not `one`.
- `user` only for the people who use the thing your reader is building.
- `we` only for the organization authoring the piece, and only when the
  antecedent is unmistakable. Never `we` for what the reader does.
- Never `let's`.
