import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

const CACHE_FILE = join(homedir(), ".config", "pi", "account-limits.json");
const POLL_MS = 2 * 60_000;
const TIMEOUT_MS = 15_000;
const STALE_MS = 15 * 60_000;
const EXPIRE_MS = 24 * 60 * 60_000;

type Window = { used: number; resetsAt?: string };
type ProviderError = "login required" | "rate limited" | "request timed out" | "endpoint changed" | "offline";
type Snapshot = {
  openai?: { weekly: Window; fetchedAt: string };
  claude?: { session: Window; weekly: Window; fable?: Window; fetchedAt: string };
  errors?: { openai?: ProviderError; claude?: ProviderError };
};

class HttpError extends Error { constructor(readonly status: number) { super("HTTP error"); } }
class EndpointChangedError extends Error {}

function record(value: unknown): Record<string, unknown> | undefined {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : undefined;
}

function finite(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) ? value : undefined;
}

function validPercent(value: unknown): number | undefined {
  const number = finite(value);
  return number !== undefined && number >= 0 && number <= 100 ? Math.round(number) : undefined;
}

function resetTime(value: unknown): string | undefined {
  const item = record(value);
  if (!item) return undefined;
  const raw = item.resets_at ?? item.reset_at;
  const date = typeof raw === "number"
    ? new Date(raw > 10_000_000_000 ? raw : raw * 1000)
    : typeof raw === "string" ? new Date(raw) : undefined;
  return date && !Number.isNaN(date.valueOf()) ? date.toISOString() : undefined;
}

export function parseOpenAI(body: unknown): Window {
  const root = record(body);
  const rateLimit = record(root?.rate_limit ?? root?.rate_limits);
  if (!rateLimit) throw new EndpointChangedError();

  const candidates = [rateLimit.primary_window, rateLimit.secondary_window]
    .map(record)
    .filter((item): item is Record<string, unknown> => Boolean(item));
  const weekly = candidates.find((item) => {
    const seconds = finite(item.limit_window_seconds ?? item.window_seconds);
    return seconds !== undefined && seconds >= 6 * 86400 && seconds <= 8 * 86400;
  });
  if (!weekly) throw new EndpointChangedError();

  const used = validPercent(weekly.used_percent ?? weekly.utilization);
  const remaining = validPercent(weekly.remaining_percent ?? weekly.remaining_percentage);
  const result = used ?? (remaining === undefined ? undefined : 100 - remaining);
  if (result === undefined) throw new EndpointChangedError();
  const resetsAt = resetTime(weekly);
  return { used: result, ...(resetsAt ? { resetsAt } : {}) };
}

function claudeWindow(value: unknown): Window {
  const item = record(value);
  const used = validPercent(item?.utilization ?? item?.used_percent);
  if (!item || used === undefined) throw new EndpointChangedError();
  const resetsAt = resetTime(item);
  return { used, ...(resetsAt ? { resetsAt } : {}) };
}

export function parseClaude(body: unknown): { session: Window; weekly: Window; fable?: Window } {
  const root = record(body);
  if (!root) throw new EndpointChangedError();
  const fableValue = Object.hasOwn(root, "seven_day_fable") ? root.seven_day_fable : undefined;
  let fable: Window | undefined;
  if (record(fableValue)) {
    try { fable = claudeWindow(fableValue); } catch { /* Optional private API field. */ }
  }
  return {
    session: claudeWindow(root.five_hour),
    weekly: claudeWindow(root.seven_day),
    ...(fable ? { fable } : {}),
  };
}

function sanitizeError(error: unknown): ProviderError {
  if (error instanceof HttpError) {
    if (error.status === 401 || error.status === 403) return "login required";
    if (error.status === 429) return "rate limited";
    if (error.status >= 500) return "offline";
    return "endpoint changed";
  }
  if (error instanceof EndpointChangedError) return "endpoint changed";
  if (error instanceof DOMException && error.name === "AbortError") return "request timed out";
  return "offline";
}

function validWindow(value: unknown): Window | undefined {
  const item = record(value);
  const used = validPercent(item?.used);
  if (!item || used === undefined) return undefined;
  const resetsAt = typeof item.resetsAt === "string" && !Number.isNaN(new Date(item.resetsAt).valueOf())
    ? item.resetsAt : undefined;
  return { used, ...(resetsAt ? { resetsAt } : {}) };
}

