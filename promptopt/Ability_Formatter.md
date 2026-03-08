# Formatter Ability Prompts

## Concise
Strip to absolute essentials. Maximum information density. Output starts immediately.

RULES:
- Remove all filler words and redundancy
- One idea per line maximum
- No adjectives unless critical to meaning
- Abbreviate where unambiguous
- Target: 50% or less of original length

FORBIDDEN:
- "Here is…", "Below is…", "I've condensed…"
- Any preamble or postamble
- Explanations of what was removed
- Unnecessary punctuation

Output the condensed content now:

## Easy to Read
Reformat for maximum scannability. Output starts immediately with content.

RULES:
- Bullet points and short paragraphs only
- **Bold** key terms and constraints
- Whitespace separates distinct ideas
- Condense verbose blocks into concise points

FORBIDDEN:
- "Here is…", "Below is…", "I've reformatted…"
- Any preamble or postamble
- Explanations of what you did
- Sign-offs or summaries about the reformatting

Output the reformatted content now:

## Executive Summary
TL;DR first, then structured details. First line must be the summary.

STRUCTURE:
- **TL;DR:** One-sentence summary (mandatory first line)
- **Key Points:** 3-5 bullets of critical info
- **Details:** Expanded sections if needed
- **Action Items:** What to do next (if applicable)

FORBIDDEN:
- Any text before "TL;DR:"
- "Here is…", "Below is…"
- Preamble, postamble
- Burying the lead

Output the executive summary now:

## Q&A Format
Restructure as clear question-answer pairs. First character must be `Q`.

STRUCTURE:
- Q: [Clear, specific question]
- A: [Direct answer, then elaboration if needed]
- Group related Q&As under headers if many
- Most important/common questions first

FORBIDDEN:
- Any text before the first "Q:"
- "Here is…", "Below is…"
- Preamble, postamble
- Vague or rhetorical questions

Output the Q&A now:

## Decision Tree
Visualize branching logic as indented decision paths. Output starts immediately.

STRUCTURE:
- Start with the initial condition/question
- Use → for outcomes
- Indent nested decisions
- Format: `IF [condition] → [action/next decision]`
- Mark terminal states with ✓ or ✗

EXAMPLE:
```
IF user authenticated?
  → YES: IF has permission?
    → YES: ✓ Allow access
    → NO: ✗ Show 403 error
  → NO: → Redirect to login
```

FORBIDDEN:
- "Here is…", "Below is…"
- Preamble, postamble
- Prose explanations instead of tree structure

Output the decision tree now:

## Prose
Reformat as flowing, readable paragraphs. Output starts immediately.

RULES:
- Complete sentences in logical paragraphs
- Smooth transitions between ideas
- No bullet points or lists
- Professional but accessible tone
- Vary sentence length for rhythm

FORBIDDEN:
- "Here is…", "Below is…"
- Any preamble or postamble
- Bullet points or numbered lists
- Choppy, disconnected sentences

Output the prose now:

## Logic Breakdown
Reformat to expose core logic and relationships. Output starts immediately.

RULES:
- Step-by-step explanations for processes
- Simple examples to illustrate concepts
- Define technical terms inline
- Highlight cause→effect relationships
- Explicit conditions: "If X → Y"

FORBIDDEN:
- "Here is…", "Below is…", "I've reformatted…"
- Any preamble or postamble
- Meta-commentary about the reformatting

Output the reformatted content now:

## Teaching Mode
Reformat as if teaching a new teammate. Output starts immediately.

RULES:
- Ordered steps for processes
- Key terms called out clearly
- Short example for the main rule
- "Why" explanations for non-obvious rules
- Build from simple to complex

FORBIDDEN:
- "Here is…", "Let me explain…", "I'll walk you through…"
- Any preamble or postamble
- Meta-commentary
- Assuming prior knowledge

Output the reformatted content now:

## Checklist + Flow
Reformat for fast human execution. First character must be `#`.

STRUCTURE:
- `# [Title]`
- `## Prerequisites` (if any)
- `## Checklist` with `- [ ]` items
- `## Flow` with numbered steps and conditionals
- `## Rollback` (if applicable)

FORBIDDEN:
- Any text before the first `#`
- "Here is…", "Below is…"
- Preamble, postamble, code fences wrapping the output

Output the checklist+flow now:

## API Documentation
Reformat as API/endpoint documentation. First character must be `#`.

STRUCTURE:
- `# Endpoint Name`
- `## Method & Path` - GET/POST/etc + route
- `## Description` - What it does
- `## Parameters` - Table with name, type, required, description
- `## Request Body` - JSON schema if applicable
- `## Response` - Success and error responses
- `## Example` - curl or code snippet

FORBIDDEN:
- Any text before the first `#`
- "Here is…", "Below is…"
- Preamble, postamble
- Missing parameter types

Output the API documentation now:

## Test Cases
Reformat as structured test cases. First character must be `#`.

STRUCTURE:
- `# Test: [Name]`
- `## Given` - Initial state/preconditions
- `## When` - Action taken
- `## Then` - Expected outcome
- `## Edge Cases` - Boundary conditions to test

For multiple tests, repeat the structure with clear separation.

FORBIDDEN:
- Any text before the first `#`
- "Here is…", "Below is…"
- Preamble, postamble
- Vague assertions ("should work correctly")

Output the test cases now:

## Spec Document
Reformat as a crisp design/requirements spec. First character must be `#`.

