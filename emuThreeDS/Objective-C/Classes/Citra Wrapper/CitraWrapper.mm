//
//  CitraWrapper.mm
//  emuThreeDS
//
//  Created by Antique on 14/6/2023.
//

#import <UIKit/UIKit.h>

#import "CitraWrapper.h"
#import "InputFactory.h"

#include "audio_core/dsp_interface.h"
#include "configuration.h"
#include "core/cheats/cheat_base.h"
#include "core/cheats/cheats.h"
#include "core/core.h"
#include "core/frontend/applets/default_applets.h"
#include "core/hle/service/am/am.h"
#include "core/loader/loader.h"
#include "core/savestate.h"
#include "emuwindow_vulkan.h"
#include "game_info.h"

@implementation PerformanceStatistics
-(PerformanceStatistics *) initWithSystemFps:(double)systemFps gameFps:(double)gameFps frameTime:(double)frameTime emulationSpeed:(double)emulationSpeed {
    if (self = [super init]) {
        self.systemFps = systemFps;
        self.gameFps = gameFps;
        self.frameTime = frameTime;
        self.emulationSpeed = emulationSpeed;
    } return self;
}
@end


@implementation SaveStateInfo
-(SaveStateInfo *) initWithSlot:(int)slot time:(int)time {
    if (self = [super init]) {
        self.slot = slot;
        self.time = time;
    } return self;
}
@end


Core::System& core{Core::System::GetInstance()};
std::unique_ptr<EmuWindow_Vulkan> emuWindowVulkan;

@implementation CitraWrapper
-(instancetype) init {
    if(self = [super init]) {
        
    } return self;
}

+(CitraWrapper *) sharedInstance {
    static CitraWrapper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CitraWrapper alloc] init];
    });
    return sharedInstance;
}


-(void) importCIAs:(NSArray<NSURL *> *)urls {
    [urls enumerateObjectsUsingBlock:^(NSURL *obj, NSUInteger idx, BOOL *stop) {
        Service::AM::InstallStatus status = Service::AM::InstallCIA(std::string([obj.path UTF8String]), [&self, &obj](std::size_t received, std::size_t total) {
            [self.importingProgressDelegate importingProgressDidChange:obj received:received total:total];
        });
        
        switch (status) {
            case Service::AM::InstallStatus::Success:
                NSLog(@"Success");
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"importingProgressDidFinish" object:obj]];
                break;
            case Service::AM::InstallStatus::ErrorFailedToOpenFile:
                NSLog(@"ErrorFailedToOpenFile");
                break;
            case Service::AM::InstallStatus::ErrorFileNotFound:
                NSLog(@"ErrorFileNotFound");
                break;
            case Service::AM::InstallStatus::ErrorAborted:
                NSLog(@"ErrorAborted");
                break;
            case Service::AM::InstallStatus::ErrorInvalid:
                NSLog(@"ErrorInvalid");
                break;
            case Service::AM::InstallStatus::ErrorEncrypted:
                NSLog(@"ErrorEncrypted");
                break;
        }
    }];
}

-(NSArray<NSString *> *) importedCIAs {
     NSMutableArray<NSString *> *games = @[].mutableCopy;
     const FileUtil::DirectoryEntryCallable ScanDir = [&games, &ScanDir](u64*, const std::string& directory, const std::string& virtual_name) {
         std::string path = directory + virtual_name;
         if (FileUtil::IsDirectory(path)) {
             path += '/';
             FileUtil::ForeachDirectoryEntry(nullptr, path, ScanDir);
         } else {
             if (!FileUtil::Exists(path))
                 return false;
             auto loader = Loader::GetLoader(path);
             if (loader) {
                 bool executable{};
                 const Loader::ResultStatus result = loader->IsExecutable(executable);
                 if (Loader::ResultStatus::Success == result && executable) {
                     [games addObject:[NSString stringWithCString:path.c_str() encoding:NSUTF8StringEncoding]];
                 }
             }
         } return true;
     };


     ScanDir(nullptr, "", FileUtil::GetUserPath(FileUtil::UserPath::SDMCDir) + "Nintendo " "3DS/00000000000000000000000000000000/" "00000000000000000000000000000000/title/00040000");
     ScanDir(nullptr, "", FileUtil::GetUserPath(FileUtil::UserPath::NANDDir) + "00000000000000000000000000000000/title/00040010");
     return games;
 }


