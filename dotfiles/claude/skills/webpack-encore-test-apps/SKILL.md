---
name: webpack-encore-test-apps
description: Add or modify a CI test app under test_apps/ in the symfony/webpack-encore repo. Enforces the lowest-peers naming convention, exact version pins, and matrix-entry layout in testing_apps.yml.
---

## When to Activate

Trigger when the user, working inside the `symfony/webpack-encore` repository, asks to:

- "rajoute/ajoute une testing-app", "add a testing app", "new test_apps/…"
- create a new directory under `test_apps/` to exercise a specific peer dependency edge (TypeScript version, Svelte version, fork-ts-checker branch, webpack-cli major, etc.)
- update the CI matrix in `.github/workflows/testing_apps.yml`

Do **not** activate for changes inside other repos, or for app code that has nothing to do with `test_apps/`.

## Core Rules

1. **Folder name MUST use the `lowest-peers-` prefix** (e.g. `lowest-peers-typescript5`, `lowest-peers-svelte4`). Never create a top-level `test_apps/<topic>/` without the prefix unless the user explicitly overrides.
2. **`devDependencies` versions MUST be EXACT** — no `^`, no `~`, no ranges (e.g. `"typescript": "5.0.0"`, not `"^5.0.0"`).
3. **Pinned version = lowest end of the matching `peerDependencies` range** in the root `package.json` of the repo. Example: `^5.0.0 || ^6.0.0` → pin `5.0.0`.
4. **Do NOT add `ts-loader` or `fork-ts-checker-webpack-plugin`** when the app exercises `enableBabelTypeScriptPreset()` — that API is mutually exclusive with `enableTypeScriptLoader()` / `enableForkedTypeScriptTypesChecking()` (see `lib/WebpackConfig.js`).
5. **Always generate `pnpm-lock.yaml`** with `pnpm install --ignore-workspace` and commit it. CI runs with `--frozen-lockfile` and `setup-node` caches by `${working_directory}/pnpm-lock.yaml`.
6. **Mirror an existing `lowest-peers-*` app** as the template instead of writing from scratch — that's how layout, scripts, and lockfile flags stay consistent.

## File Structure

Each `test_apps/lowest-peers-<topic>/` directory contains:

```
lowest-peers-<topic>/
├── .gitignore           # exactly: public/build
├── README.md            # short blurb + install/usage block
├── assets/
│   └── app.<ext>        # .ts for TypeScript apps, .js otherwise
├── package.json         # exact-pin devDependencies, type: module
├── pnpm-lock.yaml       # generated, committed
├── tsconfig.json        # only for TypeScript apps
└── webpack.config.js    # ESM, imports @symfony/webpack-encore
```

## Templates

### `package.json` (TypeScript + Babel preset example)

```json
{
  "license": "UNLICENSED",
  "private": true,
  "type": "module",
  "scripts": {
    "encore": "encore"
  },
  "devDependencies": {
    "@babel/core": "7.17.0",
    "@babel/preset-env": "7.16.0",
    "@babel/preset-typescript": "7.0.0",
    "typescript": "5.0.0",
    "webpack": "5.82.0",
    "webpack-cli": "6.0.0"
  }
}
```

### `webpack.config.js`

```javascript
import Encore from '@symfony/webpack-encore';

Encore
    .setOutputPath('public/build/')
    .setPublicPath('/build')
    .enableSingleRuntimeChunk()
    .enableBabelTypeScriptPreset()
    .addEntry('app', './assets/app.ts')
;

export default await Encore.getWebpackConfig();
```

### Matrix entry in `.github/workflows/testing_apps.yml`

Insert next to sibling `lowest peers (…)` entries:

```yaml
                    - name: lowest peers (<topic short label>)
                      pkg_manager: pnpm
                      working_directory: test_apps/lowest-peers-<topic>
                      script: |
                          pnpm install --ignore-workspace --frozen-lockfile
                          pnpm add --ignore-workspace --save-dev ../../webpack-encore.tgz
                          pnpm run encore dev
                          pnpm run encore production
```

The `--ignore-workspace` flag is mandatory for every `lowest-peers-*` entry — without it pnpm pulls hoisted versions from the repo root and the lowest-peers contract breaks.

### `README.md`

```markdown
# Testing app: lowest-peers-<topic>

Pins `<package>@<version>` (plus core peer deps) to their lowest supported versions declared in Encore's `peerDependencies`. <one-line scope sentence>.

## Installation

\`\`\`shell
$ (cd ../..; pnpm pack --out webpack-encore.tgz)
$ pnpm install --ignore-workspace --frozen-lockfile
$ pnpm add --ignore-workspace --save-dev ../../webpack-encore.tgz
\`\`\`

## Usage

\`\`\`
$ pnpm run encore dev
$ pnpm run encore production
\`\`\`
```

## Workflow

1. **Mirror.** Pick the closest existing `test_apps/lowest-peers-*` app and copy its layout (`tsconfig.json`, `assets/app.*`, `.gitignore`, `README.md`).
2. **Pin versions.** Open the root `package.json`, read `peerDependencies`, and write the lowest bound as an exact pin into the new `package.json`. No ranges.
3. **Config Encore.** Adjust `webpack.config.js` to call only the methods the app exercises. Respect mutual-exclusion rules between Encore APIs.
4. **Generate the lockfile.** `cd test_apps/lowest-peers-<topic> && pnpm install --ignore-workspace`. Commit `pnpm-lock.yaml`.
5. **Smoke-test locally.** From inside the app directory: `(cd ../..; pnpm pack --out webpack-encore.tgz) && pnpm add --ignore-workspace --save-dev ../../webpack-encore.tgz && pnpm run encore dev && pnpm run encore production`. Inspect `public/build/app.js` to confirm the build emitted JS (no residual TS syntax, no errors).
6. **Register in CI.** Add a matrix entry in `.github/workflows/testing_apps.yml` next to the sibling `lowest peers (…)` entries, using the script block above.
7. **Update memory if a new convention emerges** (scope of versions covered, new Encore API exercised, etc.).

## Examples

### User: "Rajoute une testing-app TypeScript 5 utilisant le preset Babel TypeScript"

1. Mirror `test_apps/lowest-peers-typescript-fork9/` (same TS toolchain, drop fork-ts-checker / ts-loader).
2. Create `test_apps/lowest-peers-typescript5/` with exact pins matching root `peerDependencies` lowest bounds (`typescript: 5.0.0`, `@babel/preset-typescript: 7.0.0`, etc.).
3. `webpack.config.js` calls `enableBabelTypeScriptPreset()` (mutually exclusive with `enableTypeScriptLoader()`).
4. Generate `pnpm-lock.yaml` via `pnpm install --ignore-workspace`.
5. Add matrix entry `lowest peers (TypeScript 5 with Babel preset)` in `.github/workflows/testing_apps.yml`, inserted alongside the other `lowest peers (TypeScript + …)` entries.

### User: "Bump the lowest-peers webpack-cli to v7"

Do NOT bump the existing `lowest-peers-webpack-cli6` app — create a sibling `lowest-peers-webpack-cli7` with the new exact pin. The "lowest" apps lock the *lower* bound; covering a new major needs a new app, not an in-place edit.
