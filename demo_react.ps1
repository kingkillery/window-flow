# Demo ReAct optimization for the song prompt
$userPrompt = "Write me a full song"

Write-Host "=== PROMPTOPT REACT MODE DEMO ===" -ForegroundColor Cyan
Write-Host "Original Prompt: '$userPrompt'" -ForegroundColor Yellow
Write-Host ""
Write-Host "ReAct Optimization Process:" -ForegroundColor Green

# Thought Phase
Write-Host "THOUGHT 1: Analyzing prompt..." -ForegroundColor Gray
Write-Host "- Problem: Prompt lacks specificity, context, and constraints"
Write-Host "- Missing: Genre, mood, structure requirements, length, theme"
Write-Host "- Quality gaps: No guidance on style, audience, or purpose"
Write-Host ""

# Action Phase
Write-Host "ACTION 1: Applying optimization techniques..." -ForegroundColor Gray
Write-Host "- Language precision: Adding specific constraints and requirements"
Write-Host "- Context enrichment: Defining musical elements and structure"
Write-Host "- Output specification: Defining exact format and sections"
Write-Host ""

# Observation Phase
Write-Host "OBSERVATION 1: Evaluating improvements..." -ForegroundColor Gray
Write-Host "- Clarity: High - specific genre and structure defined"
Write-Host "- Completeness: Medium - could add more emotional context"
Write-Host "- Actionability: High - clear requirements for songwriter"
Write-Host ""

# Additional refinement
Write-Host "THOUGHT 2: Further refinement..." -ForegroundColor Gray
Write-Host "- Could enhance with emotional depth and storytelling elements"
Write-Host "- Consider target audience and performance context"
Write-Host ""

Write-Host "ACTION 2: Adding emotional and narrative layers..." -ForegroundColor Gray
Write-Host "- Adding theme exploration and emotional journey"
Write-Host "- Defining narrative arc and character development"
Write-Host ""

Write-Host "OBSERVATION 2: Final quality assessment..." -ForegroundColor Gray
Write-Host "- Clarity: Excellent - all aspects clearly defined"
Write-Host "- Completeness: Excellent - covers musical, lyrical, and emotional elements"
Write-Host "- Actionability: Excellent - songwriter has complete guidance"
Write-Host ""
Write-Host "TERMINATION CRITERIA MET - Optimization complete!" -ForegroundColor Green
Write-Host ""

Write-Host "=== OPTIMIZED PROMPT ===" -ForegroundColor Magenta
Write-Host @"
Comprehensive Song Creation System

Create a complete song with the following specifications:

MUSICAL ELEMENTS:
- Genre: Modern folk-pop with acoustic foundation
- Tempo: Mid-tempo (90-120 BPM)
- Structure: Verse-Chorus-Verse-Chorus-Bridge-Chorus-Outro
- Key: C Major (or relative minor for emotional contrast)
- Length: 3-4 minutes total

LYRICAL REQUIREMENTS:
- Theme: Personal growth and resilience after hardship
- Narrative arc: From struggle to empowerment to hope
- Emotional journey: Vulnerable → Confident → Triumphant
- Rhyme scheme: AABB for verses, ABCB for chorus
- Syllable count: 8-12 per line for singability

STRUCTURAL BREAKDOWN:
Verse 1: Establish the challenge/struggle (4-6 lines)
Chorus: Main message of resilience (4-6 lines, memorable hook)
Verse 2: Show progress and change (4-6 lines)
Chorus: Repeat with emphasis
Bridge: Perspective shift, big realization (4-6 lines)
Chorus: Final powerful delivery
Outro: Hopeful fade with key phrase

STYLE GUIDELINES:
- Use concrete imagery over abstract concepts
- Include at least one metaphor about nature/journey
- Vary line length for natural rhythm
- Incorporate both internal and external rhymes
- Build emotional intensity through repetition

OUTPUT FORMAT:
1. Title: [Compelling song title]
2. [Verse 1]
3. [Chorus]
4. [Verse 2]
5. [Chorus]
6. [Bridge]
7. [Chorus]
8. [Outro]
9. Brief: 2-3 sentence description of musical arrangement

Create authentic, emotionally resonant lyrics that tell a complete story of transformation.
"@

Write-Host ""
Write-Host "ReAct mode transformed: 'Write me a full song'" -ForegroundColor Yellow
Write-Host "Into a comprehensive song creation system with 10x more detail!" -ForegroundColor Green