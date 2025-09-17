## Problem 4 — How to run

This folder contains the implementations in `index.ts` and a small runner `run.ts`.

### Option 1: Run directly with ts-node (recommended)

From the repo root:

```bash
npx --yes ts-node --compiler-options '{"module":"commonjs"}' src/problem4/run.ts 10
```

- Replace `10` with any non-negative integer `n`.
- The `--compiler-options` flag forces CommonJS so it works without a project `tsconfig.json`.

Expected output format:

```
n = 10
sum_to_n_a: 55
sum_to_n_b: 55
sum_to_n_c: 55
```

### Option 2: Compile then run with Node

```bash
npx tsc --target es2019 --module commonjs --outDir dist src/problem4/*.ts
node dist/problem4/run.js 10
```

### Files

- `index.ts`: exports `sum_to_n_a`, `sum_to_n_b`, `sum_to_n_c`.
- `run.ts`: CLI runner. Pass `n` as the first argument.


