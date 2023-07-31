//
//  emuwindow_vulkan.h
//  emuThreeDS
//
//  Created by Antique on 18/6/2023.
//

#pragma once

#include "emuwindow_apple.h"

class EmuWindow_Vulkan : public EmuWindow_Apple {
public:
    EmuWindow_Vulkan(CA::MetalLayer* surface);
    ~EmuWindow_Vulkan() override = default;
    
public:
    void TryPresenting() override;
    void DonePresenting() override;
    
    void OrientationChanged(bool portrait, CA::MetalLayer* surface);
    
    std::unique_ptr<Frontend::GraphicsContext> CreateSharedContext() const override;
    
private:
    bool CreateWindowSurface() override;
};