async function loadCache(): Promise<Snapshot> {
  try {
    const root = record(JSON.parse(await readFile(CACHE_FILE, "utf8")));
    const openai = record(root?.openai);
    const claude = record(root?.claude);
    const weekly = validWindow(openai?.weekly);
    const session = validWindow(claude?.session);
    const claudeWeekly = validWindow(claude?.weekly);
    const fable = validWindow(claude?.fable);
    const openaiCache = weekly && typeof openai?.fetchedAt === "string"
      ? { weekly, fetchedAt: openai.fetchedAt } : undefined;
    const claudeCache = session && claudeWeekly && typeof claude?.fetchedAt === "string"
      ? { session, weekly: claudeWeekly, ...(fable ? { fable } : {}), fetchedAt: claude.fetchedAt } : undefined;
    return {
      ...(openaiCache ? { openai: openaiCache } : {}),
      ...(claudeCache ? { claude: claudeCache } : {}),
    };
  } catch {
    return {};
  }
}

async function saveCache(snapshot: Snapshot, isCurrent: () => boolean): Promise<void> {
  await mkdir(dirname(CACHE_FILE), { recursive: true, mode: 0o700 });
  const temporary = `${CACHE_FILE}.${process.pid}.${Date.now()}.${Math.random().toString(16).slice(2)}.tmp`;
  const safe = { openai: snapshot.openai, claude: snapshot.claude };
  await writeFile(temporary, `${JSON.stringify(safe, null, 2)}\n`, { mode: 0o600 });
  if (!isCurrent()) {
    await rm(temporary, { force: true });
    return;
  }
  await rename(temporary, CACHE_FILE);
}

function providerModel(ctx: ExtensionContext, provider: string): any {
  const model = ctx.modelRegistry.getAll().find((candidate) => candidate.provider === provider);
  if (!model || !ctx.modelRegistry.isUsingOAuth(model)) throw new HttpError(401);
  return model;
}

async function providerAuth(ctx: ExtensionContext, provider: string): Promise<{ token: string; headers: Record<string, string> }> {
  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(providerModel(ctx, provider));
  if (!auth.ok || !auth.apiKey) throw new HttpError(401);
  return { token: auth.apiKey, headers: auth.headers ?? {} };
}

function headerValue(headers: Record<string, string>, name: string): string | undefined {
  const match = Object.entries(headers).find(([key]) => key.toLowerCase() === name.toLowerCase());
  return match?.[1];
}

async function getJson(url: string, headers: Record<string, string>, parentSignal?: AbortSignal): Promise<unknown> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
  const abort = () => controller.abort();
  if (parentSignal?.aborted) controller.abort();
  else parentSignal?.addEventListener("abort", abort, { once: true });
  try {
    const response = await fetch(url, { headers, signal: controller.signal });
    if (!response.ok) throw new HttpError(response.status);
    return await response.json();
  } finally {
    clearTimeout(timeout);
    parentSignal?.removeEventListener("abort", abort);
  }
}

async function fetchOpenAI(ctx: ExtensionContext, signal?: AbortSignal): Promise<Snapshot["openai"]> {
  const auth = await providerAuth(ctx, "openai-codex");
  const headers: Record<string, string> = {
    accept: "application/json",
    authorization: `Bearer ${auth.token}`,
  };
  const accountId = headerValue(auth.headers, "chatgpt-account-id");
  if (accountId) headers["chatgpt-account-id"] = accountId;
  const weekly = parseOpenAI(await getJson("https://chatgpt.com/backend-api/wham/usage", headers, signal));
  return { weekly, fetchedAt: new Date().toISOString() };
}

async function fetchClaude(ctx: ExtensionContext, signal?: AbortSignal): Promise<Snapshot["claude"]> {
  const auth = await providerAuth(ctx, "anthropic");
  const existingBeta = headerValue(auth.headers, "anthropic-beta") ?? "";
  const beta = new Set(existingBeta.split(",").map((item) => item.trim()).filter(Boolean));
  beta.add("oauth-2025-04-20");
  const headers: Record<string, string> = {
    accept: "application/json",
    authorization: `Bearer ${auth.token}`,
    "anthropic-version": "2023-06-01",
    "anthropic-beta": [...beta].join(","),
  };
  const limits = parseClaude(await getJson("https://api.anthropic.com/api/oauth/usage", headers, signal));
  return { ...limits, fetchedAt: new Date().toISOString() };
}

