# Suggested Features — VimQuest

Source: described idea (greenfield)
Last updated: 2026-08-14

All items below were accepted by the user in one batch. Tiers set the build order;
"Segment" maps each to the roadmap in README.md.

### F1 — Panic exit + sandbox guarantee
- Tier: Essential | Status: Accepted | Segment: S1 ✅
- What: Game lives in scratch buffers (`buftype=nofile`, `bufhidden=wipe`, no file writes); `<Esc><Esc>` always exits combat.
- Why: A real-time game inside your editor without a guaranteed escape hatch feels like a trap.

### F2 — Keystroke recorder
- Tier: Essential | Status: Accepted | Segment: S1 ✅ (capture) / S4 (consumers)
- What: Logs every key with a timestamp while the game runs.
- Why: Foundation for scoring, ghost replays and adaptive spawns.

### F3 — Pause / auto-pause
- Tier: Essential | Status: Accepted | Segment: S1 ✅
- What: `<F2>` toggles, `FocusLost` auto-pauses, ticks skip while another buffer is current.
- Why: Real-time damage must never continue while you are elsewhere.

### F4 — Versioned saves + migration
- Tier: Essential | Status: Accepted | Segment: S2
- What: JSON save with `schema_version`, upgraded by `save/migrate.lua`.
- Why: An update must never wipe progress.

### F5 — Zero-knowledge onboarding zone
- Tier: Essential | Status: Accepted | Segment: S1 ✅
- What: Zone 0 teaches cursor-as-player and `hjkl` before any threat appears.
- Why: The player is starting from no vim knowledge at all.

### F6 — Keystroke-golf scoring
- Tier: Important | Status: Accepted | Segment: S4
- What: Par keystroke count per encounter, 3 stars for optimal.
- Why: Turns "I survived" into "I solved it well" — the actual skill goal.

### F7 — Death replay + ghost
- Tier: Important | Status: Accepted | Segment: S4
- What: After dying, watch the optimal keystroke solution play back.
- Why: Fastest way to learn the counter to a mob type.

### F8 — Stamina economy punishing spam
- Tier: Important | Status: Accepted | Segment: S1 ✅ (core) / S2 (tuning)
- What: `hjkl` costs 2 stamina each; efficient motions cost 0.5. Empty stamina bleeds HP.
- Why: Structurally prevents the single worst vim habit.

### F9 — Spaced repetition on weak commands
- Tier: Important | Status: Accepted | Segment: S4
- What: SM-2-lite scheduling resurfaces fumbled commands as bounties.
- Why: Retention, not just exposure.

### F10 — Composition bosses
- Tier: Important | Status: Accepted | Segment: S3
- What: Bosses only die to count+operator+textobject combos (`2ci(`, `d2f;`).
- Why: Forces real fluency instead of single-key habits.

### F11 — Terminal capability detection
- Tier: Important | Status: Accepted | Segment: S6
- What: Probe truecolor/unicode/nerd-font, degrade gracefully.
- Why: Dev machine has Cascadia Code and no Nerd Font; other players vary.

### F12 — Headless test suite + CI
- Tier: Important | Status: Accepted | Segment: S6
- What: plenary specs + GitHub Actions.
- Why: Required before strangers install it.

### F13 — Real-file endgame zones
- Tier: Important | Status: Accepted | Segment: S5
- What: Final zones spawn mobs inside copies of actual code files.
- Why: Bridges game skills to real editing.

### F14 — Daily seeded challenge
- Tier: Nice-to-have | Status: Accepted | Segment: S6
- What: Deterministic daily dungeon with a shareable score string.
- Why: Classic pop-in retention hook.

### F15 — Achievements + titles
- Tier: Nice-to-have | Status: Accepted | Segment: S6
- What: "Dot Repeater", "Register Hoarder", etc.
- Why: Cheap, durable motivation.

### F16 — Runtime config-quest validation
- Tier: Nice-to-have | Status: Accepted | Segment: S5
- What: Validate that a mapping/option is actually live in Neovim, not that text exists in a file.
- Why: Uncheatable, and teaches how config truly applies.

### F17 — `:checkhealth vimquest`
- Tier: Nice-to-have | Status: Accepted | Segment: S6
- What: Standard Neovim diagnostics for installs.
- Why: Expected of any distributed plugin.

### F18 — Content authoring docs + zone schema
- Tier: Nice-to-have | Status: Accepted | Segment: S1 ✅ (CONTENT.md)
- What: Documented declarative zone format; engine untouched when adding content.
- Why: Makes the project easy to extend later, by you or by Claude Code.

### F19 — Async ghost racing
- Tier: Optional | Status: Accepted | Segment: post-S6
- What: Share a seed, compare keystroke counts with a friend.

### F20 — Telescope integration as in-world scrying
- Tier: Optional | Status: Accepted | Segment: post-S6
- What: Teaches fuzzy-finder workflow diegetically.

### F21 — LSP/quickfix endgame zone
- Tier: Optional | Status: Accepted | Segment: S5
- What: `gd`, `]d`, quickfix lists as late-game mechanics.

### F22 — Progress export
- Tier: Optional | Status: Accepted | Segment: S6
- What: Markdown skill report plus a personalised cheatsheet of weak keys.
