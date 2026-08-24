# LLM Wiki — Target State

## 1. Purpose

The LLM Wiki is an **agent-readable semantic map of the enterprise**. Its purpose is not to duplicate source code or become a traditional documentation repository. Its purpose is to help an agent quickly determine:

- what exists,
- why it exists,
- how systems and business concepts connect,
- which inputs, outputs, and key fields drive behavior,
- which business processes and metrics are supported by which systems,
- where the authoritative implementation truth lives,
- and where to drill deeper when more detail is required.

The Wiki is designed around **agentic search and progressive disclosure**. An agent should begin with a small amount of high-value context, choose the next relevant knowledge bundle, and only descend into source when necessary.

The source remains the detailed implementation truth. The Wiki makes that truth **legible, navigable, and usable by agents**.

---

## 2. Target-State Principles

### 2.1 Progressive disclosure remains the primary consumption model

The Wiki will continue to use OKF-style navigation:

```text
index.md
  ↓
relevant area
  ↓
relevant entity / bundle
  ↓
deeper context when needed
  ↓
authoritative source
```

The target state does **not** replace this with a traditional RAG-first architecture or force agents to use a large collection of custom retrieval tools.

Agents should be allowed to reason naturally over indexes, descriptions, links, and bundles.

### 2.2 Git is the canonical knowledge source, not the end-user experience

GitHub remains the canonical persistence and governance layer for durable Wiki knowledge because it provides:

- version history,
- PR review,
- CODEOWNERS,
- auditability,
- rollback,
- branching for short-lived authoring workflows,
- CI validation,
- and familiar developer governance.

However, consumers should not need to understand or operate Git.

> No user should need to clone, pull, synchronize, or understand the Wiki's storage topology in order to consume it.

Likewise:

> No user should need to understand Git mechanics in order to contribute knowledge.

Git is an implementation detail of governance, not the primary Wiki UX.

### 2.3 The Wiki summarizes semantic truth, not exhaustive implementation

The Wiki should contain information that is **expensive for a fresh agent to repeatedly rediscover from source**.

Examples of information that belongs in the Wiki:

- business intent,
- system responsibilities,
- important inputs and outputs,
- key fields that materially drive behavior,
- meaningful transformations of those fields,
- producer / consumer relationships,
- business processes supported,
- metrics affected or supported,
- architectural boundaries,
- ownership,
- important decisions and constraints,
- invariants,
- system-of-record relationships,
- operational meaning,
- and authoritative source locations.

Examples that normally remain in source:

- exhaustive implementation details,
- class and method structure,
- every schema field,
- local algorithms,
- line-level control flow,
- detailed configuration,
- and rapidly changing implementation mechanics.

The boundary is not simply "high-level vs. low-level."

The governing question is:

> Would a fresh agent have to perform meaningful investigation to rediscover this fact, and is the fact important enough to shape its mental model or decisions?

### 2.4 Wiki assertions should remain verifiable

Knowledge should retain enough provenance for an agent to move from:

```text
Wiki assertion
    ↓
evidence / authoritative location
    ↓
source
```

The goal is not blind trust in summaries. The goal is **efficient discovery plus cheap verification**.

### 2.5 Current truth and proposed future state must remain distinct

Current-state knowledge must never be silently overwritten by a proposal.

Future-state thinking is represented through first-class **Plans / Changes** that reference and overlay the current Wiki.

### 2.6 Conversation to persistence is seamless

The system should preserve a continuous user experience even though reads and writes use different backing mechanisms.

A user may begin with read-only published context and later decide to persist an idea. The infrastructure should lazily create the governed Git authoring state without forcing the user to restart, clone, checkout, or otherwise leave the conversation.

---

## 3. Conceptual Architecture

```text
                          DATA SOURCES
               ┌─────────────┼───────────────┐
               │             │               │
             Git          Registry        Metrics / Other
               │             │               │
               └─────────────┼───────────────┘
                             ↓
                     INGEST / RECONCILE
                             ↓
                    Proposed OKF changes
                             ↓
                       PR + review
                             ↓
                    ┌── CANONICAL WIKI ──┐
                    │      Git / OKF      │
                    └─────────┬───────────┘
                              ↓
                       Publish pipeline
                              ↓
                       S3 / CloudFront
                              ↓
                    Local read-only cache
                              ↓
                    Enterprise discovery
                       when beneficial
                              ↓
                           index.md
                              ↓
                   Agentic progressive
                       disclosure
                              ↓
             ┌────────────────┼────────────────┐
             ↓                ↓                ↓
          Source            Plans          Consumers
                             │
                   shared drafts publish
                   as serving-plane previews
                             │             text / visual /
                             │             audience lens
                             ↓
                     Future-state overlay
```

