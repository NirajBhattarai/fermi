#!/usr/bin/env bash
# Typeset docs/yellow-paper.md into web/public/fermi-yellow-paper.pdf.
# Requires pandoc and tectonic (brew install pandoc tectonic).
set -euo pipefail
cd "$(dirname "$0")/../.."

out=web/public/fermi-yellow-paper.pdf
# Drop the markdown H1 and draft line; the title page carries them.
sed '1,3d' docs/yellow-paper.md | pandoc -f markdown -o "$out" \
  --pdf-engine=tectonic \
  -H docs/pdf/header.tex \
  --toc \
  -M title="The Balanced Fermi–Dirac AMM" \
  -M subtitle="Yellow Paper · Draft v0.1 · 2026-11-19" \
  -V papersize=a4 -V geometry:margin=2.2cm -V fontsize=10.5pt \
  -V colorlinks=true -V linkcolor=fermi -V urlcolor=fermi -V toccolor=fermi

echo "wrote $out"
