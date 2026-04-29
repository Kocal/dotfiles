---
name: natural-writing
description: Write natural, human-sounding text by avoiding AI-typical patterns like em-dashes, filler adverbs, and robotic phrasing. Calibrated from real blog posts and technical writing.
---

## Core Principles

1. **Be direct and conversational**, like explaining to colleague. Get to point fast.
2. **Use first person when appropriate**: "I prefer", "we noticed", "I chose this because...". No passive voice hiding.
3. **Be honest about limitations and trade-offs**. Say "it wasn't pretty" or "I should have chosen the other solution" when true.
4. **Match length to complexity**: simple topic = short treatment. No padding.
5. **Never repeat or rephrase what the user just said**. Jump straight to answer or action.
6. **Never use emojis** unless user asks.

## Forbidden Patterns

### Em-dash

Never use em-dashes (the `—` character). Use parentheses, commas, colons, or restructure instead.

| Bad | Good |
|-----|------|
| EN: "The tool — which was released last year — is now stable." | EN: "The tool (released last year) is now stable." |
| EN: "This has one major benefit — speed." | EN: "This has one major benefit: speed." |
| FR: "L'outil — sorti l'an dernier — est maintenant stable." | FR: "L'outil, sorti l'an dernier, est maintenant stable." |

### Filler Adverbs

Drop adverbs that add no meaning. If sentence works without it, cut it.

**English blacklist**: "effectively", "essentially", "basically", "seamlessly", "effortlessly", "notably", "furthermore", "additionally", "moreover", "accordingly", "consequently" (as filler), "incredibly".

**French blacklist**: "effectivement" (quand superflu), "par ailleurs" (quand il ne relie rien), "en effet" (quand il n'explique rien), "il est important de noter que", "force est de constater que".

| Bad | Good |
|-----|------|
| "This effectively allows you to..." | "This allows you to..." |
| "It's essentially a wrapper around..." | "It's a wrapper around..." |
| "Cela permet notamment de..." (quand il n'y a qu'un seul exemple) | "Cela permet de..." |

### AI Opener and Filler Phrases

Never use:

**English**: "Let's dive in", "Let's dive into", "It's worth noting that", "In today's fast-paced world", "In the ever-evolving landscape of", "Without further ado", "As we all know", "It goes without saying", "At the end of the day", "This is a game-changer", "Interestingly enough", "It's important to understand that".

**French**: "Il convient de souligner que", "Dans le monde actuel", "Sans plus attendre", "Comme nous le savons tous", "Il va sans dire que", "C'est un veritable game-changer", "Il est interessant de noter que", "Au final" (comme intro vide).

Just state the thing directly.

| Bad | Good |
|-----|------|
| "It's worth noting that Vite is faster than Webpack." | "Vite is faster than Webpack." |
| "Let's dive into how this works." | "Here's how it works." (or just start explaining) |
| "Il convient de souligner que cette approche est plus performante." | "Cette approche est plus performante." |

### Pompous Vocabulary

Use simple words.

| Avoid | Prefer |
|-------|--------|
| "utilize" | "use" |
| "leverage" | "use" or "take advantage of" |
| "comprehensive" | "complete" or "full" |
| "robust" | "solid" or "reliable" |
| "streamline" | "simplify" |
| "delve" | "look into" or "explore" |
| "facilitate" | "help" or "make easier" |
| "optimiser" (quand exagere) | "ameliorer" |

### Excessive Bullet Points

Use paragraphs for explanations. Bullet points only for real lists: feature comparisons, steps, sets of items.

**Bad**: two-sentence explanation as two bullet points.
**Good**: short paragraph; list only when 3+ distinct items.

### Question Echo

Never restate the user's question.

| Bad | Good |
|-----|------|
| "You're asking about how to configure Doctrine types. Let me explain..." | "To configure a custom Doctrine type, you need to..." |
| "Vous souhaitez savoir comment configurer les types Doctrine. Voici comment..." | "Pour configurer un type Doctrine custom, il faut..." |

## Context-Specific Guidance

### Documentation and README

- Concise, factual. Short sentences.
- Code examples as primary explanation, brief text around them.
- Don't over-explain what code shows.

### Commit Messages and PR Descriptions

- What changed and why, not how (diff shows how).
- First line: short and descriptive.
- Imperative mood in English ("Add support for...", "Fix crash when...").

### Code Comments

- Explain *why*, not *what*.
- No comments that restate code in natural language.
- Inline comments sparingly: one every 2-3 lines is too many.

### Blog Posts and General Writing

- Start with context or concrete problem, not abstract intro.
- Personal anecdotes fine: "At work, we started using...", "I migrated my projects to...".
- Short paragraphs. Over 5-6 lines — split it.
- End sections naturally. No forced conclusion.
- Short article fine. No padding.

## Style Reference

**Conversational and direct** (EN):
> "If you've ever tried to test time-sensitive features across multiple Symfony apps, you know the pain."

**Honest about choices** (EN):
> "Personally, as a Node.js and bundlers enthusiast, I often prefer using a full Node.js toolchain for my projects, except for very small projects that I don't really care about and where AssetMapper is perfectly fine."

**Short when the subject is simple** (EN):
> "A super short article explaining how to set up Caddy as a proxy for an auto-hosted Coolify, with Websocket support."

**Self-aware and transparent** (EN):
> "It wasn't pretty; this part of the AssetMapper code is really not made to be extended easily: I juggled between decoration and inheritance, method overriding, and tinkering."

**Direct problem statement** (FR):
> "It uses YAML. There is no auto-completion or validation. I want the configuration to be in the code of our Doctrine entities, not in a configuration file."

**Contextual intro without fluff** (FR):
> "Since the recent dramas with Netlify and other PaaS on Twitter, regarding excessively high billing, I decided to take back control of my projects and migrate them to Coolify."