A separate learning loop improves Wiki maintenance over time:

```text
Human Wiki PR decisions
          ↓
 Episodic long-term memory
          ↓
 Better significance / review judge
          ↓
 Increasingly autonomous maintenance
```

---

## 4. Authoring Plane

The **authoring plane** is where durable Wiki knowledge is created or changed.

Inputs may include:

- developer-initiated repository ingestion,
- schema-registry discovery,
- architecture discovery,
- manual human edits,
- source-change events,
- metric metadata,
- architectural decisions,
- and published Plans.

The authoring workflow may be exposed through a CLI, an agent experience, or other UI. Users should not need to manually manage Git operations.

Conceptually:

```text
human / agent / event
        ↓
proposed Wiki change
        ↓
validation
        ↓
GitHub PR
        ↓
review
        ↓
merge
```

GitHub is retained because PRs provide a strong governance and training surface.

### 4.1 Authoring is lazy

A normal Wiki conversation should not require a Git checkout. Most sessions are read-only exploration and should run entirely against the published serving-plane copy.

A writable Git workspace is created only when the user decides that something from the conversation is worth persisting.

```text
conversation against published Wiki
            ↓
      "save this"
            ↓
   promote to knowledge draft
            ↓
 lazily materialize Git workspace
            ↓
 continue in the same conversation
```

The user should experience this as **promotion from conversation into durable knowledge**, not as a manual switch from S3 to Git.

### 4.2 Git branches are an authoring mechanism, not a knowledge model

A short-lived feature branch is a reasonable implementation for editing a proposed Wiki change, including a Plan.

The CLI/runtime may hide operations such as:

- locating the canonical Wiki repository,
- creating or refreshing a local authoring workspace,
- creating a feature branch,
- writing the OKF change,
- committing,
- pushing,
- and opening a Draft PR.

The branch is temporary authoring state. Once published, the Plan or other entity exists as knowledge in the Wiki and is not identified by its Git branch.

### 4.3 The skill reasons; the harness manages state

The conversational skill should recognize when a user wants to persist, share, or publish knowledge. It should not encode complex Git mechanics in prompt instructions.

The runtime/CLI should provide deterministic authoring operations and manage authentication, repository selection, branch creation, baseline revisions, workspace paths, and permissions.

> The agent manages knowledge. The harness manages authoring state.

---

## 5. Serving Plane

The **serving plane** is not a replacement for OKF progressive disclosure.

It answers a different question:

> How does every authorized agent receive a fresh, versioned, seamless view of the canonical Wiki without developers manually synchronizing Git repositories?

### 5.1 Initial target direction: published OKF bundles via S3 / CloudFront

The current preferred direction is:

```text
GitHub Wiki
    ↓ publish pipeline
versioned OKF bundle
    ↓
S3
    ↓
CloudFront
    ↓
local read-only Wiki cache
    ↓
Claude Code / other agent
    ↓
index.md
    ↓
agentic progressive disclosure
```

The GitHub Wiki remains canonical. Its pipeline publishes immutable/versioned OKF files to the serving plane. A lightweight manifest can identify the latest available revision so the CLI only refreshes changed content.

The local filesystem representation is valuable because it preserves the native Wiki interaction model: the agent reads `index.md`, chooses the next relevant file or bundle, and progressively discloses context without requiring a RAG query for every step.

The exact sync implementation may evolve, but S3 + CloudFront + a local read-only cache is the preferred initial architecture.

### 5.2 Serving-plane requirements

The serving plane must be:

- **fresh** — changes appear without manual `git pull`,
- **fast** — normal exploration should primarily operate against local files,
- **permission-aware** — users and agents only receive context they are authorized to know,
- **versioned** — a consumer can understand which Wiki revision informed its reasoning,
- **rebuildable** — derived serving state can be reconstructed from canonical Git,
- **seamless** — consumption should feel like the Wiki is simply present.

