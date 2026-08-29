# Before and after

Verbatim recommended / not-recommended pairs from the Google developer
documentation style guide, grouped by the rule they illustrate. Use these to
calibrate when a rule feels ambiguous.

## Register

The three-column calibration table. The right-hand column is the register most
professional writing defaults to, and it is a failure mode, not a safe choice.

| Too informal | Just right | Too formal |
|---|---|---|
| Dude! This API is totally awesome! | This API lets you collect data about what your users like. | The API documented by this page may enable the acquisition of information pertaining to user preferences. |
| Just like a certain pop star, this call gets your telephone number. The easy way to ask for someone's digits! | To get the user's phone number, call `user.phoneNumber.get`. | The telephone number can be retrieved by the developer via the simple expedient of using the `get` method on the `user` object's `phoneNumber` property. |
| Then BOOM, just garbage-collect, and you're golden. | To clean up, call the `collectGarbage` method. | Please note that completion of the task requires the following prerequisite: executing an automated memory management function. |

## Condition before instruction

| Recommended | Not recommended |
|---|---|
| For more information, see [link]. | See [link] for more information. |
| To delete the entire document, click **Delete**. | Click **Delete** if you want to delete the entire document. |
| If your app is located in one of the following regions, using custom domains might add noticeable latency: | Using custom domains might add noticeable latency if your app is located in one of the following regions: |

## Active voice

| Recommended | Not recommended |
|---|---|
| Send a query to the service. The server sends an acknowledgment. | The service is queried, and an acknowledgment is sent. |
| You must configure the VPC firewall rules before you deploy the VM instance. | Configuring the VPC firewall rules is required before deploying the VM instance. |
| This guide describes how to set up database replication. | This guide describes setting up database replication. |

Passive is the right choice in three cases:

1. The object matters more than the actor. "The file is saved."
2. Naming the actor would assign blame you do not intend.
   Recommended: "Over 50 conflicts were found in the file."
   Not recommended: "You created over 50 conflicts in the file."
3. The actor is genuinely irrelevant. "The database was purged in January."

Case 2 is the one that matters most in email.

## Restore the optional words

English lets you drop `that`, `then`, and repeated prepositions, verbs, and
conjunctions. Putting them back removes ambiguity at almost no cost.

| Recommended | Not recommended |
|---|---|
| If the VM has started and if you're able to connect... | If the VM has started and you're able to connect... |
| The design creates both IAM segmentation and network segmentation. | The design creates both IAM and network segmentation. |
| If the attribute key is not found, then the default value is returned. | If the attribute key is not found, the default value is returned. |
| This document assumes that you have the following knowledge: | This document assumes you have the following knowledge: |
| Identify all of the datasets. | Identify all the datasets. |
| Start the profiler, and then run the app. | Start the profiler, then run the app. |
| You can update the rules that you previously defined. | You can update the rules you previously defined. |

## Ambiguous pronouns

| Recommended | Not recommended |
|---|---|
| If you use the term green beer in an ad, then make sure that the ad is targeted. | If you use the term green beer in an ad, then make sure that it's targeted. |

Put a noun after `this` and `that`. If you cannot work out what the noun is,
the reader cannot either, and the sentence needs rewriting.

## Phrasal verbs and noun strings

| Recommended | Not recommended |
|---|---|
| This document uses the following terms: | This document makes use of the following terms: |
| A cloud-native DevSecOps pipeline in a hybrid environment | A hybrid cloud-native DevSecOps pipeline |
| Request only one token. | Only request one token. |

Established technical phrasal verbs are fine: `set up`, `log in`, `sign in`.
Never chain more than two nouns as modifiers of a third.

## Figurative language

Aiming for a conversational tone is the main way figurative language gets in.
Watch for it exactly when the writing is going well.

| Recommended | Not recommended |
|---|---|
| If the connection doesn't respond, check for errors. | If the connection hangs, check for errors. |
| Point to **File**, and then click **New**. | Hover over **File**, and hit **New**. |
| Before launch, give everything a final check for completeness. | Before launch, give everything a final sanity-check. |
| There are some baffling outliers in the data. | There are some crazy outliers in the data. |
| It slows down the service until the queue clears. | It cripples the service until the queue clears. |
| Replace the placeholder in this example with the appropriate value. | Replace the dummy variable in this example with the appropriate value. |
| Equipment installation takes around 16 person-hours. | Equipment installation takes around 16 man-hours. |
| Build AI that benefits humanity. | Build AI that benefits mankind. |
| The app is exempt because it was released before the requirements were announced. | The app is grandfathered in because it was released before the requirements were announced. |

## Double negatives

