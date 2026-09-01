# CLAUDE.md

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Serena Tools

**When the Serena MCP server is available, its symbol-aware tools are primary for code files. Read/Glob/Grep/Edit are secondary.**

Call `initial_instructions` before starting a coding task.

Before editing code:
1. `get_symbols_overview` on the target file (skip if already done this session).
2. `find_symbol` with `include_body=true` for only the symbols you'll touch, not the whole file.
3. Edit with `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`, or `replace_content`.

Built-in tools are still correct for:
- Non-code files: markdown, JSON, YAML, TOML, config, lockfiles, plain text, images.
- Regex search across many files as a discovery step - but read/edit the matched code files through Serena.
- Reading a few lines where a symbolic read is overkill.
- Anything Serena has already been tried on and failed, or files that don't parse as code.

Don't rationalize past this with "the file is small", "the path is known", or "one call versus three".