Published artifacts should be treated as read-only. Derived search indexes, graph indexes, caches, and other acceleration mechanisms may exist alongside them, but they are disposable serving infrastructure rather than canonical truth.

> Git is the truth. Published bundles and derived indexes are rebuildable views.

### 5.3 Do not sync more knowledge than necessary

The system should not assume that the entire enterprise Wiki must be copied to every developer laptop. The serving plane should distribute the authorized organizational scope and cross-cutting context required for that user while preserving security boundaries.

---

## 6. Knowledge Organization

The Wiki is organized first by the enterprise hierarchy and then by semantic entities.

Example:

```text
enterprise/
  index.md

  lob/
    index.md

    experience/
      index.md

      repositories/
      schemas/
      architectures/
      metrics/
      business-processes/
      plans/
      standards/        # only when cross-cutting/reusable
```

A user writes primarily into the organizational area they belong to but can reference higher-level or cross-cutting enterprise concepts.

Cross-cutting concepts should be linked rather than duplicated wherever possible.

---

## 7. Core Knowledge Types and Attached Context

### 7.1 Repository

Represents a deployable or independently meaningful source repository.

The Repository entity should focus on:

- business purpose,
- responsibilities,
- owners,
- inputs,
- outputs,
- key fields,
- meaningful transformations,
- upstream and downstream dependencies,
- schemas / contracts used,
- architectures it participates in,
- business processes it supports,
- metrics it materially influences,
- constraints / invariants,
- and the authoritative repository location.

The Wiki does not attempt to reproduce the repository.

When detailed implementation knowledge is needed, the agent should inspect or shallow-clone the source.

### 7.2 Schema

Represents an externally meaningful contract such as:

- OpenAPI / Swagger,
- Kafka schema,
- event schema,
- request / response contract,
- or another shared interface.

The Wiki should emphasize:

- business meaning,
- producers,
- consumers,
- important fields,
- behavior-driving fields,
- compatibility or version concerns,
- transformations,
- and authoritative registry / source location.

### 7.3 Architecture

Represents two or more connected components that jointly implement a meaningful capability or process.

Architecture is not simply a diagram. It is a semantic description of:

- purpose,
- participating components,
- interactions,
- important inputs and outputs,
- key transformations,
- constraints,
- supported business processes,
- metrics,
- and boundaries.

Architectures may be manually authored or suggested by ingestion when meaningful connectivity is discovered.

### 7.4 Metric

Represents a measure that matters to an organization.

Examples include business, operational, risk, customer, or technology measures.

A Metric should connect to the systems and processes that actually support or influence it.

Example:

```text
NSF Rate
   ↓
Business Process
   ↓
Architecture
   ↓
Repositories / Schemas
```

The target state should make it possible for a product or technology user to begin from a metric and navigate into the systems capable of influencing it.

### 7.5 Business Process / Capability

Represents the meaningful business activity implemented by one or more architectures.

This becomes the semantic bridge between business outcomes and technical systems.

Example:

```text
Metric
  ↓
Business Process
  ↓
Architecture
  ↓
Repository / Schema
```

### 7.6 Constraints, Standards, and Decision References

Constraints and decisions are important context, but they should **not automatically become standalone peer entities**.

Default rule:

> Keep knowledge with the entity it explains. Promote it into reusable cross-cutting knowledge only when multiple entities need to reference the same rule or standard.

Examples:

- A Repository-specific idempotency rule stays with that Repository.
- An Architecture-specific ordering guarantee stays with that Architecture.
- An Experience or LOB integration constraint can live at that organizational scope.
- An enterprise requirement such as "all applications use the approved feature-flag platform" is reusable cross-cutting knowledge and should be referenced rather than copied into thousands of repositories.

Constraints may therefore inherit through organizational and architectural scope:

```text
Enterprise standards / constraints
          ↓
LOB standards / constraints
          ↓
Experience standards / constraints
          ↓
Architecture constraints
          ↓
Repository-local constraints
```

An agent working on a Repository should be able to discover the effective constraints that apply to it without every parent constraint being duplicated into the Repository page.

A **Decision** is different from a Constraint. A Constraint answers "what must I obey?" A Decision or ADR answers "why was this chosen?"

