//
//  InputFactory.mm
//  emuThreeDS
//
//  Created by Antique on 20/6/2023.
//

#import "InputBridge.h"
#import "InputFactory.h"

#include "emuThreeDS-Swift.h"
@class EmulationInput;

std::unique_ptr<Input::AnalogDevice> AnalogFactory::Create(const Common::ParamPackage& params) {
    int button_id = params.Get("code", 0);
    AnalogInputBridge* emuInput = nullptr;
    switch ((Settings::NativeAnalog::Values)button_id) {
        case Settings::NativeAnalog::CirclePad:
            emuInput = EmulationInput.leftThumbstick;
            break;
        case Settings::NativeAnalog::CStick:
            emuInput = EmulationInput.rightThumstick;
            break;
        case Settings::NativeAnalog::NumAnalogs:
            UNREACHABLE();
            break;
    }
    
    if (emuInput == nullptr)
        return {};
    return std::unique_ptr<AnalogBridge>([emuInput getCppBridge]);
}

std::unique_ptr<Input::ButtonDevice> ButtonFactory::Create(const Common::ParamPackage& params) {
    int button_id = params.Get("code", 0);
    ButtonInputBridge* emuInput = nullptr;
    switch ((Settings::NativeButton::Values)button_id) {
        case Settings::NativeButton::A:
            emuInput = EmulationInput.buttonA;
            break;
        case Settings::NativeButton::B:
            emuInput = EmulationInput.buttonB;
            break;
        case Settings::NativeButton::X:
            emuInput = EmulationInput.buttonX;
            break;
        case Settings::NativeButton::Y:
            emuInput = EmulationInput.buttonY;
            break;
        case Settings::NativeButton::Up:
            emuInput = EmulationInput.dpadUp;
            break;
        case Settings::NativeButton::Down:
            emuInput = EmulationInput.dpadDown;
            break;
        case Settings::NativeButton::Left:
            emuInput = EmulationInput.dpadLeft;
            break;
        case Settings::NativeButton::Right:
            emuInput = EmulationInput.dpadRight;
            break;
        case Settings::NativeButton::L:
            emuInput = EmulationInput.buttonL;
            break;
        case Settings::NativeButton::R:
            emuInput = EmulationInput.buttonR;
            break;
        case Settings::NativeButton::Start:
            emuInput = EmulationInput.buttonStart;
            break;
        case Settings::NativeButton::Select:
            emuInput = EmulationInput.buttonSelect;
            break;
        case Settings::NativeButton::ZL:
            emuInput = EmulationInput.buttonZL;
            break;
        case Settings::NativeButton::ZR:
            emuInput = EmulationInput.buttonZR;
            break;
        case Settings::NativeButton::Debug:
        case Settings::NativeButton::Gpio14:
        case Settings::NativeButton::Home:
        case Settings::NativeButton::NumButtons:
            emuInput = EmulationInput._dummy;
    }
    
    if (emuInput == nullptr)
        return {};
    return std::unique_ptr<ButtonBridge<bool>>([emuInput getCppBridge]);
}
