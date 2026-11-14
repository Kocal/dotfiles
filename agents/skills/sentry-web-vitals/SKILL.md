---
name: sentry-web-vitals
description: Use when investigating front-end performance seen by real visitors through Sentry - Core Web Vitals (LCP, CLS, INP, FCP, TTFB), long animation frames (LoAF), a Sentry Web Vitals dashboard, a page that jumps or janks while loading or scrolling - or when turning that field data into a Chrome lab trace and a fix ticket.
---

# Web Vitals from Sentry

Three sources, three roles: Sentry (field data) names the problem, a Chrome trace (lab) shows the
mechanism, a line of code proves it. When one of the three is missing, the ticket says "cause not
identified" and describes how to find it. It never invents one.

## 1. Field data: the Sentry events API

Prebuilt Web Vitals dashboards return `widgets: []` through the API: query the spans directly.
Run a `fetch` from a Sentry tab that is already logged in (chrome-devtools `evaluate_script`): the
session cookie is enough for a GET, no token needed.

```js
async () => {
	const p = new URLSearchParams([
		['dataset', 'spans'], ['project', '<project-id>'], ['statsPeriod', '14d'],
		['query', 'span.op:ui.webvital.cls transaction:<transaction>'],
		['field', 'browser.web_vital.cls.source.1'], ['field', 'count()'], ['field', 'p75(measurements.cls)'],
		['sort', '-count()'], ['per_page', '20'],
	]);
	return (await (await fetch('/api/0/organizations/<org>/events/?' + p)).json()).data;
}
```

Several values in `query`: `span.op:[a,b]`, `transaction:[a,b]`. List the transactions first with
`field=transaction&field=count()` on `span.op:pageload`.

| Metric | `span.op` | Aggregate | Group by |
|---|---|---|---|
| LCP | `ui.webvital.lcp` | `p75(measurements.lcp)` | `lcp.element` |
| CLS | `ui.webvital.cls` | `p75(measurements.cls)` | `browser.web_vital.cls.source.1` |
| INP | `ui.interaction.click` (also `.press`, `.hover`, `.drag`) | `p75(measurements.inp)` | `browser.web_vital.inp.target` |
| FCP, TTFB | `pageload` | `p75(measurements.fcp)`, `p75(measurements.ttfb)` | `transaction` |
| Long animation frames | `ui.long_animation_frame` | `sum(span.duration)`, `p75(span.duration)` | `browser.script.invoker` |
| Document phases | `[browser.connect,browser.request,browser.response]` | `p75(span.duration)` | `transaction`, `span.op` |

List the available attributes:
`/api/0/organizations/<org>/trace-items/attributes/?itemType=spans&attributeType=string&substringMatch=<x>`.

## 2. Traps

| Trap | Reality |
|---|---|
| `statsPeriod=14d` means 14 days of data | It is only the upper bound. Read the real window (`field=min(timestamp)`, `field=max(timestamp)`) before quoting a period: one "14 days" query held 11 hours. |
| LCP or CLS read on `pageload` | Both are `null` there. They live on their own spans (table above). |
| Grouping by `cls.source.1` | The short name exists and is always `null`. Use `browser.web_vital.cls.source.1`. |
| Expecting a script URL on a long frame | LoAF carries only `browser.script.invoker`, so a big `setTimeout` stays anonymous. Attribute it in a Chrome trace: in the main-thread flame chart, "Timer fired" leads to the function and its file. |
| Cross-origin resource sizes of 0 | The CDN does not send `Timing-Allow-Origin`. The size is unknown, not zero. |
| High TTFB blamed on the server | Compare `browser.connect` and `browser.request` per transaction. A cold connection can be most of it while the server time matches other pages. |

## 3. Lab: a Chrome trace of production

Trace the production site, the one Sentry measures (edge, CDN, third-party tags included), with
the chrome-devtools MCP:

1. `new_page` with `url` and `isolatedContext` set to a fresh name (`"perf-anon"`, `"perf-anon-2"`):
   a cold visitor without cookies, so the consent banner shows as it does for real visitors.
2. `emulate` with `viewport: "412x915x2.625,mobile,touch"`, `cpuThrottlingRate: 4`,
   `networkConditions: "Slow 4G"`.
3. `performance_start_trace` with `reload`, `autoStop` and `ignoreCache` set to `true`, and **no
   `filePath`** (paths outside the MCP's workspace roots are refused).
4. `performance_analyze_insight` with the `insightSetId` printed by the trace (`NAVIGATION_0`, then
   `NAVIGATION_1` for a second trace in the same tab) and one of the listed insights: `LCPBreakdown`
   and `LCPDiscovery` for LCP, `CLSCulprits` for CLS, `ForcedReflow` for long frames,
   `ImageDelivery` for image weight, `ThirdParties` for tags.

Trace every state of a page that renders differently (finished vs upcoming, logged in vs not):
they do not share the same problems. After an MCP reconnection the `pageId`s change: run
`list_pages` again. LCP-specific work: **REQUIRED SUB-SKILL** `debug-optimize-lcp`.

## 4. Recurring causes

| Sentry shows | Typical cause | Fix |
|---|---|---|
| CLS on a ticker, carousel or scrolling banner | jQuery animates `left` or `margin-left`: every frame counts as a layout shift | `transform: translateX()`, `@keyframes` for an endless scroll |
| LoAF on `DOMWindow.onscroll` | unthrottled `$(window).scroll()` reading `offset()` then writing a margin (forced reflow per scroll) | `position: sticky`, `IntersectionObserver` |
| LoAF on `#document.onDOMContentLoaded` | chained JS initialisations that never yield | `scheduler.yield()` between steps, defer below-the-fold init |
| Late image LCP | `<img>` without `fetchpriority="high"` nor `width`/`height` | add them |
| Wasted bytes on every page | huge image displayed small | export at 2x the displayed size |

## 5. Writing the ticket

- Three sections: **Finding** (p75 and volume from Sentry, mechanism, `path:line`), **To do**
  (actions, then what to watch in Sentry to confirm the gain), **Links** (Explore link,
  permalinks, data window, screenshots).
- **Data window line**, from `min(timestamp)` / `max(timestamp)` converted to the reader's timezone:
  "Sentry data: from 03/11 09:12 to 05/11 22:40."
- **Explore link** in aggregate mode, on the absolute range of the real window so it stays valid.
  JSON url-encoded, parentheses as `%28`/`%29` or the Markdown link breaks at the first `)`.
  Explore writes `count(span.duration)` where the API writes `count()`. `start`/`end` are UTC:

  ```
  https://<org>.sentry.io/explore/traces/?mode=aggregate&project=<project-id>&aggregateField=%7B%22groupBy%22%3A%22browser.web_vital.cls.source.1%22%7D&aggregateField=%7B%22yAxes%22%3A%5B%22count%28span.duration%29%22%5D%7D&aggregateSort=-count%28span.duration%29&query=span.op%3Aui.webvital.cls%20transaction%3A<transaction>&start=2026-10-27T09%3A00%3A00&end=2026-10-27T22%3A00%3A00&utc=true
  ```

- **Screenshots**: `take_screenshot` without `filePath` saves into the session's tool-results
  folder; copy the file where the ticket tool can attach it.