| Recommended | Not recommended |
|---|---|
| You can continue without a path. | A missing path won't prevent you from continuing. |

## Headings and titles

Sentence case everywhere, including the title. No period at the end.

| Guidance | Recommended | Not recommended |
|---|---|---|
| Task heading uses a base-form verb | Create an instance | Creating an instance |
| Concept heading uses a noun phrase | Migration to Google Cloud | Migrating to Google Cloud |
| Optional sections front-load the label | Optional: Customize your alias | Customize your alias (optional) |
| No gerund in first position | Transfer data sets | Transferring data sets |

Gerunds are acceptable when no good alternative exists (`Billing`, `Pricing`)
and anywhere other than the first word (`Introduction to BigQuery monitoring`).

Do not number headings to imply sequence, do not put links in headings, do not
skip heading levels, and do not repeat the page title as a heading.

## Lists

Introduce a list with a complete sentence, not a fragment the items finish.

| Recommended | Not recommended |
|---|---|
| Use the **Submit** button for any of the following purposes:<br>- To submit the form.<br>- To indicate that you're done. | Use the **Submit** button to:<br>- Submit the form.<br>- Indicate that you're done. |
| To get the USB driver, follow these steps:<br>1. Click **SDK Manager**.<br>2. Select the driver, and then click **OK**. | To get the USB driver:<br>1. Click **SDK Manager**.<br>2. Select the driver, and then click **OK**. |

Capitalize the first word of every item. End each item with a period unless the
item is a single word, has no verb, or is entirely link text or a title. If the
punctuation comes out inconsistent, rewrite for parallel structure rather than
mixing styles.

Numbered lists are for sequences. Bulleted lists are for everything else.
A single-item list is not a list.

## Link text

Link text has to make sense read on its own, because screen reader users jump
between links without the surrounding sentence.

| Recommended | Not recommended |
|---|---|
| You can use Cloud Scheduler to manage [task scheduling on Compute Engine]. | See [this blog post]. |
| For more information, see [Make headings into link targets]. | Want more? [Click here!] |
| For more information about task scheduling, see [Reliable task scheduling]. | For more information on indexes, see [Manage indexes]. |

Never use `this document`, `this article`, `click here`, or a bare URL as link
text. Use `about`, not `on`, after "For more information". Put punctuation
outside the link. Do not force links to open in a new tab.

## Directional language

Position words fail for screen readers, for right-to-left languages, and for
any layout that reflows.

| Recommended | Not recommended |
|---|---|
| In the preceding diagram, clients run jobs on multi-team clusters. | In the diagram above, clients run jobs on multi-team clusters. |

Use `preceding`, `earlier`, `following`, and `later` instead of `above`,
`below`, and `right-hand side`.

## Dates and times

Numeric dates are ambiguous across regions: 04/05/09 is May 4 in the UK,
April 5 in the US, and May 9, 2004 in parts of Asia.

| Recommended | Not recommended |
|---|---|
| February 12, 2017 | 02.12.2017 |
| Sunday, February 12, 2017 | 12/02/2017 |
| 2017-04-15 | 04/06/2017 |
| Mon, Sep 3, 2018 | Mon, September 3, 2018 |

Spell out month and weekday names, and give the four-digit year. Abbreviate
only to save space in a heading or table, and then abbreviate every element.
Use ISO 8601 (`YYYY-MM-DD`) when a numeric format is unavoidable.

A month and year together take no comma ("in January 2017"). A full date used
mid-sentence takes a comma after the year ("the January 19, 2017, release").

Times use the 12-hour clock with capitalized `AM` and `PM` and a preceding
space: `9:00 AM`, `3 PM`. Drop the minutes from round hours. Use hyphens with
no spaces for ranges: `5-10 minutes`. Avoid time zones where possible, and
spell out the region with a UTC offset when you need one.

Avoid seasons entirely, because they invert across hemispheres.

| Recommended | Not recommended |
|---|---|
| During warmer months, data centers face a higher risk of cooling failures. | During summer months, data centers face a higher risk of cooling failures. |
| In November and December, data centers experience higher traffic. | In winter, data centers experience higher traffic. |

## Timeless versus dated

| Timeless (docs, README, policy) | Dated (blog, release notes, announcements) |
|---|---|
| These subcommands let you interact with load balancing. | These **new** subcommands let you interact with load balancing. |
| The following options aren't supported: | The following options aren't **currently** supported: |
| The emulator supports the following filters: | The emulator **now** supports the following filters: |

The left column is correct for anything read repeatedly over months. The right
column is correct for anything dated by nature. Google says so explicitly:
time-based language is acceptable in blog posts, press releases, and release
notes.