The Wiki should generally reference the authoritative ADR or decision record when deeper rationale is needed rather than reimplementing an ADR system.

### 7.7 Plan / Change

Represents a proposed change to current reality.

A Plan is first-class knowledge rather than a long-lived Git branch.

It references current-state Wiki entities and describes a possible future state without mutating current truth. A short-lived Git feature branch may be used behind the scenes while someone is editing a Plan, but the branch is an authoring mechanism and is not the identity of the Plan.

---

## 8. Enterprise Discovery vs. Progressive Disclosure

The target state preserves OKF agentic navigation as the default understanding mechanism.

However, at enterprise scale an agent may not know where to begin.

Therefore the system may provide a lightweight **enterprise discovery capability** whose job is only:

> Find the best starting points.

Example:

```text
query: "NSF rate ACH return"
```

Possible result:

```text
Likely starting points:
- metrics/nsf-rate
- architectures/ach-return-processing
- schemas/returned-payment
- experiences/deposit-servicing
```

After discovery, the agent returns to normal OKF navigation:

```text
discovery
    ↓
candidate OKF node
    ↓
index.md
    ↓
agentic progressive disclosure
    ↓
source if needed
```

The target state intentionally does **not** require a large set of graph-specific tools such as `neighbors()`, `trace()`, or `getEntity()` unless experience demonstrates that they provide measurable value.

### Open decision

The discovery implementation is not yet selected.

Candidates include:

- generated cross-cutting OKF indexes,
- lexical search,
- semantic search,
- hybrid search,
- graph-aware ranking,
- or combinations of these.

The agent should not need to understand which retrieval mechanism is used.

---

## 9. Plans and Future State

### 9.1 Plans are knowledge, not branches

A proposed future architecture should not require a long-lived Git branch.

Example:

```text
Current:
Service A → Kafka Event X → Service B

Proposed Plan:
Service A → Account API → Service B
```

The Plan explicitly represents:

```text
REMOVE Service A → Kafka Event X
ADD    Service A → Account API
ADD    Account API → Service B
```

Multiple Plans can coexist against the same current state.

### 9.2 Plans overlay current knowledge

A consumer should be able to reason about different world views:

```text
Current state

Current state + Plan A

Current state + Plan B
```

Current truth remains unchanged until implementation has actually occurred and the canonical Wiki is reconciled.

### 9.3 Plan lifecycle

A useful lifecycle is:

```text
Conversation
      ↓
Personal Draft
      ↓
Shared Preview / Draft
      ↓
Published Proposed Plan
      ↓
Approved
      ↓
In Progress
      ↓
Implemented
      ↓
Historical
```

Not every thought should immediately become enterprise knowledge. Normal exploration remains ephemeral until the user decides it is worth persisting.

The key transition is:

> **Conversation → Persistence**

not:

> Read Mode → Write Mode

### 9.4 Creating a Plan from a Wiki conversation

A user may begin by simply exploring the Wiki:

```text
wiki
  ↓
conversation about current state
  ↓
research / questions / what-if reasoning
  ↓
"I like this — save it as a Plan"
```

At that moment, the system should lazily materialize the writable Git authoring workspace and capture the emerging Plan while keeping the same Claude conversation alive.

The user should not have to exit the conversation, change directories, clone the Wiki, or restart the agent.

### 9.5 Sharing a draft Plan without exposing Git

When a user chooses to share a draft Plan, the authoring plane may:

```text
commit
  ↓
push feature branch
  ↓
open Draft PR
  ↓
publish preview OKF bundle
```

The preview bundle should be served through the same S3 / CloudFront distribution model as canonical Wiki knowledge, but under a preview namespace or equivalent isolation.

Teammates therefore consume the Plan through the serving plane rather than fetching the author's Git branch.

```text
Writer
Claude → hidden Git workspace → branch / PR → preview publish

Reader
preview S3 bundle → local cache → Claude
```

The **Plan Consumer understands a knowledge overlay**, not a Git branch.

### 9.6 Discovering Plans by person or team

The primary Plan UX should not require teammates to exchange a new Plan ID every time a Plan is created.

The preferred interaction is owner/team oriented:

```text
wiki --plan <enterprise-id-or-team-name>
```

Examples conceptually include:

