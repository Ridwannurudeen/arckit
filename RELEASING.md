# Releasing ArcKit

ArcKit publishes three packages. Each can be released independently via tag.

## Before you release

- [ ] All CI checks green on `main`
- [ ] Bump version in the relevant `package.json` / `pyproject.toml`
- [ ] Update CHANGELOG.md (TODO: not yet created)
- [ ] Test the published-shape locally:
  ```bash
  pnpm pack --pack-destination /tmp     # in packages/sdk and packages/create-arc-app
  cd packages/sdk-py && python -m build  # produces dist/*.whl + dist/*.tar.gz
  ```

## Required GitHub secrets

Add to https://github.com/Ridwannurudeen/arckit/settings/secrets/actions:

| Secret | Source |
|---|---|
| `NPM_TOKEN` | https://www.npmjs.com/settings/<user>/tokens — pick "Automation" type |
| `PYPI_TOKEN` | https://pypi.org/manage/account/token/ — scope to the `arckit-sdk` project |

## Release flow

The `.github/workflows/publish.yml` workflow fires on tag push and routes by tag prefix:

| Tag pattern | Publishes |
|---|---|
| `sdk-vX.Y.Z` | `arckit-sdk` to npm |
| `create-arc-app-vX.Y.Z` | `create-arc-app` to npm |
| `sdk-py-vX.Y.Z` | `arckit-sdk` to PyPI |
| `vX.Y.Z` | All three (coordinated release) |

Example — coordinated v0.1.0 release:

```bash
# Bump versions in package.json files first, commit:
git commit -am "chore: release v0.1.0"
git push

# Then tag and push:
git tag v0.1.0
git push origin v0.1.0
```

CI runs build + tests before publishing. If anything fails, the publish is aborted.

## Manual fallback (only if CI is broken)

```bash
# arckit-sdk
cd packages/sdk
pnpm build && pnpm test
pnpm publish --access public

# create-arc-app
cd packages/create-arc-app
pnpm build && pnpm test
pnpm publish --access public

# arckit (Python)
cd packages/sdk-py
python -m build
twine upload dist/*
```

## After release

- [ ] Verify install: `npm install arckit-sdk` / `pip install arckit-sdk` / `npx create-arc-app demo`
- [ ] Tweet from project account (template in `docs/SUBMISSION.md`)
- [ ] Update Arc community forum thread with release notes
- [ ] Submit to Arc Builders Fund if v0.1 is the first GA cut (see `docs/SUBMISSION.md`)
