export interface RouterConfig {
	privateModels: string[];
	hostedModels: string[];
	deepModels: string[];
	/** Models on the same physical host should share a group. */
	resourceGroups: Record<string, string>;
	probeTimeoutMs: number;
	probeCacheMs: number;
	toolErrorThreshold: number;
	classifier?: string;
	classifierTimeoutMs: number;
}

export const defaults: RouterConfig = {
	privateModels: [
		"ollama/qwen3.6:35b-a3b-coding",
		"strata/qwen3.8-flash-next-coder-iq1_m",
		"firefly/qwen3.8:27b-160k",
	],
	hostedModels: ["openai/gpt-6-luna", "openai/gpt-5.6-luna", "openai/gpt-5.4-mini"],
	deepModels: ["openai/gpt-6.1-sol", "openai/gpt-6-sol", "openai/gpt-5.6-sol", "openai/gpt-5.4"],
	resourceGroups: {},
	probeTimeoutMs: 1500,
	probeCacheMs: 30000,
	toolErrorThreshold: 3,
	classifierTimeoutMs: 2000,
};

export function parseConfig(value: unknown): RouterConfig {
	if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("Router config must be a JSON object");
	const object = value as Record<string, unknown>;
	for (const key of Object.keys(object)) if (!Object.hasOwn(defaults, key) && key !== "classifier") throw new Error(`Unknown router setting: ${key}`);
	const config = { ...defaults, ...object } as RouterConfig;
	for (const field of ["privateModels", "hostedModels", "deepModels"] as const) {
		if (!Array.isArray(config[field]) || config[field].some((key) => typeof key !== "string" || !/^[^/\s]+\/\S+$/.test(key))) {
			throw new Error(`${field} must be an array of provider/model IDs`);
		}
	}
	for (const key of [...config.hostedModels, ...config.deepModels]) {
		if (!/^(openai|openai-codex)\//.test(key)) throw new Error(`Only OpenAI subscription providers are allowed in hosted models: ${key}`);
	}
	for (const key of config.privateModels) {
		if (/^(openai|openai-codex|router)\//.test(key)) throw new Error(`Not a private provider: ${key}`);
	}
	if (config.classifier !== undefined && !config.privateModels.includes(config.classifier)) throw new Error("classifier must be one of privateModels");
	if (!config.resourceGroups || typeof config.resourceGroups !== "object" || Array.isArray(config.resourceGroups) ||
		Object.values(config.resourceGroups).some((group) => typeof group !== "string" || !group)) throw new Error("resourceGroups must map provider names to nonempty strings");
	for (const field of ["probeTimeoutMs", "probeCacheMs", "toolErrorThreshold", "classifierTimeoutMs"] as const) {
		if (!Number.isSafeInteger(config[field]) || config[field] < 1) throw new Error(`${field} must be a positive integer`);
	}
	const all = [...config.privateModels, ...config.hostedModels, ...config.deepModels];
	if (new Set(all).size !== all.length) throw new Error("Model lists must not contain duplicate IDs");
	return config;
}
