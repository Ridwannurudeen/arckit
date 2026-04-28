import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { copyTemplate } from '../src/scaffold.js';

const TEMPLATE_DIR = path.resolve(__dirname, '../templates/default');

describe('copyTemplate', () => {
  let tmp: string;

  beforeEach(() => {
    tmp = mkdtempSync(path.join(tmpdir(), 'arckit-test-'));
  });

  afterEach(() => {
    rmSync(tmp, { recursive: true, force: true });
  });

  it('creates package.json with the project name substituted', () => {
    copyTemplate(TEMPLATE_DIR, tmp, { projectName: 'my-cool-agent' });
    const pkgPath = path.join(tmp, 'package.json');
    expect(existsSync(pkgPath)).toBe(true);
    const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));
    expect(pkg.name).toBe('my-cool-agent');
    expect(pkg.dependencies['arckit-sdk']).toBeDefined();
    expect(pkg.dependencies.viem).toBeDefined();
  });

  it('renames _gitignore to .gitignore', () => {
    copyTemplate(TEMPLATE_DIR, tmp, { projectName: 'app' });
    expect(existsSync(path.join(tmp, '.gitignore'))).toBe(true);
    expect(existsSync(path.join(tmp, '_gitignore'))).toBe(false);
  });

  it('copies the lifecycle script with valid TypeScript', () => {
    copyTemplate(TEMPLATE_DIR, tmp, { projectName: 'app' });
    const lifecycle = readFileSync(path.join(tmp, 'src/lifecycle.ts'), 'utf8');
    expect(lifecycle).toContain("import { ArcKit, JobStatus } from 'arckit-sdk'");
    expect(lifecycle).toContain('createJob');
    expect(lifecycle).toContain('setBudget');
    expect(lifecycle).toContain('fund');
    expect(lifecycle).toContain('submit');
    expect(lifecycle).toContain('complete');
  });

  it('substitutes project name in README', () => {
    copyTemplate(TEMPLATE_DIR, tmp, { projectName: 'my-cool-agent' });
    const readme = readFileSync(path.join(tmp, 'README.md'), 'utf8');
    expect(readme).toContain('my-cool-agent');
    expect(readme).not.toContain('{{projectName}}');
  });

  it('copies the .env.example file', () => {
    copyTemplate(TEMPLATE_DIR, tmp, { projectName: 'app' });
    expect(existsSync(path.join(tmp, '.env.example'))).toBe(true);
  });
});