function percentage(value: number | undefined): string {
  return value === undefined ? "--" : `${value}%`;
}

export function usageColor(value: number | undefined): "dim" | "success" | "warning" | "error" {
  if (value === undefined) return "dim";
  return value > 90 ? "error" : value > 70 ? "warning" : "success";
}

function styledPercentage(value: number | undefined, theme: any): string {
  return theme.fg(usageColor(value), value === undefined ? "--" : `${value}%`);
}

export function compactReset(value: string | undefined, now = Date.now()): string {
  if (!value) return "--";
  const remaining = new Date(value).valueOf() - now;
  if (!Number.isFinite(remaining)) return "--";
  if (remaining <= 0) return "now";
  const minutes = remaining / 60_000;
  if (minutes < 1) return "<1m";
  if (minutes < 60) return `${Math.ceil(minutes)}m`;
  const hours = minutes / 60;
  if (hours < 24) return `${Math.ceil(hours)}h`;
  return `${Math.ceil(hours / 24)}d`;
}

function resetLabel(value: string | undefined): string {
  return value ? new Date(value).toLocaleString() : "unknown";
}

export function fableDetail(fable: Window | undefined): string {
  return fable
    ? `  Fable: ${percentage(fable.used)} used; resets ${resetLabel(fable.resetsAt)}`
    : "  Fable: not reported";
}

export function providerAge(provider: { fetchedAt: string } | undefined, now = Date.now()): number {
  if (!provider) return Number.POSITIVE_INFINITY;
  const fetched = Date.parse(provider.fetchedAt);
  return Number.isFinite(fetched) ? Math.max(0, now - fetched) : Number.POSITIVE_INFINITY;
}

export function visibleProvider<T extends { fetchedAt: string }>(provider: T | undefined, now = Date.now()): T | undefined {
  return provider && providerAge(provider, now) <= EXPIRE_MS ? provider : undefined;
}

export function providerStatus(provider: { fetchedAt: string } | undefined, error: ProviderError | undefined, now = Date.now()): string | undefined {
  if (error) return error;
  const age = providerAge(provider, now);
  if (provider && age > EXPIRE_MS) return "cached data expired";
  if (provider && age > STALE_MS) return "stale cache";
  return undefined;
}

export function shouldAdoptCache(loadVersion: number, currentVersion: number, startGeneration: number, currentGeneration: number): boolean {
  return loadVersion === currentVersion && startGeneration === currentGeneration;
}

