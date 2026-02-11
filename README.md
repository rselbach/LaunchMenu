# LauncherMenu

Personal macOS menubar app for launching apps with F1–F12 hotkeys. Built for my
own use and tailored to my workflow.

## Auto Updates

LauncherMenu uses Sparkle for in-app updates. Configure the public key and
appcast feed URL before releasing.

1. Generate Sparkle keys: `./bin/generate_keys` from the Sparkle distribution.
2. Update `SUPublicEDKey` in `Sources/Info.plist` with the public key.
3. Store the private key as the `SPARKLE_EDDSA_PRIVATE_KEY` GitHub secret.
4. Enable GitHub Pages for the repo (Settings → Pages → Source: GitHub Actions).
