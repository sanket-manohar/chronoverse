# Releasing Chronoverse

## One-time setup

1. Create the repository `sanket-manohar/chronoverse` and push `main`.
2. **Website:** in the repository settings, open *Pages* and set *Source* to *Actions*. The
   `Website` workflow then publishes `website/` to https://sanket-manohar.github.io/chronoverse/.
3. **Social preview:** in the repository settings, upload `doc/brand/banner.jpg` as the social preview image.
4. **First publish (manual):** pub.dev requires the first version to be published from your machine:
   ```bash
   flutter pub publish
   ```
   Then on pub.dev open the package's *Admin* tab and transfer it to the publisher
   `sanketmanohar.com`.
5. **Automated publishing:** on the package's *Admin* tab, enable *Automated publishing* from
   the repository `sanket-manohar/chronoverse` with tag pattern `v{{version}}`, and require the
   environment `pub.dev`. Create an environment named `pub.dev` in the repository settings.

## Every release

1. Update `version:` in `pubspec.yaml` and add a `## x.y.z` section to `CHANGELOG.md`.
2. If the guides changed, rebuild the PDFs in `doc/guides/` and commit them.
3. Commit, then tag and push:
   ```bash
   git tag v1.0.1
   git push origin main --tags
   ```
4. The `Release` workflow checks that the tag matches the pubspec version, runs analysis and tests,
   publishes to pub.dev (skipped if that version is already there) and creates a release with the PDF
   guides attached.
