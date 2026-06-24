# Ebb & Flow

> The tide app for people who live by the ocean.

**Ebb & Flow** is a native SwiftUI universal app for tide and ocean intelligence — built to surpass clarity and delight with poetic design, Liquid Glass mastery, and deep personalization for surfers, boaters, swimmers, photographers, and anyone who feels the pull of the sea.

## Status

🌊 **Pre-development** — planning complete, implementation starting soon.

This repository is a placeholder while the Xcode project and core features are built out in phases.

## Vision

Equal balance of **form** and **function**:

- **Form** — Time-aware sky gradients, Liquid Glass navigation chrome, scrubbable tide charts with water-fill animation, calm micro-interactions and haptics that feel like the ocean.
- **Function** — NOAA-accurate predictions, offline caching, My Spots favorites, activity-aware insights, widgets, Live Activities, and an optional tide-tagged journal.

## Platforms

iPhone · iPad · Mac · Apple Watch · visionOS (immersive, later phase)

## Tech Stack

- SwiftUI (iOS 26+)
- Swift Charts, Canvas, MapKit
- SwiftData
- WidgetKit, ActivityKit, App Intents
- NOAA CO-OPS (US) + extensible global tide providers

## Roadmap

| Phase | Focus |
|-------|-------|
| **1 — Foundation** | NOAA data layer, Liquid Glass shell, Today chart, My Spots |
| **2 — Depth** | Weekly/monthly charts, iPad/Mac layouts, station map |
| **3 — Ambient** | Widgets, Live Activities, notifications, Journal, Watch |
| **4 — Launch** | Global data, accessibility polish, App Store readiness |

## Development

The Xcode project has not been scaffolded yet. Phase 1 will add:

- Multi-target SwiftUI app (iOS 26+)
- NOAA `DataGetterClient` + SwiftData cache
- `RootView` with Liquid Glass tab bar and tide bottom accessory
- Marina del Rey (`9410840`) as the default preview station

## Data & Disclaimer

Tide predictions are for informational purposes only — not for navigation. Always verify conditions on the water. US coastal data sourced from [NOAA CO-OPS](https://tidesandcurrents.noaa.gov/).

## License

TBD — source will be published under an appropriate license before public release.

---

*Built with care for the coast. Starting in Southern California, excellent everywhere.*