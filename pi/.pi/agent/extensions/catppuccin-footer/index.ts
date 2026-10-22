/**
 * Catppuccin Mocha powerline footer for pi.
 *
 * Replaces the default footer with the same two-area layout (working dir +
 * git branch, then token/cost/context stats and the active model), but
 * styled with the Catppuccin Mocha palette used by the Claude Code
 * statusline (claude/.claude/statusline.sh):
 *
 *   Line 1: colored BG segments (dir = blue, branch = sapphire)
 *   Line 2: colored FG on transparent background (model = mauve,
 *           context = green/yellow/peach by usage, rest = subtext)
 */
import { execFileSync } from "node:child_process";
import { relative, resolve, sep } from "node:path";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// ---------------------------------------------------------------------------
// Catppuccin Mocha palette (truecolor, same values as claude statusline.sh)
// ---------------------------------------------------------------------------
const C = {
	subtext1: "#bac2de",
	subtext0: "#a6adc8",
	peach: "#fab387",
	yellow: "#f9e2af",
	green: "#a6e3a1",
	sapphire: "#74c7ec",
	blue: "#89b4fa",
	mauve: "#cba6f7",
	base: "#1e1e2e",
} as const;

// Nerd Font powerline left cap (require a Nerd Font, same as the claude statusline)
const CAP_L = "\uE0B6";

const BOLD = "\x1b[1m";
const RESET = "\x1b[0m";
const DIM = "\x1b[2m";

function fmtTokens(count: number): string {
	if (count < 1000) return count.toString();
	if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
	if (count < 1000000) return `${Math.round(count / 1000)}k`;
	return `${(count / 1000000).toFixed(1)}M`;
}

/** Colored segment on a solid background (line 1 powerline segments). */
function seg(bg: string, fg: string, content: string): string {
	return `\x1b[48;2;${hex(bg)}m\x1b[38;2;${hex(fg)}m${BOLD} ${content} \x1b[0m`;
}

/** Dimmed colored text on transparent background (line 2). */
function plain(color: string, content: string): string {
	return `\x1b[38;2;${hex(color)}m${DIM}${content}\x1b[0m`;
}

function hex(color: string): string {
	return `${parseInt(color.slice(1, 3), 16)};${parseInt(color.slice(3, 5), 16)};${parseInt(color.slice(5, 7), 16)}`;
}

/** Short-cached git branch lookup; null when not in a repo. */
let branchCache: { cwd: string; branch: string | null; at: number } | null = null;
function gitBranch(cwd: string): string | null {
	const now = Date.now();
	if (branchCache && branchCache.cwd === cwd && now - branchCache.at < 1500) {
		return branchCache.branch;
	}
	let branch: string | null = null;
	try {
		const ref = execFileSync("git", ["-C", cwd, "symbolic-ref", "--short", "HEAD"], {
			encoding: "utf8",
			timeout: 1000,
		}).trim();
		if (ref) branch = ref;
	} catch {
		branch = null;
	}
	branchCache = { cwd, branch, at: now };
	return branch;
}

