# GitHub Copilot Instructions

## Project Overview

This is a **LaTeX bachelor's thesis (BP)** for UHK (Hradec Králové) FIM faculty, written in English. The thesis topic is implementing a distributed P2P video streaming platform in Rust using libp2p, GStreamer, and Wayland screen capture.

The thesis is built upon this implementation project:
- https://github.com/Luxuride/p2p-stream

## File Structure

| File | Purpose |
|---|---|
| `main.tex` | Root document — thesis metadata only (author, title, supervisor, faculty, keywords, abstract) |
| `text-01-kapitoly.tex` | All thesis body chapters — edit here for content |
| `text-03-zkratky.tex` | Acronym definitions via `\DeclareAcronym{}` |
| `text-02-literatura/text-02-literatura.bib` | BibTeX bibliography |
| `fim-uhk-thesis.cls` | Custom document class (do not edit; based on VUT FIT template) |
| `recorder-pipeline.puml` / `renderer-pipeline.puml` | PlantUML source for pipeline diagrams |
| `out/recorder-pipeline/` / `out/renderer-pipeline/` | Generated diagram PNGs (referenced in LaTeX) |

## Build Workflow

**Enter the dev shell first** (provides `texliveFull`, `plantuml`, `graphviz`):
```sh
nix develop
```

**Generate PlantUML diagrams** (must be done before LaTeX compilation when `.puml` files change):
```sh
plantuml -tpng recorder-pipeline.puml -o out/recorder-pipeline/
plantuml -tpng renderer-pipeline.puml -o out/renderer-pipeline/
```

**Compile the thesis** (standard LaTeX sequence):
```sh
pdflatex main && bibtex main && pdflatex main && pdflatex main
```
Or with `latexmk`:
```sh
latexmk -pdf main
```
## Develompent workflow
- You can use `nix-shell -c` to run needed commands

## Key Conventions

### Acronyms
- Declare in `text-03-zkratky.tex`: `\DeclareAcronym{P2P}{short=P2P, long=Peer to Peer}`
- Use in text with `\ac{P2P}` (expands on first use, abbreviates after)

### Citations
- Bibliography style is `iso690` — entries go in `text-02-literatura/text-02-literatura.bib`
- Cite with `~\cite{citekey}`, e.g. `~\cite{schollmeierDefinitionPeertopeerNetworking2001}`
- BibTeX keys follow pattern: `authorNameShortTitleYear`
 - Use citations wherever possible. If new sources are needed, search for them and note them, but expect the user to add them to Zotero and re-export the `.bib` file.
- When adding citations, make sure to check it against full-text sources to ensure it is relevant and supports the point being made. Avoid making claims that are not supported by the cited source. If a claim is made that is not supported by the cited source, either find a different source that supports the claim or rephrase the claim to accurately reflect what the cited source says.
- Never make up citations without verifying that the source actually supports the claim being made. If a citation is needed but cannot be found, it is better to omit the claim than to include an unsupported citation.

### Cross-references
- Use `\label{sec:abr}` on sections/figures, reference with `\ref{sec:abr}` or `\S\ref{sec:abr}`
- Figures reference generated PNGs: `\includegraphics[width=1\textwidth]{out/recorder-pipeline/recorder-pipeline.png}`

### Document Class Options
- Current: `\documentclass[english]{fim-uhk-thesis}` — keep `english` parameter for EN thesis
- Supported: `english`, `slovak`, `enslovak`, `print`, `zadani`, `twoside`

### Quote environment
The `quote` environment is redefined (in `main.tex`) to render as inline italic with `""` instead of an indented block.

## Thesis Architecture (for content editing)

The implementation described covers:
- **Recorder crate** — Wayland screen capture via `ashpd` → PipeWire FD → GStreamer pipeline → RTP/H.264 packets
- **Renderer crate** — RTP packets → GStreamer decode pipeline → `autovideosink`
- **Video Reader crate** — Raw Y4M video file reader (e.g., Big Buck Bunny) serving as a reproducible source for automated testing.
- **Transport layer** — Three libp2p implementations: Gossipsub (mesh, higher latency), direct Stream (lower latency, no mesh), and a Hybrid approach (Gossipsub for control/spares, Stream for heavy payload).
- **Testing & Analysis** — Automated testing framework to evaluate stream metrics (latency, packet loss, misordered packets, bitrate, MTU sizes). Analysis is done via R scripts (`analysis_metrics.R`) to generate comparison plots.
