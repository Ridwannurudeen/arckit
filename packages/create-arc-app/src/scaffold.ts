import {
  copyFileSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import path from 'node:path';

export type ScaffoldVars = {
  projectName: string;
};

const TEMPLATEABLE_EXTS = new Set(['.json', '.md', '.ts', '.js', '.env', '.example']);

/// Recursively copy a template directory, applying {{projectName}} substitutions
/// to text files and renaming any `_gitignore` to `.gitignore` (npm strips dotfiles
/// from packed templates).
export function copyTemplate(srcDir: string, destDir: string, vars: ScaffoldVars): void {
  const entries = readdirSync(srcDir);
  for (const entry of entries) {
    const srcPath = path.join(srcDir, entry);
    const destEntry = entry === '_gitignore' ? '.gitignore' : entry;
    const destPath = path.join(destDir, destEntry);

    const stat = statSync(srcPath);
    if (stat.isDirectory()) {
      mkdirSync(destPath, { recursive: true });
      copyTemplate(srcPath, destPath, vars);
      continue;
    }

    const ext = path.extname(entry);
    if (TEMPLATEABLE_EXTS.has(ext) || entry.startsWith('_')) {
      const raw = readFileSync(srcPath, 'utf8');
      const out = raw.replaceAll('{{projectName}}', vars.projectName);
      writeFileSync(destPath, out);
    } else {
      copyFileSync(srcPath, destPath);
    }
  }
}