-(void) prepareLayer:(CAMetalLayer *)layer {
    emuWindowVulkan = std::make_unique<EmuWindow_Vulkan>((__bridge CA::MetalLayer *)layer);
    emuWindowVulkan->OrientationChanged(true, (__bridge CA::MetalLayer *)layer);
}

-(void) insertRom:(NSString *)path {
    _path = path;
    
    Configuration{};
    Settings::values.layout_option.SetValue((Settings::LayoutOption)[[NSNumber numberWithInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"portrait_layout_option"]] unsignedIntValue]);
    Settings::values.resolution_factor.SetValue([[NSNumber numberWithInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"resolution_factor"]] unsignedIntValue]);
    Settings::values.async_shader_compilation.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"async_shader_compilation"]);
    Settings::values.async_presentation.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"async_presentation"]);
    Settings::values.use_hw_shader.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"use_hw_shader"]);
    
    Settings::values.use_cpu_jit.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"use_cpu_jit"]);
    Settings::values.cpu_clock_percentage.SetValue([[NSNumber numberWithInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"cpu_clock_percentage"]] unsignedIntValue]);
    Settings::values.is_new_3ds.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"is_new_3ds"]);
    
    Settings::values.use_vsync_new.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"use_vsync_new"]);
    Settings::values.shaders_accurate_mul.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"shaders_accurate_mul"]);
    Settings::values.use_shader_jit.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"use_shader_jit"]);
    
    Settings::values.swap_screen.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"swap_screen"]);
    Settings::values.upright_screen.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"upright_screen"]);
    
    Settings::values.render_3d.SetValue((Settings::StereoRenderOption)[[NSNumber numberWithInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"render_3d"]] unsignedIntValue]);
    Settings::values.factor_3d.SetValue([[NSNumber numberWithInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"factor_3d"]] unsignedIntValue]);
    
    Settings::values.dump_textures.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"dump_textures"]);
    Settings::values.custom_textures.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"custom_textures"]);
    Settings::values.preload_textures.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"preload_textures"]);
    Settings::values.async_custom_loading.SetValue([[NSUserDefaults standardUserDefaults] boolForKey:@"async_custom_loading"]);
    
    for (const auto& service_module : Service::service_module_map) {
        Settings::values.lle_modules.emplace(service_module.name, ![[NSUserDefaults standardUserDefaults] boolForKey:@"use_hle"]);
    }
    
    
    for(int i = 0; i < Settings::NativeButton::NumButtons; i++) {
        Common::ParamPackage param{ { "engine", "ios_gamepad" }, { "code", std::to_string(i) } };
        Settings::values.current_input_profile.buttons[i] = param.Serialize();
    }
        
    for(int i = 0; i < Settings::NativeAnalog::NumAnalogs; i++) {
        Common::ParamPackage param{ { "engine", "ios_gamepad" }, { "code", std::to_string(i) } };
        Settings::values.current_input_profile.analogs[i] = param.Serialize();
    }
    
        
    Frontend::RegisterDefaultApplets();
    Input::RegisterFactory<Input::ButtonDevice>("ios_gamepad", std::make_shared<ButtonFactory>());
    Input::RegisterFactory<Input::AnalogDevice>("ios_gamepad", std::make_shared<AnalogFactory>());
    
    Settings::Apply();
    
    FileUtil::SetCurrentRomPath(std::string([_path UTF8String]));
    auto loader = Loader::GetLoader(std::string([_path UTF8String]));
    if(loader)
        loader->ReadProgramId(_title_id);
}

