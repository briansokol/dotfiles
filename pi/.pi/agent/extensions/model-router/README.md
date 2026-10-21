# Local-first model router for Pi

Registers **`router/auto`**, a Pi virtual model. Tested with Pi 1.3.0. Uses Pi's native provider calls, authentication, tool loop, context compaction, and branch-local virtual-model state. No proxy, npm dependencies, or additional paid service.

## Install / select

From the dotfiles repository:

```sh
stow --restow --no-folding pi
```

In Pi, run `/reload`, then **`/router auto`** (or choose `router/auto` in `/model`). This does not change your global default. Save the selection in `/model` if you want it for new sessions.

Try without Stow:

```sh
pi -e ./pi/.pi/agent/extensions/model-router/index.ts --model router/auto
```

Existing modifications to `models.json` are independent of the router. It looks up configured model IDs; it never rewrites model definitions, settings, or credentials.

## Policy

1. Use only explicitly configured candidate IDs that Pi reports as available.
2. For private candidates, check their OpenAI-compatible `GET <baseUrl>/models` endpoint and model ID (cached for 30 seconds). Probes do not load a model or generate tokens. Endpoints requiring authentication for `/models` are currently unsupported; probe requests do not send credentials or follow redirects.
3. Require OpenAI's provider to report **both OAuth authentication and a subscription login**. An API key alone is insufficient. Explicit CLI `--api-key` disables hosted candidates. Other paid providers are never automatically discovered or used.
4. Filter for images anywhere in history. Estimate the whole transcript size, including system/tool declarations, reserve the candidate's declared maximum output, and keep a 10% input margin.
5. Prefer private models in configured order for routine/standard tasks. Use the deep subscription tier for multiple complexity signals, high-risk debugging/security tasks, or an explicit report that the previous approach failed.
6. Keep the model through tool continuations. After three `isError` tool results in one user turn, escalate once to hosted inference where permitted. This is a bounded heuristic, **not proof of poor model quality**; shell commands with nonzero exit codes do not necessarily produce `isError`.
7. On retries, exclude failed models; transport/rate/quota failures exclude their resource group. Failures accumulate for that user turn to prevent bouncing between models. A new user turn allows recovery. Context-overflow retries keep the model for Pi's compaction recovery when it remains eligible.
8. If nothing fits the estimated context, choose the largest eligible input budget and let Pi compact. Never substitute a text-only model for image history. A model lock never silently fails over.
9. Maintenance/direct requests (for example compaction summaries) prefer private inference too.

Routine tasks use low reasoning, ordinary tasks medium, complex tasks high. The virtual model's `/thinking` selection is a **ceiling** on the automatically chosen reasoning level. Pi clamps levels to physical-model support. Normal continuations retain the previous physical level to avoid needless cache changes.

### Subscription usage and privacy

**Automatic mode can send the complete outgoing conversation—including previously read repository content—to OpenAI without a confirmation dialog.** Use `/router local-only` *before* introducing sensitive data. It also prevents hosted maintenance requests and escalation, but cannot retract earlier hosted calls.

This optimizes for private execution and subscription allowance, not OpenAI API price estimates. Subscription quotas/model entitlements vary; the catalog and OAuth metadata are not proof every model is entitled. An entitlement error can trigger another configured candidate on a Pi retry. Subscription exhaustion permits private fallback; the extension never deliberately switches to OpenAI API-key billing. Pi's normal retry settings still govern which failures get retried.

Only list genuinely private, unbilled inference servers in `privateModels`. That list is a trusted operator declaration, not a network isolation or billing enforcement boundary. As with other Pi extensions, provider overrides and SDK/runtime credential overrides outside this extension must be trusted.

## Commands

```text
/router                 Show mode/configuration
/router status          Same as above
/router explain         Explain the most recent decision in this process
/router auto            Select router, enable automatic hosted routing, clear lock
/router local-only      Select router, forbid hosted routing, clear lock
/router lock ID         Lock to a configured provider/model; preserve privacy mode
/router reload          Reload extension/config and clear health cache
```

Controls are custom session entries, read from the **active branch** on every request. Forks/tree navigation/resume preserve branch-specific settings. Transient failures live in Pi's branch-local virtual-model state. Explanations/status are ephemeral and are not a separate prompt log. `/router auto` clears a lock; it does not erase a turn's existing failure state.

The Catppuccin footer displays `auto → provider/model`. The standard footer displays Pi's native routed-model information. `/router explain` provides the reason. No background watchers or subprocesses are created.

## Machine-local configuration

Optional file: **`~/.pi/agent/model-router.json`** (or the agent directory selected by Pi). Do not commit credentials there. Copy/edit `config.example.json`, then `/router reload`. Unknown fields and malformed settings fail closed. Missing configuration uses `config.ts` defaults; arrays replace defaults.

Model lists are ordered preferences, not performance rankings. Adjust them after measuring your workloads. Default private candidates are Firefly Laguna XS 2.1 128k, Ollama Qwen 3.6, then Firefly Qwen 3.8. Default hosted lists contain curated OpenAI IDs from the current catalog; unavailable IDs are skipped. Both hosted tiers may be empty to disable hosted candidates globally.

Resource groups prevent treating aliases/shared hardware as independent failover. Loopback hosts and the current machine's hostname (including its Tailscale FQDN) automatically share `private:local-machine`. For other aliases/shared machines, configure provider-to-group mappings explicitly. All OpenAI subscription candidates share one quota/resource group. Groups affect retry exclusion, **not scheduling or memory management**; the router does not load/unload models or prevent concurrent processes from competing for GPU memory.

Context limits and capabilities come from `models.json`/Pi's catalog. Verify actual allocation with `ollama ps` and your local server. Token estimation is conservative but not an exact tokenizer; Pi remains responsible for real context overflow recovery. Image estimates use 4096 tokens per image and may differ from actual provider accounting.

### Optional local model-assisted assessment

Set `classifier` to an ID already present in `privateModels`. On new user requests not already identified as complex, the router asks that physical model for a JSON difficulty label using up to two preceding user prompts. It has no tools or file access and cannot call the virtual router recursively. A two-second deadline, invalid JSON, or provider failure falls back to task heuristics.

**Disabled by default:** the currently configured private models are large, and an extra model call/load can cost more latency than it saves. Prefer adding a small, warm classifier model if you enable this. Classification produces private inference usage; those nested tokens are not currently included in Pi's assistant-response footer totals. No hosted classifier is used.

## Tests

From the repository root, Node 22.19+:

```sh
node --experimental-strip-types --test pi/.pi/agent/extensions/model-router/tests/policy.test.ts
```

Tests cover policy, capability/context gating, retry exhaustion, shared-host exclusion, sticky continuations, escalation, locks, local-only mode, task assessment, and configuration validation without model calls.

A load-only check (no inference):

```sh
pi --offline --no-extensions --no-approve \
  -e ./pi/.pi/agent/extensions/model-router/index.ts --list-models router
```

This is a first policy implementation, not a trained accuracy predictor. Evaluate successful task completion, corrections, latency, and hosted usage on representative coding tasks before trusting the tier ordering. Subagents with explicit models do not automatically inherit this router or its privacy controls.