```text
wiki --plan <my-enterprise-id>
wiki --plan <my-team>
```

This should make the relevant Plans owned, authored, or shared by that person/team discoverable in the session. Team/person identity is therefore a collaboration and discovery dimension; it does not replace the Plan's stable internal identity.

If multiple Plans exist, the system should present or index those Plans for agentic discovery rather than blindly applying every future-state overlay simultaneously. Once the conversation focuses on a specific Plan, the Plan Consumer can combine that Plan with its current-state baseline.

A Plan ID may still exist as a stable internal identifier and as a secondary precision path, for example:

```text
wiki --plan-id <plan-id>
```

but normal collaboration should revolve around **people and teams**, not requiring users to memorize or communicate opaque IDs.

### 9.7 Publishing knowledge is distinct from approving the proposed change

Merging a Wiki PR means:

> This Plan is valid durable knowledge that the organization wants to retain and share.

It does **not** necessarily mean:

> This proposed architecture or product change has been approved for implementation.

The Git PR lifecycle controls knowledge publication. The Plan lifecycle controls proposal status.

A Plan can therefore be merged into the canonical Wiki while still carrying:

```yaml
status: proposed
```

and later evolve through `approved`, `in-progress`, `implemented`, or `historical`.

### 9.8 Baseline revision and consistency

The Plan should record which published Wiki revision informed the conversation that created it.

Example:

```yaml
baseline_wiki_revision: <revision>
```

If canonical Wiki knowledge advances before the draft is persisted or published, the authoring harness should detect whether entities referenced by the Plan materially changed.

If nothing relevant changed, authoring can continue normally. If important baseline context changed, the agent should reconcile the new evidence before finalizing the Plan.

### 9.9 Plans should be general, not over-taxonomized

The system should avoid separate hard-coded types such as:

- Product Plan,
- Technology Plan,
- Modernization Plan,
- Metric Plan,
- etc.

Instead, a Plan represents a general **Change Intent**:

```text
CURRENT STATE
      │
      │ Change Intent
      ▼
PROPOSED STATE
```

A change may begin from:

- a Metric,
- Architecture,
- Repository,
- Business Process,
- Risk,
- Control,
- Cost,
- Customer Experience,
- Incident,
- Technology concern,
- Regulation,
- or something not anticipated in advance.

### 9.10 Plan Guides

Plan Guides are reasoning playbooks, not rigid templates.

Examples:

- Improve a Metric
- Modernize Technology
- Migrate a System
- Reduce Operational Risk
- Respond to Regulation
- Improve Customer Experience

A Metric-oriented guide might reason:

```text
Metric
  ↓
Business processes influencing it
  ↓
Architectures implementing those processes
  ↓
Repositories / schemas involved
  ↓
Controllable levers
  ↓
Potential changes
```

A modernization guide might reason:

```text
Repository / Architecture
  ↓
Current responsibilities
  ↓
Inputs / outputs
  ↓
Consumers
  ↓
Constraints
  ↓
Operational problems
  ↓
Possible future topology
  ↓
Business / metric impact
```

If no existing guide fits, the agent should still be able to create a Plan.

### 9.11 Minimal common Plan structure

The universal Plan model should remain intentionally small:

- Objective
- Why change?
- Current-state anchors
- Desired outcomes
- Proposed changes
- Constraints
- Assumptions
- Impacted entities
- Expected metric / outcome effects
- Open questions
- Decisions
- Evidence

Additional content may remain free-form.

---

## 10. Consumers

A **Consumer** is a way of presenting or navigating the same underlying knowledge for a particular task or audience.

Consumers do not create separate truths.

### 10.1 Default Consumer: conversational exploration

The default experience should be an organic conversation grounded in the Wiki.

The system should **not** begin by forcing the user to select a mode such as "learn", "plan", or "architecture". A conversation may naturally evolve from learning into diagnosis, planning, or design.

The default behavior should be approximately:

> Converse naturally. Ground reasoning in the Wiki. Progressively disclose context as necessary. Inspect authoritative source when greater detail is required. Allow the user's intent to emerge organically.

A `/hey-wiki` skill can encode this conversational behavior, but when the `wiki` CLI launches an agent specifically for the second-brain experience, that behavior should ideally be activated automatically rather than requiring an extra command from the user.

