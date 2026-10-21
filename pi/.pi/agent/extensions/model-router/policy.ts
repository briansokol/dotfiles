// Pure routing policy: no Pi imports, network access, or credential access.
export interface Candidate {
	key: string;
	group: string;
	hosted: boolean;
	deep: boolean;
	contextWindow: number;
	maxTokens: number;
	images: boolean;
}

export interface Assessment {
	difficulty: "routine" | "standard" | "complex";
	reason: string;
}

export interface RouteState {
	selected?: string;
	failedKeys: string[];
	failedGroups: string[];
	reason?: string;
}

export interface Controls {
	mode: "auto" | "local-only";
	lock?: string;
}

export function textOf(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	return content.flatMap((part) => part?.type === "text" && typeof part.text === "string" ? [part.text] : []).join("\n");
}

export function lastAsk(messages: readonly any[]): string {
	return textOf(messages.findLast((message) => message.role === "user")?.content);
}

export function assess(messages: readonly any[]): Assessment {
	const ask = lastAsk(messages);
	if (/\b(still (?:fails?|failing|broken)|that (?:didn't|did not) work|try (?:a different|another) approach)\b/i.test(ask)) {
		return { difficulty: "complex", reason: "user reports an unsuccessful previous approach" };
	}
	if (/\b(race condition|deadlock|security audit|cryptographic|data corruption)\b/i.test(ask)) {
		return { difficulty: "complex", reason: "high-risk debugging or security task" };
	}
	const dimensions = [
		/\b(architect(?:ure|ural)?|design|migration|refactor)\b/i,
		/\b(distributed|concurren\w*|cross[- ](?:file|cutting|service)|multi[- ](?:file|service)|repository[- ]wide)\b/i,
		/\b(debug|diagnos\w*|root cause|intermittent|subtle|complex)\b/i,
		/\b(production|authentication|authorization|database|protocol|compiler)\b/i,
	].filter((pattern) => pattern.test(ask)).length;
	if (dimensions >= 2) return { difficulty: "complex", reason: "multiple engineering complexity signals" };
	if (dimensions === 0 && ask.length < 1200) return { difficulty: "routine", reason: "bounded task without complexity signals" };
	return { difficulty: "standard", reason: "ordinary engineering task" };
}

export function toolErrors(messages: readonly any[]): number {
	const start = messages.findLastIndex((message) => message.role === "user");
	return messages.slice(start + 1).filter((message) => message.role === "toolResult" && message.isError).length;
}

/** Estimate, not a tokenizer. Excludes base64 and reserves tokens for every image. */
export function contextNeeds(messages: readonly any[]): { tokens: number; images: boolean } {
	let images = false;
	let imageCount = 0;
	const json = JSON.stringify(messages, (key, value) => {
		if (value && typeof value === "object" && (value.type === "image" || value.type === "image_url")) {
			images = true;
			imageCount++;
			return { type: "image" };
		}
		return value;
	});
	return { tokens: Math.ceil(Buffer.byteLength(json ?? "", "utf8") / 3) + imageCount * 4096, images };
}

export function failureScope(error: string): "context" | "group" | "model" {
	if (/context[_ -]?(?:length|window)|too many tokens|prompt.{0,30}too long/i.test(error)) return "context";
	if (/429|rate.?limit|quota|usage limit|overloaded|503|502|ECONN|fetch failed|connection|timed? ?out|unreachable/i.test(error)) return "group";
	return "model";
}

export function decide(input: {
	candidates: Candidate[];
	controls: Controls;
	state?: RouteState;
	reason: string;
	previous?: string;
	failed?: { key: string; error: string; group?: string };
	assessment: Assessment;
	tokens: number;
	images: boolean;
	errors: number;
	errorThreshold: number;
}): { candidate: Candidate; state: RouteState; thinkingLevel: "low" | "medium" | "high"; explanation: string } {
	const { controls } = input;
	const old = input.reason === "user" || input.reason === "direct" ? undefined : input.state;
	const state: RouteState = { failedKeys: [...(old?.failedKeys ?? [])], failedGroups: [...(old?.failedGroups ?? [])] };
	if (input.failed && failureScope(input.failed.error) !== "context") {
		state.failedKeys.push(input.failed.key);
		const failed = input.candidates.find((candidate) => candidate.key === input.failed!.key);
		const group = input.failed.group ?? failed?.group;
		if (group && failureScope(input.failed.error) === "group") state.failedGroups.push(group);
	}
	state.failedKeys = [...new Set(state.failedKeys)];
	state.failedGroups = [...new Set(state.failedGroups)];
	let eligible = input.candidates.filter((candidate) =>
		(controls.mode !== "local-only" || !candidate.hosted) &&
		(!input.images || candidate.images) &&
		!state.failedKeys.includes(candidate.key) && !state.failedGroups.includes(candidate.group));
	if (controls.lock) eligible = eligible.filter((candidate) => candidate.key === controls.lock);
	if (!eligible.length) throw new Error("Router: no eligible model remains (privacy, lock, capabilities, health, auth, or failed attempts). No billed API fallback is permitted.");
	const fits = eligible.filter((candidate) => input.tokens <= (candidate.contextWindow - candidate.maxTokens) * 0.9);
	const needsCompaction = fits.length === 0;
	if (fits.length) eligible = fits;
	else eligible = [...eligible].sort((a, b) => (b.contextWindow - b.maxTokens) - (a.contextWindow - a.maxTokens));
	const stickyKey = input.failed && failureScope(input.failed.error) === "context"
		? input.failed.key : input.previous ?? old?.selected;
	const sticky = eligible.find((candidate) => candidate.key === stickyKey);
	const escalate = input.errors >= input.errorThreshold;
	const complex = input.assessment.difficulty === "complex" || escalate;
	let candidate: Candidate;
	let explanation: string;
	if (controls.lock) {
		candidate = eligible[0];
		explanation = "explicit model lock";
	} else if (needsCompaction) {
		candidate = eligible[0];
		explanation = "no estimated full-context fit; largest eligible input budget selected for Pi compaction";
	} else if (sticky && input.reason !== "user" && input.reason !== "direct" && (!escalate || sticky.hosted)) {
		candidate = sticky;
		explanation = "keep model stable through continuation/retry";
	} else if (complex && eligible.some((item) => item.hosted)) {
		candidate = eligible.find((item) => item.hosted && item.deep) ?? eligible.find((item) => item.hosted)!;
		explanation = escalate ? `${input.errors} tool errors this user turn; bounded hosted escalation` : input.assessment.reason;
	} else {
		candidate = eligible.find((item) => !item.hosted) ?? eligible.find((item) => !item.deep) ?? eligible[0];
		explanation = candidate.hosted ? "no suitable private candidate; subscription fallback" : input.assessment.reason;
	}
	const thinkingLevel = complex ? "high" : input.assessment.difficulty === "routine" ? "low" : "medium";
	state.selected = candidate.key;
	state.reason = explanation;
	return { candidate, state, thinkingLevel, explanation };
}
