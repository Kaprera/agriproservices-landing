#!/usr/bin/env python3
"""Print the CSP sha256 hashes for every inline <script>/<style> in index.html.

The site ships no external JS or CSS, so hashing the inline blocks lets the policy
drop 'unsafe-inline' entirely. Re-run this after editing any inline block and paste
the result into _headers, or the browser will refuse to run them.
"""
import base64, hashlib, io, re, sys

src = io.open('index.html', encoding='utf-8').read()
script, style = [], []
for m in re.finditer(r'<(script|style)([^>]*)>(.*?)</\1>', src, re.S):
    tag, attrs, body = m.group(1), m.group(2), m.group(3)
    if 'src=' in attrs:
        continue
    h = "'sha256-%s'" % base64.b64encode(hashlib.sha256(body.encode('utf-8')).digest()).decode()
    (script if tag == 'script' else style).append((h, attrs.strip() or '(inline)', len(body)))

for label, items in (('script-src', script), ('style-src', style)):
    print('# %s' % label)
    for h, attrs, n in items:
        print('  %s  <- %s, %d bytes' % (h, attrs, n))
print()
print("script-src 'self' %s" % ' '.join(h for h, _, _ in script))
print("style-src 'self' %s https://fonts.googleapis.com" % ' '.join(h for h, _, _ in style))
