# App Icon Creation Guide

To create your own app icon for PayGuardian, follow these steps:

1. Create a 1024x1024 pixel PNG image for your app icon
2. Save it as `icon.png` in this directory (replace the existing file)
3. Run the following command to generate all required icon sizes:
   ```
   flutter pub run flutter_launcher_icons:main
   ```

## Icon Design Tips

- Keep the design simple and recognizable at small sizes
- Use a transparent background if desired
- Avoid placing important elements near the edges (they may be cropped)
- Test your icon on both light and dark backgrounds

## Required Icon Sizes

The flutter_launcher_icons package will automatically generate all required sizes for:
- Android (various densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- iOS (various sizes for different devices)
- Web (favicon and various sizes)

Once you've created your icon.png file, simply run the command above to generate all platform-specific icons.