### 10.2 Specialized Consumers are lenses, not mandatory modes

Examples may include:

- Developer Consumer,
- Product Consumer,
- Architecture Consumer,
- Metric Consumer,
- Plan Consumer,
- Incident Consumer.

A Product-oriented Consumer may begin from:

```text
Metric
  ↓
Business Process
  ↓
Architecture
  ↓
Repositories / Schemas
```

A Developer-oriented Consumer may begin from:

```text
Repository
  ↓
Architecture
  ↓
Schemas / Dependencies
  ↓
Source
```

A Plan Consumer may combine current entities with a proposed Plan and render a future-state view.

These Consumers may be invoked when useful, but the user should not have to classify the conversation before beginning. Consumers may be textual, visual, or both.

---

## 11. Visualization

Visualization is valuable when understanding architecture, impact, or future state.

### Default

**Mermaid** is the preferred default for inline diagrams because it is:

- Markdown-friendly,
- text-based,
- versionable,
- diffable,
- agent-readable,
- easy for LLMs to generate,
- and broadly renderable.

However:

> Mermaid is a rendering format, not the underlying architecture model.

Relationships should remain represented semantically in Wiki knowledge so that different Consumers can render them differently.

### Alternatives to retain

For richer use cases, the system may later consider:

- **D2** for declarative architecture diagrams and automatic layout,
- **Structurizr / C4-style modeling** for more formal architecture views,
- or a custom graph / interactive UI Consumer.

The choice of renderer must not require changing canonical Wiki knowledge.

---

## 12. Ingestion

Repository ingestion should do more than summarize a repository.

It should progressively discover relationships.

Example:

```text
ingest Repository A
        ↓
discover Kafka topic
        ↓
query schema registry
        ↓
identify schema
        ↓
identify known producers / consumers
        ↓
discover Repository B and C relationships
        ↓
suggest Wiki relationships
        ↓
potentially suggest an Architecture
```

The ingestion system should search for:

- inputs,
- outputs,
- behavior-driving fields,
- schemas,
- upstream and downstream systems,
- important transformations,
- business intent,
- supported processes,
- and existing Wiki concepts that should be linked.

The output is a **proposed knowledge change**, not an automatic replacement of current Wiki content.

---

## 13. Continuous Reconciliation and Maintenance

Source systems can emit events when relevant things change.

Examples:

- repository changes,
- schema changes,
- registry changes,
- metric definition changes,
- ownership changes,
- or other authoritative-source updates.

The desired maintenance pipeline is:

```text
Source Event
     ↓
Affected knowledge discovery
     ↓
Gather diff / evidence
     ↓
Semantic significance judgment
     ↓
Proposed Wiki change
     ↓
Review / decision
```

The significance question is:

> Did something change that would alter the mental model a competent agent should have about this entity?

Examples:

- private method rename → ignore,
- internal refactor with unchanged semantics → usually ignore,
- new meaningful input/output → likely update,
- behavior-driving field changes meaning → update,
- producer / consumer topology changes → update,
- system-of-record changes → strongly update.

---

## 14. Human-Governed Learning and Increasing Autonomy

The target state should not immediately allow AI to autonomously rewrite and merge enterprise knowledge.

Human review is initially required because the system first needs examples of organizational judgment.

### Stage 1 — Human governed

```text
AI proposes
Human reviews
Human merges
```

Capture:

- accepted changes,
- rejected changes,
- edits,
- review comments,
- source diff,
- Wiki diff,
- supporting evidence,
- and rationale.

### Stage 2 — AI-assisted review

```text
AI proposes
AI pre-reviews against learned examples
Human approves / merges
```

### Stage 3 — Risk-based autonomy

```text
AI proposes
AI evaluates using evidence + learned precedent
       ↙                         ↘
low-risk / high-confidence     ambiguous / high-risk
auto-merge                    human review
```

Human review history becomes **episodic long-term memory** that teaches the system:

- what belongs in Wiki vs. source,
- what level of abstraction is useful,
- which changes are semantically significant,
- what evidence is sufficient,
- and what the organization considers a high-quality Wiki update.

This creates a governance flywheel rather than relying on a perfectly specified judge from day one.

---

## 15. Trust, Freshness, and Provenance

