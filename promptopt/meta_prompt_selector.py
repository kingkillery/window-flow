#!/usr/bin/env python3
"""
Meta-Prompt Selector for PromptOpt
Intelligently selects the best meta-prompt template based on input text analysis.
"""
import os
import re
import json
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, asdict


@dataclass
class MetaPrompt:
    id: str
    name: str
    description: str
    keywords: List[str]
    patterns: List[str]  # Regex patterns for domain detection
    file_path: str
    category: str
    mode: str  # 'meta' or 'edit'
    weight: float = 1.0  # Importance weight for this meta-prompt
    
    def score_keywords(self, text: str) -> float:
        """Score based on keyword matches with weighted importance."""
        text_lower = text.lower()
        matches = 0
        total_weight = 0
        
        for kw in self.keywords:
            kw_lower = kw.lower()
            # Count occurrences (more occurrences = stronger signal)
            count = text_lower.count(kw_lower)
            if count > 0:
                # Weight by keyword length (longer = more specific)
                kw_weight = len(kw.split()) * (1 + count * 0.3)
                matches += kw_weight
                total_weight += kw_weight
        
        if total_weight == 0:
            return 0.0
        
        # Normalize by text length to avoid bias
        word_count = len(text.split())
        if word_count == 0:
            return 0.0
        
        # Normalize: more matches relative to text length = higher score
        normalized = min(matches / max(word_count / 5, 1), 1.0)
        return normalized * self.weight
    
    def score_patterns(self, text: str) -> float:
        """Score based on domain-specific regex patterns."""
        score = 0.0
        text_lower = text.lower()
        max_pattern_score = 0.0
        
        for pattern in self.patterns:
            matches = len(re.findall(pattern, text, re.IGNORECASE | re.MULTILINE))
            if matches > 0:
                # Pattern matches are strong signals
                pattern_score = min(matches * 0.2, 0.4)  # Cap per pattern
                max_pattern_score = max(max_pattern_score, pattern_score)
        
        return max_pattern_score
    
    def score_structure(self, text: str) -> float:
        """Score based on structural elements (code blocks, URLs, etc.)."""
        score = 0.0
        text_lower = text.lower()
        
        # Code block detection
        if self.category == 'coding':
            code_blocks = len(re.findall(r'```[\s\S]*?```', text))
            code_tags = len(re.findall(r'<code>[\s\S]*?</code>', text, re.IGNORECASE))
            if code_blocks > 0 or code_tags > 0:
                score += 0.5
        
        # URL/web detection
        if self.category == 'browser':
            urls = len(re.findall(r'https?://[^\s]+', text))
            if urls > 0:
                score += 0.5  # Strong signal for browser operations
        
        # Edit mode detection
        if self.mode == 'edit':
            edit_indicators = [
                r'\b(rewrite|refactor|polish|revise|clean up|improve|fix|correct|modify|update)\b',
                r'\b(make|make it).*\b(more|better|clearer|professional|formal|casual)',
                r'\b(before|after|original|current|existing)\b',
            ]
            for pattern in edit_indicators:
                if re.search(pattern, text_lower):
                    score += 0.4  # Strong signal for edit mode
                    break
        
        # RAG/context detection
        if self.category == 'rag':
            rag_indicators = [
                r'\b(context|retrieve|search|document|chunk|embedding|vector|knowledge base|source)\b',
                r'{{.*?}}',  # Template placeholders
            ]
            for pattern in rag_indicators:
                if re.search(pattern, text_lower):
                    score += 0.3
                    break
        
        return min(score, 1.0)
    
    def score(self, text: str) -> float:
        """Combined scoring with weighted components."""
        if not text or not text.strip():
            return 0.0
        
        keyword_score = self.score_keywords(text) * 0.5
        pattern_score = self.score_patterns(text) * 0.3
        structure_score = self.score_structure(text) * 0.2
        
        total = keyword_score + pattern_score + structure_score
        
        # Boost score if multiple signals align
        signal_count = sum(1 for s in [keyword_score, pattern_score, structure_score] if s > 0.1)
        if signal_count >= 2:
            total *= 1.2  # 20% boost for multiple signals
        
        return min(total, 1.0)


