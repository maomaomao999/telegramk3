# Kislap 1.1 Screenshot Package

These images are generated from the current Kislap 1.1 simulator build. No synthetic nearby users are shown.

## Output

- `en-US/iphone-6.9`: 1320 × 2868 portrait PNG
- `en-US/ipad-13`: 2064 × 2752 portrait PNG

The final PNG files are RGB and contain no alpha channel.

## Regenerate

The script expects the verified raw simulator captures in `/tmp`:

- `/tmp/kislap-1.1-learning-hub.png`
- `/tmp/kislap-1.1-learning-hub-ipad-v2.png`

Run:

```bash
python3 -m pip install --target /tmp/kislap-pillow Pillow
zsh app-store/1.1/generate_screenshots.sh
```

Before uploading, visually compare every image with the submitted binary and verify dimensions and alpha:

```bash
find app-store/1.1/en-US -name '*.png' -print0 | \
  xargs -0 -n1 sips -g pixelWidth -g pixelHeight -g hasAlpha
```