-(void) runEmulation {
    _isRunning = true;
    _isPaused = false;
    
    emuWindowVulkan->MakeCurrent();
    auto _ = core.Load(*emuWindowVulkan, std::string([_path UTF8String]));
    
    
    // MARK: Audio Stretching | BEGIN
    Core::TimingEventType* audio_stretching_event{};
    auto audio_stretching_ticks {msToCycles(500)};
    audio_stretching_event = core.CoreTiming().RegisterEvent("AudioStretchingEvent", [&](u64, s64 cycles_late) {
        if (Settings::values.enable_audio_stretching)
            Core::DSP().EnableStretching(Core::System::GetInstance().GetAndResetPerfStats().emulation_speed < 0.95);
        core.CoreTiming().ScheduleEvent(audio_stretching_ticks - cycles_late, audio_stretching_event);
    });
    core.CoreTiming().ScheduleEvent(audio_stretching_ticks, audio_stretching_event);
    // MARK: Audio Stretching | END
    
    
    while (_isRunning) {
        if (_isPaused) {
            if (Settings::values.volume.GetValue() != 0)
                Settings::values.volume.SetValue(0);
            emuWindowVulkan->PollEvents();
        } else {
            auto _ = core.RunLoop();
            if (Settings::values.volume.GetValue() != 1)
                Settings::values.volume.SetValue(1);
            
            if (core.IsPoweredOn()) {
                auto statistics = core.GetAndResetPerfStats();
                auto performanceStatistics = [[PerformanceStatistics alloc] initWithSystemFps:statistics.system_fps gameFps:statistics.game_fps frameTime:statistics.frametime emulationSpeed:statistics.emulation_speed];
                
                
                _currentTime += 1;
                if ((_currentTime > _lastTime + 1000) && performanceStatistics.gameFps > 0.0) {
                    if (self.performanceStatisticsDelegate && [self.performanceStatisticsDelegate respondsToSelector:@selector(performanceStatisticsDidChange:)]) {
                        [self.performanceStatisticsDelegate performanceStatisticsDidChange:performanceStatistics];
                        _lastTime = _currentTime;
                    }
                }
            }
        }
    }
}

-(void) pauseEmulation {
    _isPaused = true;
}

-(void) resumeEmulation {
    _isPaused = false;
}


-(uint16_t*) GetIcon:(NSString *)path {
    auto icon = GameInfo::GetIcon(std::string([path UTF8String]));
    return icon.data(); // huh? "Address of stack memory associated with local variable 'icon' returned"
}

-(NSString *) GetPublisher:(NSString *)path {
    auto publisher = GameInfo::GetPublisher(std::string([path UTF8String]));
    return [NSString stringWithCharacters:(const unichar*)publisher.c_str() length:publisher.length()];
}

-(NSString *) GetRegion:(NSString *)path {
    auto regions = GameInfo::GetRegions(std::string([path UTF8String]));
    return [NSString stringWithCString:regions.c_str() encoding:NSUTF8StringEncoding];
}

-(NSString *) GetTitle:(NSString *)path {
    auto title = GameInfo::GetTitle(std::string([path UTF8String]));
    return [NSString stringWithCharacters:(const unichar*)title.c_str() length:title.length()];
}


-(void) addCheat:(NSString *)path {
    
}

-(void) getCheats {
    auto _ = Cheats::CheatEngine(_title_id, core).GetCheats();
}

-(void) removeCheat:(NSInteger)index {
    Cheats::CheatEngine(_title_id, core).RemoveCheat(index);
}

-(void) updateCheat:(NSInteger)index withPath:(NSString *)path {
    
}


-(NSArray <SaveStateInfo *> *) saveStates {
    auto save_states = Core::ListSaveStates(_title_id);
    
    NSMutableArray *saveStates = @[].mutableCopy;
    for (auto save_state : save_states)
        [saveStates addObject:[[SaveStateInfo alloc] initWithSlot:save_state.slot time:save_state.time]];
    
    return saveStates;
}

-(void) loadState:(NSInteger)index {
    NSLog(@"loadState: %i", core.SendSignal(Core::System::Signal::Load, index + 1));
}

-(void) saveState {
    NSLog(@"saveState: %i", core.SendSignal(Core::System::Signal::Save, self.saveStates.count + 1));
}


-(void) touchesBegan:(CGPoint)point {
    emuWindowVulkan->OnTouchEvent((point.x * [[UIScreen mainScreen] nativeScale]) + 0.5, (point.y * [[UIScreen mainScreen] nativeScale]) + 0.5, true);
}

-(void) touchesEnded {
    emuWindowVulkan->OnTouchReleased();
}

-(void) touchesMoved:(CGPoint)point {
    emuWindowVulkan->OnTouchMoved((point.x * [[UIScreen mainScreen] nativeScale]) + 0.5, (point.y * [[UIScreen mainScreen] nativeScale]) + 0.5);
}


-(void) orientationChanged:(UIDeviceOrientation)orientation with:(CAMetalLayer *)layer {
    if (_isRunning && !_isPaused) {
        if (orientation == UIDeviceOrientationPortrait) {
            Settings::values.layout_option.SetValue(Settings::LayoutOption::MobilePortrait);
        } else {
            Settings::values.layout_option.SetValue(Settings::LayoutOption::MobileLandscape);
        }
        
        emuWindowVulkan->OrientationChanged(orientation == UIDeviceOrientationPortrait, (__bridge CA::MetalLayer*)layer);
    }
}
@end
