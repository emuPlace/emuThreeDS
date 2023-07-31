# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Update
### Next Release
- Should come this week
- Only for BMAC members initially
- Requires eSign or Sideloadly for sideloading
  - This is an issue with Xcode 15 and annoyingly now I’ve built everything with it

### Changes
- App will now have a sign in screen to authenticate with BMAC
- Load and save states will be attempted
- Virtual controller customisation/repositioning should be added
Read more changes below 👇🏼

## [1.0.6.5] - WIP
### Added
#### Application
- Added support for iOS and iPadOS 14
  - <span style="color: rgb(255, 149, 0)">This will need to be tested thoroughly</span>

#### Library
- Added ability to import CTR Importable Archive (`.cia`) roms
  - Tapping an imported rom will launch it but no other functionality is available yet

### Changed
#### Library
- Changed the user interface to be more simplified for now

### Fixed
#### Emulation
- Fixed a crash where the on-screen controller would disappear and reappear when rotating the device by ditching Apple's GCVirtualController and making my own
- Fixed an issue where the emulation would crash when rotating the device


## [1.0.6.4] - 8th June 2023
### Added
- Added new settings
  - Enable Logging
  - Enable VSync New
  - Shaders Accurate Mul
  - Enable Shader JIT
  - Swap Screen
  - Upright Screen
  - Stereo Render
  - 3D Factor
  - Dump Textures
  - Custom Textures
  - Preload Textures
  - Async Custom Loading
- Added in-game menu button
  - <span style="color: rgb(255, 149, 0)">Current option appears buggy</span>
- Added full physical controller support

### Changed
- Updated VulkanSDK from `v1.3.243.0` to `v1.3.250.0`

### Fixed
- Fixed an issue where audio would not play through headphones, etc
  - <span style="color: rgb(255, 149, 0)">This will need to be tested</span>

## [1.0.6.1] - 29th May 2023
### Added
- Built XCFrameworks for 90% of all external libraries
  - Only includes support for iOS and iPadOS for now, tvOS support is planned
  - Clone the repository with `--branch swiftui-rework --recursive` to built the app yourself
    - <span style="color: rgb(255, 59, 48)">This is only recommended for developers, it does not do anything important yet</span>
- Added rom icon and publisher within the Library screen
- Improved the handling of roms with **[LibraryManager.swift](../../emuThreeDS/Swift/Classes/LibraryManager.swift)**
- Added functional JIT setting

### Changed
- Transitioned to SwiftUI by recreating the Xcode project
- Updated VulkanSDK from `v1.3.239.0` to `v1.3.243.0`
- Updated Citra to the latest Vulkan fork by GPUcode
- Improved virtual (on-screen) controller support
- Improved portrait and landscape support
  - Orientation changing now works correctly
  - Landscape touch support now works correctly

### Removed
- Removed numerous header and source files that are no longer needed
