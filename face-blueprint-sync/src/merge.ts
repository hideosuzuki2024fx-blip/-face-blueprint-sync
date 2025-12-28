import yaml from 'js-yaml';

export function buildPromptFromCharacter(c: any, extras: string[]): string {
  const tags = new Set<string>([
    'same face identity',
    'imaginary adult woman'
  ]);
  // inject face_blueprint (flatten simple keys)
  const fb = c?.face_blueprint || {};
  for (const [k, v] of Object.entries(fb)) {
    if (typeof v === 'string') tags.add(v);
    if (typeof v === 'object' && v !== null) {
      for (const vv of Object.values(v as any)) tags.add(String(vv));
    }
  }
  // always_add
  for (const t of (c?.always_add || [])) tags.add(String(t));
  // extras (scene, outfit, etc.)
  for (const t of extras) tags.add(String(t));
  return Array.from(tags).join(', ');
}
