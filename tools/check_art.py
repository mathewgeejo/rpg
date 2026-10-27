"""Verify original pixel designs and credited artist assets against the reviewed manifest."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'assets/pixel/manifest.json').read_text(encoding='utf-8'))
approved = {entry['path']: entry for entry in manifest['images']}
problems = []
for path in (root / 'assets').rglob('*'):
    if path.suffix.lower() not in {'.png', '.jpg', '.jpeg', '.webp', '.gif'}:
        continue
    relative = path.relative_to(root).as_posix()
    entry = approved.get(relative)
    if not entry:
        problems.append(f'Unreviewed raster artwork: {relative}')
    elif hashlib.sha256(path.read_bytes()).hexdigest() != entry['sha256']:
        problems.append(f'Artwork changed since source review: {relative}')
for relative in approved:
    if not (root / relative).is_file():
        problems.append(f'Missing source artwork: {relative}')
if problems:
    raise SystemExit('\n'.join(problems))
originals = sum(entry['path'].startswith('assets/custom/') for entry in manifest['images'])
print(f'PASS: {originals} original pixel assets and {len(approved)-originals} credited artist-source images verified; no unapproved raster assets.')