At enterprise scale, stale context can be more dangerous than missing context.

Entities should therefore support metadata such as:

- owner,
- authoritative source,
- evidence,
- last verified,
- Wiki revision,
- current / proposed / deprecated status,
- effective date where relevant,
- and confidence when knowledge is inferred rather than explicitly declared.

Consumers should be able to distinguish:

```text
Verified against source 3 days ago
```

from:

```text
Not reconciled against source in 180 days
```

Agents can then decide whether to trust the summary or inspect source.

---

## 16. Security and Permissions

The serving plane must preserve source permissions.

Security cannot rely only on the fact that the canonical Git repository is restricted.

Derived systems must not expose unauthorized:

- repository names,
- schema names,
- architecture relationships,
- Plan contents,
- metadata,
- search results,
- or even the existence of restricted concepts where that itself is sensitive.

Search, generated indexes, caches, graph views, and Consumers must all be **security trimmed**.

---

## 17. Seamless Enterprise Consumption

Seamless consumption is a target-state requirement.

### 17.1 One primary entry point

The default UX should be a single command:

```text
wiki
```

The CLI resolves the user's default second brain, refreshes the published read-only cache when necessary, and launches Claude Code or another supported agent with the Wiki context available.

A first-run experience may ask the user which Wiki should be their default. After that, the default should be remembered rather than repeatedly confirmed.

The session may show non-blocking context such as:

```text
Second Brain: <default Wiki>
Revision: <published revision>
```

Users may still explicitly select a different Wiki when necessary, but correct defaults should minimize ceremony.

### 17.2 Organic conversation before workflow selection

The Wiki experience should not ask users up front whether they are trying to learn, plan a feature, modernize technology, diagnose an issue, or perform another workflow.

A natural conversation may evolve like:

```text
Why is this metric changing?
        ↓
Which architecture influences it?
        ↓
What constrains us today?
        ↓
What if we replaced this stream with an API?
        ↓
This is promising — save it as a Plan.
```

The system should support that progression without forcing the user to predict the destination of the conversation.

### 17.3 Read and write backing stores are separate; the conversation is continuous

A Wiki session conceptually has two possible workspaces:

```text
READ WORKSPACE
local cache of published S3 / CloudFront OKF
read-only

AUTHORING WORKSPACE
lazy Git checkout / worktree / branch
writable
```

The authoring workspace does not need to exist until the user wants to persist something.

When the user crosses that boundary, the same conversational session continues while the infrastructure creates the writable workspace underneath it.

### 17.4 Plan collaboration by person or team

Plan discovery should be optimized for how people naturally collaborate.

Preferred:

```text
wiki --plan <enterprise-id-or-team-name>
```

This makes the Plans associated with that person or team available for discovery in the Wiki session.

A precise Plan ID remains useful for deep links, automation, and unambiguous lookup, but is a secondary UX:

```text
wiki --plan-id <plan-id>
```

A team/person lookup should surface the relevant Plan collection. The agent then chooses the relevant Plan based on the conversation rather than automatically composing every Plan into one future-state view.

### 17.5 End-to-end UX

```text
                       USER
                        │
                      `wiki`
                        │
                        ↓
              Resolve default brain
                        │
                        ↓
              Refresh published cache
                        │
                        ↓
               Local read-only OKF
                        │
                        ↓
                   Claude Code
                        │
                conversational Wiki
                        │
             ┌──────────┴──────────┐
             │                     │
        keep exploring       "save this"
             │                     │
             │                     ↓
             │              PROMOTE KNOWLEDGE
             │                     │
             │               lazy Git workspace
             │                     │
             │                continue editing
             │                     │
             │                   share
             │                     │
             │              push / Draft PR
             │                     │
             │              preview published
             │                     │
             │             teammates consume
             │              through serving plane
             │                     │
             └─────────────────────┘
```

This yields three primary states:

```text
Conversation
    = ephemeral thinking

Draft
    = durable authoring workspace

Published Knowledge
    = shared through the serving plane
```

with an optional intermediate state:

```text
Shared Preview
    = remote branch / Draft PR rendered through the serving plane
```

The architectural principle is:

> **Reads optimize for ubiquitous, fast, agent-native access. Writes optimize for governance, provenance, and collaboration. The user should not have to manage the transition between them.**

