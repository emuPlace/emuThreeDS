# Building

## Notes
- Simulator support has been partially added with the latest externals commit(s).
  - Emulation is not possible currently due to MoltenVK not having an x86_64 dylib.

## Environment
- macOS
- Xcode

## Prerequisites
- **[Boost](https://www.boost.org/)**
- Git
- **[Vulkan SDK](https://sdk.lunarg.com/sdk/download/latest/mac/vulkan-sdk.dmg)**

## Steps
### Clone Repository

```
cd path/to/local/directory
git clone --recursive -b swiftui-rework https://github.com/emuplace/emuthreeds
```

### Build Project
> **Note**: You may need to change the developer account in Signing and Capabilities to your own.

- Open the Xcode project `emuThreeDS.xcodeproj` and select your device in the device selection menu.
- Click on the Play button to the left of the device selection menu.
