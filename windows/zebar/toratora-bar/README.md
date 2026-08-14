# toratora-bar

Tokyo Night terminal-style Zebar bar for GlazeWM.

## Build

```sh
cd ui
npm install
npm run build   # → outputs to ../toratora-widget/
```

Zebar loads `toratora-widget/index.html` (pre-built). Edit sources in `ui/src/`.

## Notes

- shellExec (GPU/temp/VPN, Wi-Fi settings) requires the privileges declared in zpack.json.
- Wi-Fi: signal color-coded, ↓↑ live speed, hover = inline details, click = Windows Wi-Fi flyout.
