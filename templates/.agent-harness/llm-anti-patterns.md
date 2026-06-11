# LLM Prompting Anti-Patterns & Hallucination Triggers

When building Agentic workflows or writing instructions for LLMs (like `CLAUDE.md` or `.worktree-task.md`), we often use intuitive human logic. However, LLMs are probabilistic predictors, not rule-following state machines. 

Below are the most common "Dark Patterns" and "Hallucination Triggers" in Agent prompting, and how to fix them using `wtcraft` governance.

## 1. The "Pink Elephant" Problem (Irony of Negation)
**The Trap:** Telling the model what *not* to do (e.g., "Do not use Korean", "Do not modify the database"). 
**Why it fails:** Negative instructions require the model to allocate attention to the prohibited concept. This actively anchors the forbidden token probabilities in the model's context window, paradoxically making it *more* likely to output the forbidden concept.
**The Fix:** Use **Exclusive Affirmative (肯定排他句)**. Instead of telling it what to avoid, give it a narrow, strict whitelist. Add catastrophic consequences to enforce the boundary.

*Bad:* `Do not output Japanese or Korean.`
*Good:* `CRITICAL: Output YOUR ENTIRE RESPONSE in Simplified Chinese or English ONLY. Any use of Hiragana, Katakana, or Hangul characters is strictly forbidden and will cause an immediate system failure.`

## 2. Sycophancy (Flattery & Agreement Bias)
**The Trap:** The model blindly agrees with the user's incorrect assumptions instead of correcting them. For example, if you say "I think the bug is in `auth.ts`, fix it," the model will modify `auth.ts` even if the bug is actually in `router.ts`.
**Why it fails:** LLMs are fine-tuned via RLHF (Reinforcement Learning from Human Feedback) to be "helpful" and pleasing to the user. Disagreeing is heavily penalized in their base training.
**The Fix:** Use a **Devil's Advocate / Objective Persona**.
*Fix:* In `.agent-harness/planner.md`, explicitly state: `You are an impartial verifier. You are rewarded for finding flaws in the user's hypothesis. Do NOT agree with the user unless the evidence explicitly supports it.`

## 3. Attention Collapse (Lost in the Middle)
**The Trap:** Giving an Agent a massive 2000-line prompt with instructions buried in the middle. The agent perfectly follows the first and last sentences but ignores the constraints in the middle.
**Why it fails:** Transformers exhibit a U-shaped attention curve. Tokens at the beginning and end of a context window have significantly higher retrieval accuracy than those in the middle.
**The Fix:** **Modular Handoffs**. This is exactly why `wtcraft` divides tasks into `Planner`, `Executor`, and `Verifier`. Never give one agent the full context; bounded worktrees force the context to remain small and highly relevant.

## 4. The "Chameleon" Effect (Contextual Drift)
**The Trap:** An Agent starts writing clean code, but after reading a messy legacy file, it starts writing messy, un-typed code.
**Why it fails:** LLMs are completion engines. If the immediate context is messy, the statistically most probable "next token" is also messy.
**The Fix:** **Formatting Checklists**. In the `## Verification` section of `.worktree-task.md`, enforce strict formatting checks (e.g., `npm run lint`). Do not rely on the LLM to "just know" how to write clean code; rely on `wtcraft check` and `wtcraft verify` to physically reject drifted code.
