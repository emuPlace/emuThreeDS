# emuThreeDS
World's first Nintendo 3DS emulator for Apple devices based on Citra.

## Progress
Progress updates for sections within the port.

### Audio
![100%](https://progress-bar.dev/100?width=110)  
Audio support is complete.
- Removed cubeb
- Updated SoundTouch

### Common
![0%](https://progress-bar.dev/0?width=110)  
No changes have been made to common yet.

### Core
![50%](https://progress-bar.dev/50?width=110)  
Core support is basically complete but will require testing.
- Replaced `pthread_jit_write_np` with `mprotect`
  - This needs looking into as I've not used mprotect before
  
### Dedicated Room
![0%](https://progress-bar.dev/0?width=110)  
No changes have been made to dedicated room yet.

### Input Common
![25%](https://progress-bar.dev/25?width=110)  
Input will need to be rewritten to support iOS.
- Removed `input_common`
- Controllers should still be supported via SDL2

### Network
![0%](https://progress-bar.dev/0?width=110)  
No changes have been made to network yet.

### Video Core
![25%](https://progress-bar.dev/25?width=110)  
Video Core currently crashes on `vkCreateSemaphore` and will require more work.

### Web Service
![0%](https://progress-bar.dev/0?width=110)  
No changes have been made to web service yet.