export default function (pi: ExtensionAPI) {
	let enabled = true;

	const install = (ctx: ExtensionContext) => {
		if (!enabled) {
			ctx.ui.setFooter(undefined);
			return;
		}

		ctx.ui.setFooter((tui, _theme, footerData) => {
			const unsub = footerData.onBranchChange(() => tui.requestRender());

			return {
				invalidate() {},
				dispose: unsub,
				render(width: number): string[] {
					// --- Line 1: dir + git branch powerline segments ---
					const home = process.env.HOME || process.env.USERPROFILE;
					let cwd = ctx.sessionManager.getCwd();
					if (home) {
						const rel = relative(resolve(home), resolve(cwd));
						if (rel === "" || (!rel.startsWith("..") && !rel.startsWith(`..${sep}`) && !rel.startsWith("/"))) {
							cwd = rel === "" ? "~" : `~${sep}${rel}`;
						}
					}

					let line1 = "";
					line1 += seg(C.blue, C.base, cwd);
					// pi's footer provider watches .git; fall back to a cached
					// query only if it doesn't have the branch yet.
					const branch = footerData.getGitBranch() ?? gitBranch(cwd);
					if (branch) line1 += ` ${seg(C.sapphire, C.base, branch)}`;

					const sessionName = ctx.sessionManager.getSessionName();
					if (sessionName) line1 += plain(C.subtext0, ` • ${sessionName}`);

					// --- Line 2: token/cost/context stats + model ---
					const usageTotals = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0 };
					let latestCacheHitRate: number | undefined;
					for (const entry of ctx.sessionManager.getEntries()) {
						if (entry.type !== "message") continue;
						const m = entry.message as AssistantMessage;
						if (!m.usage) continue;
						usageTotals.input += m.usage.input ?? 0;
						usageTotals.output += m.usage.output ?? 0;
						usageTotals.cacheRead += m.usage.cacheRead ?? 0;
						usageTotals.cacheWrite += m.usage.cacheWrite ?? 0;
						usageTotals.cost += m.usage.cost?.total ?? 0;
						const promptTokens = (m.usage.input ?? 0) + (m.usage.cacheRead ?? 0) + (m.usage.cacheWrite ?? 0);
						latestCacheHitRate = promptTokens > 0 ? ((m.usage.cacheRead ?? 0) / promptTokens) * 100 : undefined;
					}

					const model = ctx.model;
					const contextWindow = ctx.getContextUsage()?.contextWindow ?? model?.contextWindow ?? 0;
					const ctxPercent = ctx.getContextUsage()?.percent ?? null;
					// Same thresholds as the claude statusline: <50 green, <80 yellow, >=80 peach
					const ctxColor = ctxPercent === null ? C.subtext0 : ctxPercent >= 80 ? C.peach : ctxPercent >= 50 ? C.yellow : C.green;
					const ctxDisplay =
						ctxPercent === null ? `?/${fmtTokens(contextWindow)}` : `${ctxPercent.toFixed(0)}%/${fmtTokens(contextWindow)}`;

					const parts: string[] = [];
					if (usageTotals.input) parts.push(`↑${fmtTokens(usageTotals.input)}`);
					if (usageTotals.output) parts.push(`↓${fmtTokens(usageTotals.output)}`);
					if (usageTotals.cacheRead) parts.push(`R${fmtTokens(usageTotals.cacheRead)}`);
					if (usageTotals.cacheWrite) parts.push(`W${fmtTokens(usageTotals.cacheWrite)}`);
					if ((usageTotals.cacheRead > 0 || usageTotals.cacheWrite > 0) && latestCacheHitRate !== undefined) {
						parts.push(`CH${latestCacheHitRate.toFixed(0)}%`);
					}
					if (usageTotals.cost > 0) parts.push(`$${usageTotals.cost.toFixed(3)}`);
					parts.push(ctxDisplay); // plain text; the context part gets colored below

					const statsText = parts.join("  ");
					const modelName = model?.name ?? model?.id ?? "no-model";
					let modelDisplay = modelName;
					if (model?.reasoning && ctx.thinkingLevel !== undefined) {
						modelDisplay = `${modelName} • thinking ${ctx.thinkingLevel}`;
					}

					// Color only the context part of the stats line (width math stays on plain text).
					const before = statsText.slice(0, statsText.length - ctxDisplay.length); // includes trailing "  " separator
					const stats = before ? plain(C.subtext1, before) + plain(ctxColor, ctxDisplay) : plain(ctxColor, ctxDisplay);

					// Right-align the model, truncating from the cheaper side first.
					const statsW = visibleWidth(statsText);
					const modelW = visibleWidth(modelDisplay);
					const minPad = 2;
					let line2: string;
					if (statsW + minPad + modelW <= width) {
						line2 = stats + " ".repeat(width - statsW - modelW) + plain(C.mauve, modelDisplay);
					} else if (statsW < width - minPad) {
						const avail = width - statsW - minPad;
						line2 = stats + " ".repeat(minPad) + plain(C.mauve, truncateToWidth(modelDisplay, avail, ""));
					} else {
						line2 = plain(C.subtext1, truncateToWidth(statsText, width, "..."));
					}

					line1 = truncateToWidth(line1, width, RESET + "...");
					line2 = truncateToWidth(line2, width, "");
					return [line1, line2];
				},
			};
		});
	};

	// Install the footer for every session (including /resume, new sessions, forks).
	pi.on("session_start", (_event, ctx) => {
		install(ctx);
	});

	// Rebind on each turn so the footer always tracks the session's live ctx.
	pi.on("turn_start", (_event, ctx) => {
		install(ctx);
	});

	pi.registerCommand("footer", {
		description: "Toggle Catppuccin powerline footer (default on)",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			install(ctx);
			ctx.ui.notify(enabled ? "Catppuccin powerline footer enabled" : "Default footer restored", "info");
		},
	});
}
