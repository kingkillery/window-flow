# Demo: What happens with PK_REACT "yeah go for it"
$userPrompt = "yeah go for it"

Write-Host "=== YOUR PROMPT: PK_REACT 'yeah go for it' ===" -ForegroundColor Cyan
Write-Host "Original prompt: '$userPrompt'" -ForegroundColor Yellow
Write-Host ""

Write-Host "ReAct Analysis Process:" -ForegroundColor Green

# Thought Phase
Write-Host "THOUGHT 1: Analyzing the vagueness..." -ForegroundColor Gray
Write-Host "- Problem: Extremely vague, lacks context, purpose, and action"
Write-Host "- Missing: What should I go for? What's the task/goal?"
Write-Host "- Quality gaps: No direction, no constraints, no output format"
Write-Host ""

# Action Phase
Write-Host "ACTION 1: Clarification and context building..." -ForegroundColor Gray
Write-Host "- Language precision: Replace vagueness with specific action items"
Write-Host "- Context enrichment: Add scenarios where this phrase might be used"
Write-Host "- Output specification: Define what "going for it" means"
Write-Host ""

# Observation Phase
Write-Host "OBSERVATION 1: Evaluating improvements..." -ForegroundColor Gray
Write-Host "- Clarity: High - specific actions and contexts defined"
Write-Host "- Completeness: Medium - could add more domain-specific examples"
Write-Host "- Actionability: High - clear guidance for response generation"
Write-Host ""

Write-Host "THOUGHT 2: Adding flexibility and user guidance..." -ForegroundColor Gray
Write-Host "- Need to handle multiple possible interpretations"
Write-Host "- Should provide options for common scenarios"
Write-Host ""

Write-Host "ACTION 2: Creating adaptive response framework..." -ForegroundColor Gray
Write-Host "- Adding clarification questions to guide user"
Write-Host "- Providing templates for common use cases"
Write-Host "- Including fallback options for unclear contexts"
Write-Host ""

Write-Host "OBSERVATION 2: Final quality assessment..." -ForegroundColor Gray
Write-Host "- Clarity: Excellent - handles ambiguity gracefully"
Write-Host "- Completeness: Excellent - covers multiple scenarios"
Write-Host "- Actionability: Excellent - provides clear next steps"
Write-Host ""
Write-Host "TERMINATION CRITERIA MET - Optimization complete!" -ForegroundColor Green
Write-Host ""

Write-Host "=== OPTIMIZED PROMPT ===" -ForegroundColor Magenta
Write-Host @"
Adaptive Response System for Unclear User Intent

When user responds with vague affirmation like "yeah go for it" or similar phrases:

PRIMARY RESPONSE STRATEGY:
1. Acknowledge the affirmation positively
2. Clarify the specific action or task being confirmed
3. Propose concrete next steps or execution options

CLARIFICATION PROTOCOL:
- Identify the most recent context or task being discussed
- Ask specific questions to narrow down scope:
  * "What specifically would you like me to proceed with?"
  * "Should I [specific action 1] or [specific action 2]?"
  * "What's your preferred format/approach for this?"

COMMON SCENARIOS & RESPONSES:

Scenario A: Task Confirmation
User said "yeah go for it" after I proposed a task
Response: "Great! I'll [specific task description]. Would you like me to:
• Start immediately with [approach 1]
• Wait for your specific preferences
• Show you the plan first?"

Scenario B: Idea/Approach Confirmation
User confirmed my suggestion or idea
Response: "Excellent choice! Let me [implement the confirmed idea].
I'll focus on: [key aspects]. Any specific preferences or modifications?"

Scenario C: Generic Enthusiasm
User responded positively but context is unclear
Response: "I'm ready to help! What would you like me to work on?
I can assist with:
• [relevant capability 1]
• [relevant capability 2]
• [other options based on conversation history]"

FALLBACK RESPONSE (if no context available):
"I'm excited to help! To give you the best results, could you tell me:
1. What specific task or project you'd like me to work on
2. Any particular requirements or preferences you have
3. Your desired timeline or next steps"

EXECUTION GUIDELINES:
- Always maintain positive, proactive tone
- Provide clear, actionable options
- Wait for user confirmation before proceeding with major actions
- Keep responses concise but comprehensive
- Focus on moving the conversation/productive work forward

ADAPTATION RULES:
- Adjust complexity based on user's previous interaction level
- Match enthusiasm level while maintaining clarity
- Include 2-3 specific options rather than open-ended questions
- Reference previous conversation context when available

OUTPUT: Acknowledge, clarify, propose next steps, and await user direction.
"@

Write-Host ""
Write-Host "🔥 REACT TRANSFORMATION COMPLETE 🔥" -ForegroundColor Yellow
Write-Host "From: 'yeah go for it' (3 vague words)" -ForegroundColor Red
Write-Host "To: Comprehensive adaptive response system (20+ detailed guidelines)" -ForegroundColor Green
Write-Host ""
Write-Host "Your prompt will now handle any unclear context gracefully!" -ForegroundColor Cyan