---

## 18. Closed-Loop Context Model

The long-term goal is a closed loop:

```text
             WIKI
              │
      ┌───────┴────────┐
      ↓                ↓
  Understand         Plan
 current state     future state
      │                │
      └───────┬────────┘
              ↓
            Intent
              ↓
       implementation
              ↓
           source
              ↓
      ingest / reconcile
              ↓
           WIKI
```

Over time, long-term memory can also capture the outcomes of prior changes:

- which assumptions were wrong,
- which modernization patterns worked,
- which plans affected metrics,
- which architectural decisions caused operational issues,
- and how human reviewers evaluated similar Wiki updates.

The Wiki therefore becomes more than documentation. It becomes a continuously improving context system for understanding, planning, implementation, and learning.

---

## 19. Explicit Non-Goals

The target state does **not** aim to:

- copy all source code into the Wiki,
- replace source inspection,
- make embeddings or vector search the primary truth,
- require a graph database as the canonical store,
- force agents to learn a large custom retrieval-tool surface,
- make Mermaid or any visualization syntax the canonical architecture model,
- represent proposed future state by silently changing current-state Wiki content,
- require users to manually clone or synchronize Wiki repositories,
- require users to classify a Wiki conversation as "learn" vs. "plan" before starting,
- require users to exchange opaque Plan IDs for normal person/team collaboration,
- or immediately allow autonomous AI merges without organizational training data.

---

## 20. Open Decisions

The following choices remain intentionally unresolved.

### 20.1 Enterprise discovery strategy

Determine how agents find the best starting point when they do not know the owning LOB or Experience.

Options to evaluate:

- generated cross-cutting OKF indexes,
- lexical search,
- semantic search,
- hybrid search,
- graph-aware ranking,
- or a combination.

The preferred solution should be selected empirically based on retrieval quality, latency, explainability, operational complexity, and agent performance.

### 20.2 Physical placement of Plans

Determine whether published Plans should live:

- inside each LOB / Experience Wiki,
- in a separate enterprise Plan knowledge space,
- or through a hybrid model where the Plan has a canonical home but references entities across Wiki boundaries.

The logical Plan model is independent of this storage choice.

### 20.3 Shared-preview retention and collaboration behavior

The initial direction is to use a lazy Git authoring workspace plus a Draft PR / branch and publish a preview OKF bundle through the serving plane.

Still determine:

- how long abandoned previews are retained,
- who may discover another person's drafts,
- how team ownership and sharing are represented,
- whether teammates can directly co-author the same draft or contribute through review,
- and how preview cleanup works after merge or abandonment.

### 20.4 Serving-plane sync details

The preferred initial architecture is GitHub → publish pipeline → S3 → CloudFront → local read-only cache.

Still determine:

- manifest format,
- cache invalidation / refresh semantics,
- incremental download behavior,
- local cache location and lifecycle,
- offline behavior,
- how multiple authorized Wikis are cached,
- and how preview bundles are resolved alongside canonical bundles.

### 20.5 Minimum entity contracts

Define the required fields and validation rules for:

- Repository,
- Schema,
- Architecture,
- Metric,
- Business Process,
- Plan,
- and reusable cross-cutting Standard / Constraint where needed.

This should be done carefully to preserve enough structure for reliable navigation while avoiding a rigid documentation bureaucracy.

---

## 21. Target-State Summary

The target-state LLM Wiki is:

> **A Git-governed, OKF-based, progressively disclosed semantic map of the enterprise that helps agents understand current state, verify against authoritative source, connect technology to business outcomes, reason about proposed future states, and continuously improve through source reconciliation and human-reviewed learning.**

Its core separation of concerns is:

```text
Git / OKF
    =
canonical durable knowledge

Serving Plane
    =
versioned OKF publication through S3 / CloudFront and a fast local read-only cache

Agentic Search + Progressive Disclosure
    =
primary understanding model

Enterprise Discovery
    =
optional acceleration to the correct starting point

Source
    =
detailed authoritative implementation truth

Plans
    =
first-class proposed future-state overlays, authored through lazy Git workspaces and shared through serving-plane previews

Consumers
    =
task- and audience-specific views of the same knowledge

Human Review + Long-Term Memory
    =
path from governed maintenance toward safe autonomy
```