export default function (pi: ExtensionAPI) {
  let snapshot: Snapshot = {};
  let pollTimer: ReturnType<typeof setInterval> | undefined;
  let displayTimer: ReturnType<typeof setInterval> | undefined;
  let active: { generation: number; promise: Promise<void> } | undefined;
  let shutdown = new AbortController();
  let generation = 0;
  let stateVersion = 0;

  const updateStatus = (ctx: ExtensionContext) => {
    if (!ctx.hasUI) return;
    const theme = ctx.ui.theme;
    const now = Date.now();
    const openaiData = visibleProvider(snapshot.openai, now);
    const claudeData = visibleProvider(snapshot.claude, now);
    const openai = openaiData?.weekly.used;
    const session = claudeData?.session.used;
    const weekly = claudeData?.weekly.used;
    const fable = claudeData?.fable;
    const openaiStale = providerStatus(snapshot.openai, snapshot.errors?.openai, now);
    const claudeStale = providerStatus(snapshot.claude, snapshot.errors?.claude, now);
    const staleMark = (stale: string | undefined) => stale ? ` ${theme.fg("dim", "~")}` : "";
    const openaiStatus = `${theme.fg("mdLink", "ChatGPT")} ${styledPercentage(openai, theme)} ${theme.fg("dim", `(${compactReset(openaiData?.weekly.resetsAt, now)})`)}${staleMark(openaiStale)}`;
    const claudeWindows = [
      `${styledPercentage(session, theme)} ${theme.fg("dim", `(${compactReset(claudeData?.session.resetsAt, now)})`)}`,
      `${styledPercentage(weekly, theme)} ${theme.fg("dim", `(${compactReset(claudeData?.weekly.resetsAt, now)})`)}`,
      fable ? `${theme.fg("mdLink", "Fable")} ${styledPercentage(fable.used, theme)} ${theme.fg("dim", `(${compactReset(fable.resetsAt, now)})`)}` : undefined,
    ].filter((value): value is string => Boolean(value));
    ctx.ui.setStatus("account-limits-1-openai", openaiStatus);
    ctx.ui.setStatus("account-limits-2-claude", `${theme.fg("dim", "│")} ${theme.fg("mdLink", "Claude")} ${claudeWindows.join(` ${theme.fg("dim", "·")} `)}${staleMark(claudeStale)}`);
  };

  const refresh = (ctx: ExtensionContext): Promise<void> => {
    const runGeneration = generation;
    if (active?.generation === runGeneration) return active.promise;
    const runSignal = shutdown.signal;
    const promise = (async () => {
      const [openai, claude] = await Promise.allSettled([
        fetchOpenAI(ctx, runSignal),
        fetchClaude(ctx, runSignal),
      ]);
      if (runGeneration !== generation) return;
      snapshot.errors = {};
      if (openai.status === "fulfilled") snapshot.openai = openai.value;
      else snapshot.errors.openai = sanitizeError(openai.reason);
      if (claude.status === "fulfilled") snapshot.claude = claude.value;
      else snapshot.errors.claude = sanitizeError(claude.reason);
      stateVersion += 1;
      await saveCache(snapshot, () => runGeneration === generation).catch(() => {});
      if (runGeneration === generation) updateStatus(ctx);
    })();
    const slot = { generation: runGeneration, promise };
    active = slot;
    void promise.finally(() => { if (active === slot) active = undefined; }).catch(() => {});
    return promise;
  };

  pi.on("session_start", (_event, ctx) => {
    generation += 1;
    const startGeneration = generation;
    if (pollTimer) clearInterval(pollTimer);
    if (displayTimer) clearInterval(displayTimer);
    shutdown.abort();
    shutdown = new AbortController();
    snapshot = {};
    stateVersion += 1;
    const loadVersion = stateVersion;
    pollTimer = setInterval(() => { void refresh(ctx).catch(() => {}); }, POLL_MS);
    displayTimer = setInterval(() => {
      if (startGeneration === generation) updateStatus(ctx);
    }, 60_000);
    void (async () => {
      const cached = await loadCache();
      if (startGeneration !== generation) return;
      if (shouldAdoptCache(loadVersion, stateVersion, startGeneration, generation)) snapshot = cached;
      updateStatus(ctx);
      await refresh(ctx);
    })().catch(() => {});
  });

  pi.on("session_shutdown", (_event, ctx) => {
    generation += 1;
    if (pollTimer) clearInterval(pollTimer);
    if (displayTimer) clearInterval(displayTimer);
    pollTimer = undefined;
    displayTimer = undefined;
    shutdown.abort();
    if (ctx.hasUI) {
      ctx.ui.setStatus("account-limits-1-openai", undefined);
      ctx.ui.setStatus("account-limits-2-claude", undefined);
    }
  });

  pi.registerCommand("limits", {
    description: "Refresh and show account quota limits",
    handler: async (_args, ctx) => {
      await refresh(ctx);
      const now = Date.now();
      const openai = visibleProvider(snapshot.openai, now);
      const claude = visibleProvider(snapshot.claude, now);
      const openaiStatus = providerStatus(snapshot.openai, snapshot.errors?.openai, now);
      const claudeStatus = providerStatus(snapshot.claude, snapshot.errors?.claude, now);
      const lines = [
        "ChatGPT",
        `  Weekly: ${percentage(openai?.weekly.used)} used`,
        `  Resets: ${resetLabel(openai?.weekly.resetsAt)}`,
        openaiStatus ? `  Status: ${openaiStatus}` : undefined,
        "Claude",
        `  Session: ${percentage(claude?.session.used)} used; resets ${resetLabel(claude?.session.resetsAt)}`,
        `  Week: ${percentage(claude?.weekly.used)} used; resets ${resetLabel(claude?.weekly.resetsAt)}`,
        fableDetail(claude?.fable),
        claudeStatus ? `  Status: ${claudeStatus}` : undefined,
      ].filter((line): line is string => Boolean(line));
      ctx.ui.notify(lines.join("\n"), openaiStatus || claudeStatus ? "warning" : "info");
    },
  });
}