class MetaPromptSelector:
    def __init__(self, meta_prompt_dir: str, config: Optional[Dict] = None):
        self.meta_prompt_dir = Path(meta_prompt_dir)
        self.meta_prompts: List[MetaPrompt] = []
        
        # Default configuration
        self.confidence_threshold = 0.65
        self.auto_detect_enabled = True
        self.show_scores_in_menu = True
        self.fallback_id = "general-meta"
        self.min_text_length = 10
        
        if config:
            self.confidence_threshold = config.get('confidence_threshold', 0.65)
            self.auto_detect_enabled = config.get('auto_detect_enabled', True)
            self.show_scores_in_menu = config.get('show_scores_in_menu', True)
            self.fallback_id = config.get('fallback_metaprompt', 'general-meta')
            self.min_text_length = config.get('min_text_length', 10)
        
        self.load_meta_prompts()
    
    def load_meta_prompts(self):
        """Load meta-prompt definitions with comprehensive keyword/pattern sets."""
        self.meta_prompts = [
            MetaPrompt(
                id="general-meta",
                name="General - Meta Prompt",
                description="Universal orchestration for reasoning, planning, analysis, and everyday assistance",
                keywords=[
                    "general", "reasoning", "planning", "analysis", "explain", "help", "assist",
                    "task", "goal", "objective", "decision", "recommend", "suggest", "advice"
                ],
                patterns=[
                    r'\b(think|reason|analyze|plan|decide|recommend|suggest|explain|help)\b',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt.general.md"),
                category="general",
                mode="meta",
                weight=0.9  # Slightly lower weight (fallback)
            ),
            MetaPrompt(
                id="coding-meta",
                name="Coding - Meta Prompt",
                description="Code generation, refactoring, debugging, and programming tasks",
                keywords=[
                    "code", "function", "class", "debug", "programming", "api", "json", "xml",
                    "python", "javascript", "typescript", "java", "c++", "rust", "go",
                    "algorithm", "data structure", "library", "framework", "syntax", "error",
                    "test", "unit test", "implementation", "interface", "module", "package"
                ],
                patterns=[
                    r'\b(function|class|def |import |const |let |var |return |async |await )',
                    r'```[\s\S]*?```',  # Code blocks
                    r'<code>[\s\S]*?</code>',
                    r'\b(\.py|\.js|\.ts|\.java|\.cpp|\.rs|\.go)\b',  # File extensions
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt.coding.md"),
                category="coding",
                mode="meta",
                weight=1.2  # Higher weight (strong signals)
            ),
            MetaPrompt(
                id="coding-python-meta",
                name="Coding Python - Meta Prompt",
                description="Python-specific code generation with advanced structure and multi-perspective reasoning",
                keywords=[
                    "python", "py", "django", "flask", "fastapi", "pandas", "numpy",
                    "pytest", "pip", "virtualenv", "conda", "pydantic", "typing",
                    "decorator", "generator", "comprehension", "async", "asyncio",
                    "__init__", "__main__", "import", "from import"
                ],
                patterns=[
                    r'\b(python|\.py)\b',
                    r'\b(def |class |import |from .* import |async def )',
                    r'\b(django|flask|fastapi|pandas|numpy|pytest|pydantic)\b',
                    r'@\w+',  # Decorators
                    r'\b(__init__|__main__|__name__)\b',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt.codingpython.md"),
                category="coding",
                mode="meta",
                weight=1.3  # Higher weight for Python-specific signals
            ),
            MetaPrompt(
                id="coding-edit",
                name="Coding - Edit Mode",
                description="Code refactoring, style fixes, documentation, and code improvements",
                keywords=[
                    "refactor", "clean", "style", "format", "document", "improve code",
                    "optimize", "simplify", "restructure", "reorganize", "rename",
                    "add comments", "fix style", "lint", "format code", "code review"
                ],
                patterns=[
                    r'\b(refactor|clean|style|format|document|optimize|simplify)\b.*\b(code|function|class)',
                    r'\b(fix|improve|update|modify).*code',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt_Edits.coding.md"),
                category="coding",
                mode="edit",
                weight=1.1
            ),
            MetaPrompt(
                id="writing-meta",
                name="Writing - Meta Prompt",
                description="Original prose generation: articles, stories, blog posts, marketing copy, emails",
                keywords=[
                    "write", "essay", "article", "blog", "story", "email", "letter",
                    "document", "prose", "narrative", "creative", "copy", "content",
                    "post", "draft", "compose", "author", "text", "paragraph"
                ],
                patterns=[
                    r'\b(write|compose|draft|author|create).*\b(essay|article|blog|story|email|letter|post)',
                    r'\b(marketing|copy|content|prose|narrative)\b',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt.writing.md"),
                category="writing",
                mode="meta",
                weight=1.1
            ),
            MetaPrompt(
                id="writing-edit",
                name="Writing - Edit Mode",
                description="Style transformations: rewriting text into new tone, voice, or genre",
                keywords=[
                    "rewrite", "change tone", "style", "voice", "genre", "transform",
                    "make it", "convert to", "adapt", "rephrase", "paraphrase"
                ],
                patterns=[
                    r'\b(rewrite|transform|adapt|convert).*\b(tone|style|voice|genre)',
                    r'\b(make it|change to|convert to)\b.*\b(formal|casual|professional|playful|academic)',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt_Edits.writing.md"),
                category="writing",
                mode="edit",
                weight=1.0
            ),
            MetaPrompt(
                id="browser-meta",
                name="Browser - Meta Prompt",
                description="Web/page content operations: summarize, extract, analyze web content",
                keywords=[
                    "webpage", "website", "url", "browser", "page", "html", "scrape",
                    "extract from page", "read page", "web content", "site", "link",
                    "webpage content", "page content", "from this page", "from this url",
                    "extract", "summarize", "analyze", "main points", "key points",
                    "from the page", "from the article", "from the website"
                ],
                patterns=[
                    r'https?://[^\s]+',  # URLs
                    r'\b(webpage|website|url|browser|page|html)\b',
                    r'\b(extract|scrape|read|get|summarize|analyze).*\b(page|web|site|url|article)',
                    r'\b(from|from this|from the).*\b(page|url|website|article|site)',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt.browser.md"),
                category="browser",
                mode="meta",
                weight=1.3  # Higher weight for URL detection
            ),
            MetaPrompt(
                id="browser-edit",
                name="Browser - Edit Mode",
                description="Cleaning and refining text extracted from web pages, PDFs, or browser sources",
                keywords=[
                    "clean", "remove", "extract", "scraped", "web content", "html artifacts",
                    "remove navigation", "remove ads", "clean up page", "extract text",
                    "clean up", "remove html", "strip html", "remove formatting"
                ],
                patterns=[
                    r'\b(clean|remove|extract|strip).*\b(html|web|page|scraped|formatting|artifacts)',
                    r'\b(remove|strip).*\b(navigation|menu|ads|banner|header|footer)',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt_Edits.browser.md"),
                category="browser",
                mode="edit",
                weight=1.1
            ),
            MetaPrompt(
                id="rag-meta",
                name="RAG - Meta Prompt",
                description="Retrieval-augmented generation: using retrieved context chunks for grounded answers",
                keywords=[
                    "retrieve", "search", "document", "context", "chunk", "rag",
                    "embedding", "vector", "knowledge base", "source", "reference",
                    "based on", "using context", "from documents", "retrieved"
                ],
                patterns=[
                    r'\b(retrieve|search|context|chunk|embedding|vector|rag|knowledge base)\b',
                    r'{{.*?}}',  # Template placeholders
                    r'\b(based on|using|from).*\b(context|document|source|reference)',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt.rag.md"),
                category="rag",
                mode="meta",
                weight=1.2
            ),
            MetaPrompt(
                id="rag-edit",
                name="RAG - Edit Mode",
                description="Revising text while enforcing consistency with retrieved context chunks",
                keywords=[
                    "align", "match context", "revise with", "edit based on", "update from",
                    "consistent with", "according to", "per context", "based on documents"
                ],
                patterns=[
                    r'\b(align|match|revise|edit|update).*\b(context|document|source)',
                    r'\b(consistent|according|based).*\b(context|document)',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt_Edits.rag.md"),
                category="rag",
                mode="edit",
                weight=1.1
            ),
            MetaPrompt(
                id="general-edit",
                name="General - Edit Mode",
                description="Polishing non-code text: emails, reports, outlines, documentation",
                keywords=[
                    "improve", "polish", "refine", "edit", "fix grammar", "clarify",
                    "make clearer", "better", "enhance", "revise", "clean up text",
                    "rewrite", "rewrite this", "make more", "make it more", "change tone",
                    "more professional", "more formal", "more casual", "more concise"
                ],
                patterns=[
                    r'\b(improve|polish|refine|edit|fix|clarify|enhance|revise|rewrite).*\b(text|writing|document|email|message|letter)',
                    r'\b(make|make it).*\b(clearer|better|more concise|more professional|more formal|more casual)',
                    r'\b(rewrite|change).*\b(tone|style|voice)',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt_Edits.general.md"),
                category="general",
                mode="edit",
                weight=1.1
            ),
            MetaPrompt(
                id="react-meta",
                name="ReAct - Tool-Assisted",
                description="ReAct-style reasoning with tool use: think step-by-step, call tools, observe results",
                keywords=[
                    "tool", "action", "observation", "react", "agent", "step-by-step",
                    "reasoning loop", "use tool", "call function", "execute", "run",
                    "think then act", "plan then execute", "tool use", "agentic"
                ],
                patterns=[
                    r'\b(tool|action|observation|react|agent|step-by-step)\b',
                    r'\b(think|reason).*\b(then|and).*\b(act|execute|call|use)',
                    r'\b(use|call|execute|run).*\b(tool|function|api|action)',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt_ReAct.md"),
                category="react",
                mode="meta",
                weight=1.2
            ),
            MetaPrompt(
                id="relace-meta",
                name="Relace - Edit Tool",
                description="Generate precise file edit snippets for RelaceEditTool with minimal diff formatting",
                keywords=[
                    "relace", "edit tool", "file edit", "diff", "snippet", "patch",
                    "code edit", "modify file", "insert", "delete", "replace",
                    "minimal diff", "edit payload", "json edit", "code change"
                ],
                patterns=[
                    r'\b(relace|edit tool|file edit|diff|patch)\b',
                    r'\b(insert|delete|replace).*\b(code|line|function|block)',
                    r'\b(modify|change|update).*\b(file|code)\b',
                    r'RelaceEditTool',
                ],
                file_path=str(self.meta_prompt_dir / "Meta_Prompt.relace.md"),
                category="coding",
                mode="meta",
                weight=1.4  # High weight for specific tool use
            ),
        ]
    
    def score_all(self, text: str) -> List[Tuple[MetaPrompt, float]]:
        """Score all meta-prompts against input text."""
        if not text or len(text.strip()) < self.min_text_length:
            # Return fallback for very short text
            fallback = next((mp for mp in self.meta_prompts if mp.id == self.fallback_id), None)
            if fallback:
                return [(fallback, 0.5)]
            return []
        
        scored = [(mp, mp.score(text)) for mp in self.meta_prompts]
        # Sort by score descending
        scored.sort(key=lambda x: x[1], reverse=True)
        return scored
    
    def select(
        self,
        text: str,
        force_menu: bool = False
    ) -> Optional[Dict]:
        """
        Select meta-prompt for given text.
        
        Returns:
            Dict with keys: id, file_path, category, mode, score, auto_selected
            or None if cancelled/error
        """
        if not text or not text.strip():
            fallback = self._get_fallback()
            return {
                'id': fallback.id,
                'file_path': fallback.file_path,
                'category': fallback.category,
                'mode': fallback.mode,
                'score': 0.0,
                'auto_selected': True,
                'reason': 'empty_input'
            }
        
        scored = self.score_all(text)
        if not scored:
            fallback = self._get_fallback()
            return {
                'id': fallback.id,
                'file_path': fallback.file_path,
                'category': fallback.category,
                'mode': fallback.mode,
                'score': 0.0,
                'auto_selected': True,
                'reason': 'no_matches'
            }
        
        top_mp, top_score = scored[0]
        second_score = scored[1][1] if len(scored) > 1 else 0.0
        
        # Check if we should auto-select
        should_auto = (
            not force_menu and
            self.auto_detect_enabled and
            top_score >= self.confidence_threshold and
            (top_score - second_score) >= 0.15  # At least 15% better than second
        )
        
        if should_auto:
            return {
                'id': top_mp.id,
                'file_path': top_mp.file_path,
                'category': top_mp.category,
                'mode': top_mp.mode,
                'score': top_score,
                'auto_selected': True,
                'reason': 'high_confidence',
                'all_scores': {mp.id: score for mp, score in scored[:5]}  # Top 5 for logging
            }
        else:
            # Return top choice but mark as needing menu
            return {
                'id': top_mp.id,
                'file_path': top_mp.file_path,
                'category': top_mp.category,
                'mode': top_mp.mode,
                'score': top_score,
                'auto_selected': False,
                'reason': 'low_confidence' if top_score < self.confidence_threshold else 'close_scores',
                'all_scores': {mp.id: score for mp, score in scored[:5]},
                'show_menu': True
            }
    
    def _get_fallback(self) -> MetaPrompt:
        """Get fallback meta-prompt."""
        fallback = next(
            (mp for mp in self.meta_prompts if mp.id == self.fallback_id),
            None
        )
        if fallback:
            return fallback
        return self.meta_prompts[0] if self.meta_prompts else None


def main():
    parser = argparse.ArgumentParser(description='Meta-Prompt Selector for PromptOpt')
    parser.add_argument('--input', required=True, help='Input text file path')
    parser.add_argument('--meta-prompt-dir', required=True, help='Directory containing meta-prompt files')
    parser.add_argument('--force-menu', action='store_true', help='Force menu display (low confidence)')
    parser.add_argument('--config', help='JSON config file path')
    parser.add_argument('--output', help='Output JSON file path (default: stdout)')
    
    args = parser.parse_args()
    
    # Load config if provided
    config = None
    if args.config and os.path.exists(args.config):
        with open(args.config, 'r') as f:
            config = json.load(f).get('metaprompt_selector', {})
    
    # Read input text
    try:
        with open(args.input, 'r', encoding='utf-8') as f:
            text = f.read()
    except Exception as e:
        print(json.dumps({'error': f'Failed to read input: {e}'}), file=sys.stderr)
        sys.exit(1)
    
    # Initialize selector
    selector = MetaPromptSelector(args.meta_prompt_dir, config)
    
    # Select meta-prompt
    result = selector.select(text, force_menu=args.force_menu)
    
    if not result:
        print(json.dumps({'error': 'Selection failed'}), file=sys.stderr)
        sys.exit(1)
    
    # Output result
    output_json = json.dumps(result, indent=2)
    
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(output_json)
    else:
        print(output_json)


if __name__ == '__main__':
    main()

