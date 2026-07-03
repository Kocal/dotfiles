---
name: webpack-encore-ts-migration
description: Convert symfony/webpack-encore source files from JavaScript to TypeScript (issue #816), following the project's strict tsconfig, dist build, and import-extension conventions.
---

## When to Activate

Use this skill when migrating files in the `symfony/webpack-encore` repo from `.js` to `.ts`. The integration branch is `typescript-migration`; each batch is a `typescript/<area>` branch (e.g. `typescript/loaders`, `typescript/plugins`) opened as a PR against `typescript-migration`, not `main`. Operate **only on the files the user gives you** for the current batch; do not migrate unrelated files.

Setup is already in place: `tsconfig.json` (strict, `extends @tsconfig/node22`, `allowJs`, `rewriteRelativeImportExtensions`, `allowImportingTsExtensions`, `erasableSyntaxOnly`), `pnpm build` (tsc -> `dist/` with `.js` + `.d.ts`), eslint, oxfmt. The package ships compiled `dist/`, never raw `.ts`.

## Core Rules

1. **Convert each given file** `x.js` -> `x.ts` (e.g. `git rm x.js` + write `x.ts`, or `git mv` then edit). Keep the license header verbatim.
2. **Add real types** to satisfy `strict`. Replace JSDoc `@param {T}`/`@returns {T}` with TS annotations (keep prose descriptions). Turn JSDoc `@import X from '...'` / `@typedef` into real `import type` / `type` declarations. `export` any type other files reference (e.g. via `@import { OptionsCallback }`).
3. **Import-extension convention** — when an import RESOLVES TO a migrated `.ts` file, write the specifier with `.ts` (e.g. `import x from './utils/foo.ts'`). `rewriteRelativeImportExtensions` rewrites `.ts` -> `.js` in the emitted `dist/`, and eslint-plugin-n needs the real `.ts` file to exist. Imports to still-`.js` files keep `.js`.
4. **After migrating a file, update ALL its importers** (across `index.js`, `lib/`, `test/`) to use the `.ts` specifier. Miss none, or `n/no-missing-import` fails on the now-removed `.js`.
5. **Keep these as `.js` (the rewrite/eslint do NOT cover them):**
   - JSDoc `@import { X } from './y.js'` (rewrite skips JSDoc -> a `.ts` here leaks a broken `import type from './y.ts'` into the emitted `.d.ts`).
   - `import.meta.resolve('./y.js')` / `require.resolve('./y.js')` (not import statements; resolved at runtime against emitted files).
   - Public/documented import paths in comments (e.g. `@symfony/webpack-encore/lib/plugins/plugin-priorities.js`).
   - **Dynamic `import('./y.js')` ALWAYS keeps `.js`** — `rewriteRelativeImportExtensions` does NOT rewrite dynamic `import()` (neither in `.ts` nor `.js` files), so a `.ts` specifier leaks into `dist/` and breaks at runtime. In a `.ts` file `.js` is correct (n is off for `**/*.ts`, tsc resolves `.js`->`.ts`). In a still-`.js` file, also add `// eslint-disable-next-line n/no-missing-import` on a one-line import (so oxfmt keeps the disable aligned); remove it when that file itself migrates.
6. **Untyped deps** under strict: add the matching `@types/*` devDep (e.g. `@types/semver`) rather than casting. `any` is acceptable only at genuine dep boundaries that ship no types.
7. **Always reach for the most precise type — never default to `object`/`object[]` or `any`.** These are placeholders, not types; replace them wherever a concrete type exists. Before writing `object` or `any`, look for the real type:
   - **Upstream library types** — annotate with the type the package already exports: webpack plugin instances as `WebpackPluginInstance`, a loader `use`/`loaders` array as `RuleSetUseItem[]`, rule callbacks as `webpack.RuleSetRule`. Import as `import type { WebpackPluginInstance } from 'webpack'`, or reuse `webpack.X` in files already doing `import webpack from 'webpack'`.
   - **Your own shapes** — write an explicit `type`/`interface` (or `Record<string, T>` when keys are dynamic) instead of `object`.
   - **`object` / `Record<string, unknown>`** — acceptable ONLY for genuinely arbitrary third-party option bags threaded through `applyOptionsCallback` (ts-loader / babel / `webpack-manifest-plugin` options, manifest `seed`, css-loader `modules`), where no good upstream type exists.
   - **`any`** — last resort, only at a genuine dep boundary that ships no types (see rule 6); prefer `unknown` + a narrowing check over `any` when you must accept something opaque.
8. **Never disable `n/no-missing-import` globally.** It is intentionally off only for `**/*.ts` (tsc owns resolution there); `.js` files keep it.
9. **Verify before declaring done:** `pnpm build`, `pnpm lint`, `pnpm fmt:check` (run `pnpm fmt` to fix), and the tests. All must be green, and `dist/` must contain **no residual `.ts` specifier** (imports, dynamic imports, or `.d.ts`).

## Command Reference

| Command | Purpose |
|---------|---------|
| `pnpm build` | `tsc` -> emits `dist/` (`.js` + `.d.ts`), strict type-check, fails on a missing import or type error. |
| `pnpm lint` | eslint (incl. `n/no-missing-import`, headers, jsdoc). Must be 0 warnings. |
| `pnpm fmt` / `pnpm fmt:check` | oxfmt write / check. |
| `pnpm type-check` | `tsc --noEmit` (type-check only). |

Bulk-rewrite all importers of migrated files (zsh: `$files` is one arg unquoted, so use `xargs`; BSD/macOS `sed -i ''` is brittle — prefer `perl`):

```bash
NAMES='(foo|bar|baz)'  # base names of the files just migrated
grep -rlE "<dir>/${NAMES}\.js'" index.js lib test \
  | xargs perl -i -pe "s{<dir>/${NAMES}\.js(?=')}{<dir>/\$1.ts}g"
# then revert any over-matched JSDoc @import / public-path / dynamic-import-in-.js back to .js
```

Verify no runtime `.ts` leaked into the build:

```bash
grep -rnE "from '[^']*\.ts'|import\('[^']*\.ts'\)|import type .* from '[^']*\.ts'" dist/ | grep -v ' \* '
```

## Workflow

1. Read every file in the batch the user gave you.
2. For each: convert to `.ts`, add types, set its OWN imports per rules 3 & 5.
3. Remove the old `.js` (`git rm`).
4. Update all external importers to `.ts` specifiers (rule 4), then revert exceptions (rule 5).
5. Run `pnpm build`; fix strict-mode errors (add `@types/*`, annotate option objects, cast at dep boundaries only).
6. Run `pnpm lint` + `pnpm fmt`; fix.
7. Run the relevant tests. **Do not run the full `pnpm test` locally with uncommitted `package.json` changes** — `test/bin/encore.js` runs `git checkout package.json` and would wipe them. Run a targeted subset, or commit first.
8. Confirm `dist/` has no residual `.ts` specifier.

## Examples

Migrating `lib/utils/get-vue-version.js` (imports the still-`.js` core files):

```ts
// lib/utils/get-vue-version.ts
import semver from 'semver';                       // dep: needs @types/semver under strict
import type WebpackConfig from '../WebpackConfig.js'; // still .js -> keep .js
import logger from '../logger.js';                 // still .js -> keep .js
import packageHelper from '../package-helper.js';  // still .js -> keep .js

export default function (webpackConfig: WebpackConfig): number | string | null {
    // ...
}
```

A plugin importing already-migrated utils:

```ts
import applyOptionsCallback from '../utils/apply-options-callback.ts'; // migrated -> .ts
import PluginPriorities from './plugin-priorities.ts';                 // migrated -> .ts
import type WebpackConfig from '../WebpackConfig.js';                  // not migrated -> .js
```
