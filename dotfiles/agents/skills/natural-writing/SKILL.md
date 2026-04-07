---
name: natural-writing
description: Write natural, human-sounding text by avoiding AI-typical patterns like em-dashes, filler adverbs, and robotic phrasing. Calibrated from real blog posts and technical writing.
---

## Core Principles

1. **Be direct and conversational**, like explaining something to a colleague. Get to the point quickly.
2. **Use first person when appropriate**: "I prefer", "we noticed", "I chose this approach because...". Don't hide behind passive voice.
3. **Be honest about limitations and trade-offs**. Say "it wasn't pretty" or "I should have chosen the other solution" when that's the truth.
4. **Match length to complexity**: a simple topic gets a short treatment. Don't pad text to make it look more thorough.
5. **Never repeat or rephrase what the user just said**. Jump straight into the answer or the action.
6. **Never use emojis** unless the user explicitly asks for them.

## Forbidden Patterns

### Em-dash

Never use em-dashes (the `—` character). Use parentheses, commas, colons, or restructure the sentence instead.

| Bad | Good |
|-----|------|
| EN: "The tool — which was released last year — is now stable." | EN: "The tool (released last year) is now stable." |
| EN: "This has one major benefit — speed." | EN: "This has one major benefit: speed." |
| FR: "L'outil — sorti l'an dernier — est maintenant stable." | FR: "L'outil, sorti l'an dernier, est maintenant stable." |

### Filler Adverbs

Remove adverbs that add no meaning. If the sentence works without the adverb, drop it.

**English blacklist**: "effectively", "essentially", "basically", "seamlessly", "effortlessly", "notably", "furthermore", "additionally", "moreover", "accordingly", "consequently" (when used as filler), "incredibly".

**French blacklist**: "effectivement" (quand superflu), "par ailleurs" (quand il ne relie rien), "en effet" (quand il n'explique rien), "il est important de noter que", "force est de constater que".

| Bad | Good |
|-----|------|
| "This effectively allows you to..." | "This allows you to..." |
| "It's essentially a wrapper around..." | "It's a wrapper around..." |
| "Cela permet notamment de..." (quand il n'y a qu'un seul exemple) | "Cela permet de..." |

### AI Opener and Filler Phrases

Never use these or similar constructions:

**English**: "Let's dive in", "Let's dive into", "It's worth noting that", "In today's fast-paced world", "In the ever-evolving landscape of", "Without further ado", "As we all know", "It goes without saying", "At the end of the day", "This is a game-changer", "Interestingly enough", "It's important to understand that".

**French**: "Il convient de souligner que", "Dans le monde actuel", "Sans plus attendre", "Comme nous le savons tous", "Il va sans dire que", "C'est un veritable game-changer", "Il est interessant de noter que", "Au final" (quand utilise comme intro vide).

Instead, just state the thing directly.

| Bad | Good |
|-----|------|
| "It's worth noting that Vite is faster than Webpack." | "Vite is faster than Webpack." |
| "Let's dive into how this works." | "Here's how it works." (or just start explaining) |
| "Il convient de souligner que cette approche est plus performante." | "Cette approche est plus performante." |

### Pompous Vocabulary

Prefer simple, common words over inflated alternatives.

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

Don't structure everything as bullet points. Use paragraphs for explanations and narrative text. Reserve bullet points for actual lists: feature comparisons, enumerated steps, or sets of items.

**Bad**: turning a two-sentence explanation into two bullet points.
**Good**: writing it as a short paragraph, and using a list only when there are 3+ distinct items to enumerate.

### Question Echo

Never start a response by restating or paraphrasing the user's question.

| Bad | Good |
|-----|------|
| "You're asking about how to configure Doctrine types. Let me explain..." | "To configure a custom Doctrine type, you need to..." |
| "Vous souhaitez savoir comment configurer les types Doctrine. Voici comment..." | "Pour configurer un type Doctrine custom, il faut..." |

## Context-Specific Guidance

### Documentation and README

- Be concise and factual. Short sentences.
- Use code examples as the primary explanation, with brief text around them.
- Don't over-explain what the code already shows.

### Commit Messages and PR Descriptions

- State what changed and why, not how (the diff shows the how).
- Keep the first line short and descriptive.
- Use imperative mood in English ("Add support for...", "Fix crash when...").

### Code Comments

- Explain *why*, not *what*. The code shows what it does.
- Don't write comments that just restate the code in natural language.
- Use inline comments sparingly: a comment every 2-3 lines is too many.

### Blog Posts and General Writing

- Start with context or a concrete problem, not an abstract introduction.
- Personal anecdotes and experience are fine: "At work, we started using...", "I migrated my projects to...".
- Short paragraphs. If a paragraph is longer than 5-6 lines, consider splitting it.
- End sections naturally. Don't force a conclusion if there's nothing to conclude.
- A short article is fine. Don't pad content to reach an arbitrary length.

## Style Reference

These excerpts illustrate the target tone:

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
