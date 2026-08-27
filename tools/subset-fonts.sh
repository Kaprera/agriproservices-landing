#!/usr/bin/env bash
# Regenerate assets/fonts/*.woff2 from the full-coverage originals in Identity/Fonts.
#
# The shipped faces are subset to Latin + the punctuation the site actually uses.
# Helvetica ships 2197 glyphs and Garamond 663 (Cyrillic, Greek, symbols); the page
# renders none of them, and Arabic is served separately by Almarai. Subsetting takes
# the four preloaded faces from 411KB to 162KB on the critical path.
#
# Requires: pip install "fonttools[woff]" brotli
set -euo pipefail
cd "$(dirname "$0")/.."

# Basic Latin, Latin-1 Supplement, Latin Extended-A, General Punctuation
# (en/em dashes, curly quotes, ellipsis, bullet), currency, trademark, arrows.
UNICODES="U+0020-007E,U+00A0-00FF,U+0100-017F,U+2000-200D,U+2010-2015,U+2018-201A,\
U+201C-201E,U+2020-2022,U+2026,U+2030,U+2039,U+203A,U+2044,U+20AC,U+2122,U+2190-2193,U+2212,U+FEFF"

# source TTF (in Identity/Fonts) | shipped woff2 basename | extra pyftsubset flags
#
# Garamond ships unhinted. It carries ~62KB of TrueType hinting across the two faces,
# which sat on the critical path in front of the LCP element (the hero paragraph is
# Garamond) and cost ~300ms of LCP on a throttled mobile connection. It is only used
# for body copy at 16px and up, where DirectWrite leans on its own vertical hinting
# and macOS/Android ignore TT instructions altogether. Drop --no-hinting below to
# restore it if Windows rendering ever looks off.
#
# Helvetica keeps its hinting: it is the UI and heading face, it renders at small
# sizes in the nav, and stripping it would save only a few KB.
declare -a FACES=(
  "Identity/Fonts/Helvetica/Helvetica.ttf|Helvetica|"
  "Identity/Fonts/Helvetica/Helvetica-Bold.ttf|Helvetica-Bold|"
  "Identity/Fonts/Garamond/GARA.TTF|Garamond|--no-hinting --drop-tables+=LTSH,hdmx,gasp"
  "Identity/Fonts/Garamond/GARAIT.TTF|Garamond-Italic|--no-hinting --drop-tables+=LTSH,hdmx,gasp"
)

for face in "${FACES[@]}"; do
  IFS='|' read -r src name extra <<< "$face"
  out="assets/fonts/${name}.woff2"
  # shellcheck disable=SC2086
  pyftsubset "$src" --unicodes="$UNICODES" --layout-features='*' \
    $extra --flavor=woff2 --output-file="$out"
  printf '%-40s -> %-34s %4s KB\n' "$src" "$out" "$(( $(wc -c < "$out") / 1024 ))"
done
