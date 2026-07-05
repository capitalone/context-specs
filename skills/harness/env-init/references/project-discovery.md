# Project discovery — how to read a codebase before generating

Three artifacts env-init generates are codebase-dependent and must NOT be
hardcoded: `AGENTS.md`, `scripts/local-checks.sh`, and
`scripts/bootstrap-worktree.sh`. This file is the shared discovery procedure
that feeds all three. Run the scan once, then reuse the findings.

This is the Software-3.0 core of the skill: you read the repo, infer how it
works, propose, and let the human correct you. Auto-discover as much as
possible; ask only where signals are genuinely absent or conflicting.

## What to read (strongest signals first)

1. **Dependency manifests** — the single best signal for the toolchain:
   `package.json` (+ lockfile: `package-lock.json` / `pnpm-lock.yaml` /
   `yarn.lock` / `bun.lockb`), `pyproject.toml` / `requirements.txt` /
   `uv.lock` / `Pipfile`, `Cargo.toml`, `go.mod`, `Gemfile`, `pom.xml` /
   `build.gradle`, `composer.json`, `mix.exs`, etc.
2. **Scripts already defined** — `package.json` `"scripts"`, `Makefile` /
   `Justfile` / `Taskfile.yml`, `pyproject.toml` `[tool.*]` sections. These tell
   you what the project already calls "lint", "test", "build", "dev".
3. **Getting-started docs** — `README.md`, `CONTRIBUTING.md`, `docs/`. Search
   for "setup", "install", "getting started", "development", "prerequisites".
   This is how the project tells a new human dev to set up — exactly what
   `bootstrap-worktree.sh` automates.
4. **CI config** — `.github/workflows/*.yml`, `.gitlab-ci.yml`,
   `.circleci/config.yml`, `Dockerfile`. The CI "setup" and "test" steps are a
   gold-standard, already-working recipe for provisioning + checking.
5. **`.gitignore`** — tells you what is NOT in git, i.e. what a fresh worktree
   will be missing. Cross-reference against what's needed to run.
6. **Env/secret templates** — `.env.example`, `.env.sample`, `.env.template`,
   `config/*.example.*`. These name the real (gitignored) files that must be
   present to run.
7. **Codegen signals** — `prisma/schema.prisma`, `*.proto`, `codegen.yml` /
   GraphQL codegen, `*.gen.go` patterns, `buf.yaml`, ORM migration dirs,
   protobuf/thrift, sqlc. These need a generate step before the project runs.
8. **Pre-commit / hook config** — `.pre-commit-config.yaml`, `lefthook.yml`,
   `.husky/`. Tells you what deterministic checks already exist (don't
   duplicate them; `local-checks.sh` can just call them).

## What to extract

After scanning, you should be able to fill in this picture for the user:

| Dimension | Example finding |
|-----------|-----------------|
| Package manager / runtime | `pnpm` + Node 20 (from `pnpm-lock.yaml` + `.nvmrc`) |
| Install command | `pnpm install --frozen-lockfile` |
| Lint / format | `pnpm lint` (eslint), `pnpm format` (prettier) |
| Typecheck | `pnpm typecheck` (tsc --noEmit) |
| Test | `pnpm test` (vitest) |
| Build | `pnpm build` (next build) |
| Dev server | `pnpm dev` on port 3000 (note for port-collision) |
| Gitignored runtime files | `.env.local`, `.env` (named by `.env.example`) |
| Codegen | `prisma generate` (from `prisma/schema.prisma`) |
| Existing hooks | husky pre-commit running lint-staged |

## How to present findings

1. State what you found and the signal you found it from ("`pnpm-lock.yaml`
   present, so I'll use `pnpm`").
2. Flag low-confidence inferences explicitly and ask.
3. Never invent a command you didn't see evidence for. If you can't determine
   how the project installs deps or runs codegen, **ask** rather than guess —
   the bootstrap script is worthless if it's wrong.

## Per-stack quick reference (commands, for orientation only — verify against the repo)

| Stack | Install | Lint/format | Typecheck | Test |
|-------|---------|-------------|-----------|------|
| Node/npm | `npm ci` | `npm run lint` / `npm run format` | `npm run typecheck` or `tsc --noEmit` | `npm test` |
| Node/pnpm | `pnpm i --frozen-lockfile` | `pnpm lint` | `pnpm typecheck` | `pnpm test` |
| Python/uv | `uv sync` | `ruff check` / `ruff format` | `mypy .` / `pyright` | `pytest` |
| Python/poetry | `poetry install` | `ruff check` | `mypy .` | `pytest` |
| Rust | `cargo fetch` | `cargo clippy` / `cargo fmt` | `cargo check` | `cargo test` |
| Go | `go mod download` | `golangci-lint run` / `gofmt -l` | `go vet ./...` | `go test ./...` |
| Ruby | `bundle install` | `rubocop` | — | `rspec` / `rake test` |

These are starting points. The project's own `package.json`/`Makefile` scripts
override them — prefer the command the project already defines over the generic
one, because it carries the project's flags and config.
