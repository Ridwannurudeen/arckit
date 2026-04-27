import { existsSync, mkdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { cancel, intro, isCancel, log, outro, text } from '@clack/prompts';
import kleur from 'kleur';
import { copyTemplate } from './scaffold.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function main() {
  intro(kleur.cyan().bold(' create-arc-app '));

  const cwd = process.cwd();
  const argName = process.argv[2];

  const projectName =
    argName ??
    (await text({
      message: 'Project name:',
      placeholder: 'my-arc-agent',
      validate(value) {
        if (!value) return 'Project name is required';
        if (!/^[a-z0-9][a-z0-9-_]*$/i.test(value)) {
          return 'Use letters, numbers, dashes, and underscores only';
        }
        return undefined;
      },
    }));

  if (isCancel(projectName)) {
    cancel('Cancelled.');
    process.exit(0);
  }

  const targetDir = path.resolve(cwd, projectName as string);

  if (existsSync(targetDir)) {
    cancel(`Directory ${kleur.yellow(projectName as string)} already exists.`);
    process.exit(1);
  }

  mkdirSync(targetDir, { recursive: true });

  const templateDir = path.resolve(__dirname, '../templates/default');
  copyTemplate(templateDir, targetDir, { projectName: projectName as string });

  log.success(`Scaffolded ${kleur.cyan(projectName as string)}`);

  outro(`${kleur.bold('Next steps:')}
  ${kleur.dim('cd')} ${projectName}
  ${kleur.dim('npm install')}
  ${kleur.dim('cp .env.example .env')}   ${kleur.gray('# add your private key')}
  ${kleur.dim('npm run lifecycle')}      ${kleur.gray('# create + fund + submit + complete a job on Arc testnet')}

${kleur.gray('Docs:')} ${kleur.cyan('https://github.com/Ridwannurudeen/arckit')}
`);
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