STRUCTURE:
- `# Purpose` - what this spec covers
- `# Inputs` - parameters/data with types
- `# Rules` - numbered constraints
- `# Logic` - numbered procedure steps
- `# Edge Cases` - boundary conditions
- `# Example` - concrete illustration

FORBIDDEN:
- Any text before the first `#`
- "Here is…", "Below is…"
- Preamble, postamble, code fences wrapping the output

Output the spec now:

## LLM Instructions
Reformat as tightly scoped LLM system prompt. First character must be `#`.

STRUCTURE:
- `# Role` - what the model is
- `# Objective` - primary goal
- `# Input Format` - expected inputs
- `# Output Format` - expected outputs
- `# Rules` - behavioral constraints
- `# Examples` - input/output pairs

FORBIDDEN:
- Any text before the first `#`
- "Here is…", "Below is…"
- Preamble, postamble, code fences wrapping the entire output
- Vague instructions

Output the instruction blocks now:

## Pseudocode
Reformat as logic map with pseudocode. First character must be `#`.

STRUCTURE:
- `# [Topic]`
- `## Inputs` - what goes in
- `## Logic` - pseudocode block
- `## Output` - what comes out

Use clear pseudocode conventions:
- IF/ELSE, FOR/WHILE, RETURN
- Indent for nesting
- Comments with //

FORBIDDEN:
- Any text before the first `#`
- "Here is…", "Below is…"
- Preamble, postamble
- Actual programming language syntax

Output the pseudocode now:

## YAML Playbook
Reformat as YAML ops runbook. First character must be `p` (playbook:).

STRUCTURE:
```
playbook:
  name: [descriptive name]
  goal: [what this achieves]

prechecks:
  - [condition to verify before starting]

steps:
  - step: [description]
    command: [action to take]
    on_failure: [what to do if fails]

postchecks:
  - [condition to verify after completion]

rollback:
  description: [when/why to rollback]
  steps:
    - [rollback action]
```

FORBIDDEN:
- Any text before `playbook:`
- "Here is…", "Below is…"
- Preamble, postamble
- Code fences (```yaml) wrapping the output

Output raw YAML now:

## XML Structured
Reformat as structured XML. First character must be `<`.

STRUCTURE:
```
<document>
  <summary>...</summary>
  <sections>
    <section title="...">
      <content>...</content>
    </section>
  </sections>
  <metadata>
    <created>...</created>
    <tags>...</tags>
  </metadata>
</document>
```

FORBIDDEN:
- Any text before `<`
- "Here is…", "Below is…"
- Preamble, postamble
- Code fences (```xml) wrapping the output

Output raw XML now:

## JSON Contract
Reformat as machine-consumable JSON. First character must be `{`.

STRUCTURE:
```
{
  "title": "...",
  "description": "...",
  "inputs": {
    "param": {"type": "string", "required": true, "description": "..."}
  },
  "logic": [
    {"if": "condition", "then": "action"}
  ],
  "outputs": ["..."],
  "constraints": ["..."]
}
```

FORBIDDEN:
- Any text before `{`
- "Here is…", "Below is…"
- Preamble, postamble
- Code fences (```json) wrapping the output
- Invalid JSON syntax

Output raw JSON now:

## Tagged DSL
Reformat as tag-based instruction DSL. First character must be `<`.

STRUCTURE:
```
<INSTRUCTIONS>
  <GOAL>...</GOAL>
  <CONTEXT>...</CONTEXT>
  <RULES>
    - rule1
    - rule2
  </RULES>
  <EXAMPLES>
    <EXAMPLE>
      <INPUT>...</INPUT>
      <OUTPUT>...</OUTPUT>
    </EXAMPLE>
  </EXAMPLES>
  <CONSTRAINTS>...</CONSTRAINTS>
</INSTRUCTIONS>
```

FORBIDDEN:
- Any text before `<INSTRUCTIONS>`
- "Here is…", "Below is…"
- Preamble, postamble
- Code fences wrapping the output

Output raw tagged content now:

## Mermaid Diagram
Reformat as Mermaid diagram syntax. First line must be diagram type.

SUPPORTED TYPES:
- `flowchart TD` - top-down flowchart
- `sequenceDiagram` - interaction sequence
- `stateDiagram-v2` - state machine
- `erDiagram` - entity relationship

RULES:
- Choose most appropriate diagram type
- Use clear, short node labels
- Show all relationships/transitions
- Add notes for complex logic

FORBIDDEN:
- Any text before diagram declaration
- "Here is…", "Below is…"
- Preamble, postamble
- Code fences (```mermaid) wrapping the output

Output raw Mermaid syntax now:

## Table Format
Reformat as clean markdown tables. First character must be `|`.

RULES:
- Use tables for structured/comparative data
- Clear, concise column headers
- Align columns appropriately
- One table per logical grouping
- Add brief headers above tables if multiple

FORBIDDEN:
- Any text before the first `|`
- "Here is…", "Below is…"
- Preamble, postamble
- Inconsistent column counts

Output the table(s) now:

## Changelog
Reformat as a changelog/release notes. First character must be `#`.

STRUCTURE:
- `# Changelog` or `# [Version]`
- `## Added` - new features
- `## Changed` - modifications
- `## Fixed` - bug fixes
- `## Removed` - removed features
- `## Security` - security patches (if any)

RULES:
- Most recent changes first
- One line per change
- Start each line with action verb

FORBIDDEN:
- Any text before the first `#`
- "Here is…", "Below is…"
- Preamble, postamble
- Vague descriptions ("various fixes")

Output the changelog now:
