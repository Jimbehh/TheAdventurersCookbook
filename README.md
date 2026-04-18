# ⚔️ The Adventurer's Cookbook

> *A Collection of Recipes for the Discerning Dungeon Gourmet*

A personal recipe helper with a medieval fantasy cookbook aesthetic, inspired by *Delicious in Dungeon*. Built as a single-file HTML app — no backend, no build step, just open and cook.

🔗 **Live at:** [jimbehh.github.io/TheAdventurersCookbook](https://jimbehh.github.io/TheAdventurersCookbook)

---

## ✨ Features

- 📖 **Tome-style book layout** — recipes presented as pages in an ancient cookbook
- 🔗 **Import from URL** — paste a recipe link and it auto-extracts ingredients & method
- ⚖️ **Automatic metric conversion** — US cups/oz/lbs are converted to grams & millilitres
- 🔢 **Adjustable servings** — scale ingredients up or down with a slider
- 📝 **Inline measurements** — ingredient quantities appear next to their mentions in the method steps
- 🗓️ **Weekly planner** — pick recipes for the week, get a combined shopping list
- ✅ **Shopping list** — tick items you need to buy, send to Apple Notes
- 💾 **Export / Import** — back up all recipes as JSON

## 🛠️ Tech

- Single-file HTML app (no dependencies, no build)
- Data stored in `localStorage` (device-specific)
- Google Fonts: Cinzel, Cinzel Decorative, IM Fell English, Crimson Text
- CORS proxy chain for URL recipe imports

## 🚀 Running Locally

Just open `index.html` in any modern browser. No install, no server.

```bash
open index.html
```

## 📦 Data Storage

Recipes are saved in the browser's `localStorage`, so:
- ✅ Your recipes persist across sessions on the same device
- ❌ Recipes don't automatically sync between devices
- 💡 Use the **Export** button to back up your recipes as JSON, and **Import** on another device

## 🎨 Design Inspiration

Visual language inspired by *Delicious in Dungeon* (Dungeon Meshi) — warm parchment tones, ink illustrations, illuminated manuscript feel. Recipes presented as pages in an adventurer's field journal.

---

*Built with Claude Code.*
