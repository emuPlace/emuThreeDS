//
//  InputBridge.h
//  emuThreeDS
//
//  Created by Antique on 20/6/2023.
//

#pragma once

#ifdef __cplusplus
#include "core/frontend/input.h"

template <typename StatusType>
class ButtonBridge : public Input::InputDevice<StatusType> {
public:
    std::atomic<StatusType> current_value;

    ButtonBridge(StatusType initial_value) {
        current_value = initial_value;
    }

    StatusType GetStatus() const {
        return current_value;
    }
};

struct Float2D {
    float x;
    float y;
};

class AnalogBridge : public Input::InputDevice<std::tuple<float, float>> {
public:
    std::atomic<Float2D> current_value;

    AnalogBridge(Float2D initial_value) {
        current_value = initial_value;
    }

    std::tuple<float, float> GetStatus() const {
        Float2D cv = current_value.load();
        return { cv.x, cv.y };
    }
};
#endif

#import <Foundation/Foundation.h>
#import <GameController/GameController.h>

NS_ASSUME_NONNULL_BEGIN
@interface ButtonInputBridge: NSObject
-(ButtonInputBridge *) init;
-(void) pressChangedHandler:(GCControllerButtonInput * _Nullable)input value:(float)value pressed:(BOOL)pressed;

#ifdef __cplusplus
-(ButtonBridge<bool> *) getCppBridge;
#endif
@end

@interface AnalogInputBridge: NSObject
-(AnalogInputBridge *) init;
-(void) valueChangedHandler:(GCControllerDirectionPad * _Nullable)input x:(float)xValue y:(float)yValue;

#ifdef __cplusplus
-(AnalogBridge *) getCppBridge;
#endif
@end
NS_ASSUME_NONNULL_END
