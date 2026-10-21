import assert from "node:assert/strict";
import test from "node:test";
import { assess, contextNeeds, decide, failureScope, toolErrors, type Candidate } from "../policy.ts";
import { parseConfig } from "../config.ts";

const local: Candidate = { key: "ollama/small", group: "private:local-machine", hosted: false, deep: false, contextWindow: 32768, maxTokens: 8192, images: true };
const firefly: Candidate = { ...local, key: "firefly/large", group: "private:firefly", contextWindow: 163840, maxTokens: 32768 };
const standard: Candidate = { ...local, key: "openai/economy", hosted: true, group: "openai-subscription", contextWindow: 272000, maxTokens: 32768 };
const deep: Candidate = { ...standard, key: "openai/deep", deep: true };
const base = { candidates: [local, firefly, standard, deep], controls: { mode: "auto" as const }, reason: "user", tokens: 1000, images: false,
	assessment: { difficulty: "routine" as const, reason: "routine" }, errors: 0, errorThreshold: 3 };

test("routine work prefers private order", () => assert.equal(decide(base).candidate.key, local.key));
test("complex work selects subscription deep model", () => assert.equal(decide({ ...base, assessment: { difficulty: "complex", reason: "hard" } }).candidate.key, deep.key));
test("local-only overrides complexity and hosted locks", () => {
	assert.equal(decide({ ...base, controls: { mode: "local-only" }, assessment: { difficulty: "complex", reason: "hard" } }).candidate.key, local.key);
	assert.throws(() => decide({ ...base, controls: { mode: "local-only", lock: deep.key } }));
});
test("context budget includes output reservation", () => assert.equal(decide({ ...base, tokens: 25000 }).candidate.key, firefly.key));
test("no fit chooses largest input budget for compaction", () => {
	const decision = decide({ ...base, tokens: 900000 });
	assert.equal(decision.candidate.key, standard.key);
	assert.match(decision.explanation, /compaction/);
});
test("images exclude text-only candidates", () => assert.equal(decide({ ...base, candidates: [{ ...local, images: false }, firefly], images: true }).candidate.key, firefly.key));
test("unsupported image input fails closed", () => assert.throws(() => decide({ ...base, candidates: [{ ...local, images: false }], images: true })));
test("continuations keep private model even when reassessment is complex", () => assert.equal(decide({ ...base, reason: "continuation", previous: local.key, assessment: { difficulty: "complex", reason: "hard" } }).candidate.key, local.key));
test("hosted continuations are not downgraded", () => assert.equal(decide({ ...base, reason: "continuation", previous: deep.key }).candidate.key, deep.key));
test("tool-error escalation is bounded and remains hosted", () => {
	const first = decide({ ...base, reason: "continuation", previous: local.key, errors: 3 });
	assert.equal(first.candidate.key, deep.key);
	assert.equal(decide({ ...base, reason: "continuation", state: first.state, previous: deep.key, errors: 4 }).candidate.key, deep.key);
});
test("transport failure excludes aliases on same physical host", () => {
	const alias = { ...firefly, group: local.group };
	const decision = decide({ ...base, reason: "retry", candidates: [local, alias, standard], failed: { key: local.key, error: "fetch failed" } });
	assert.equal(decision.candidate.key, standard.key);
	assert.ok(decision.state.failedGroups.includes(local.group));
});
test("failure groups survive when an unhealthy candidate is no longer listed", () => {
	const decision = decide({ ...base, reason: "retry", candidates: [{ ...firefly, group: local.group }, standard],
		failed: { key: local.key, group: local.group, error: "connection refused" } });
	assert.equal(decision.candidate.key, standard.key);
});
test("quota exhaustion excludes every hosted model and falls back privately", () => {
	const decision = decide({ ...base, reason: "retry", previous: deep.key, errors: 4,
		failed: { key: deep.key, error: "429 usage limit reached" } });
	assert.equal(decision.candidate.key, local.key);
	assert.ok(decision.state.failedGroups.includes("openai-subscription"));
});
test("fully exhausted retry chain stops", () => assert.throws(() => decide({ ...base, reason: "retry",
	state: { failedKeys: [], failedGroups: [local.group, firefly.group, standard.group] } })));
test("direct requests ignore agent-loop failure state", () => assert.equal(decide({ ...base, reason: "direct",
	state: { failedKeys: [local.key], failedGroups: [local.group] } }).candidate.key, local.key));
test("model-specific denial allows another model", () => {
	const decision = decide({ ...base, reason: "retry", failed: { key: local.key, error: "model not found" } });
	assert.equal(decision.candidate.key, firefly.key);
	assert.deepEqual(decision.state.failedGroups, []);
});
test("retry failures accumulate, never bounce back", () => {
	const first = decide({ ...base, reason: "retry", failed: { key: local.key, error: "bad model" } });
	const second = decide({ ...base, reason: "retry", state: first.state, failed: { key: firefly.key, error: "bad model" } });
	assert.equal(second.candidate.key, standard.key);
	assert.deepEqual(second.state.failedKeys, [local.key, firefly.key]);
});
test("new user turn resets transient failures", () => assert.equal(decide({ ...base, state: { failedKeys: [local.key], failedGroups: [local.group] } }).candidate.key, local.key));
test("context overflow retry stays on failed model for Pi recovery", () => assert.equal(decide({ ...base, reason: "retry", failed: { key: firefly.key, error: "context_length_exceeded" } }).candidate.key, firefly.key));
test("lock does not silently fail over", () => assert.throws(() => decide({ ...base, controls: { mode: "auto", lock: local.key }, reason: "retry", failed: { key: local.key, error: "timeout" } })));
test("no candidates fails closed", () => assert.throws(() => decide({ ...base, candidates: [] }), /No billed API fallback/));
test("task assessment detects context-sensitive correction and complexity", () => {
	const ask = (text: string) => [{ role: "user", content: text }];
	assert.equal(assess(ask("What does stow do?")).difficulty, "routine");
	assert.equal(assess(ask("Diagnose intermittent production failures")).difficulty, "complex");
	assert.equal(assess(ask("That didn't work, try another approach")).difficulty, "complex");
});
test("tool errors count only latest user turn", () => assert.equal(toolErrors([{ role: "toolResult", isError: true }, { role: "user", content: "new" }, { role: "toolResult", isError: false }, { role: "toolResult", isError: true }]), 1));
test("context estimation detects old images without counting base64", () => {
	const needs = contextNeeds([{ role: "user", content: [{ type: "image", data: "a".repeat(1000000) }] }]);
	assert.equal(needs.images, true);
	assert.ok(needs.tokens > 4096 && needs.tokens < 5000);
});
test("failure scopes distinguish context, rate limits, and model errors", () => {
	assert.equal(failureScope("context_length_exceeded"), "context");
	assert.equal(failureScope("429 quota exceeded"), "group");
	assert.equal(failureScope("model not available"), "model");
});
test("config accepts overrides without mutating defaults", () => {
	assert.equal(parseConfig({ toolErrorThreshold: 5 }).toolErrorThreshold, 5);
	assert.equal(parseConfig({}).toolErrorThreshold, 3);
});
test("config rejects unsafe and malformed values", () => {
	for (const value of [null, [], { typo: 1 }, { toString: 1 }, { hostedModels: ["anthropic/foo"] }, { privateModels: ["openai/foo"] },
		{ classifier: "openai/foo" }, { probeTimeoutMs: 0 }, { toolErrorThreshold: 1.5 }, { resourceGroups: [] },
		{ hostedModels: ["openai/a"], deepModels: ["openai/a"] }]) assert.throws(() => parseConfig(value));
});
