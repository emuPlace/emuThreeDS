//
//  InputBridge.mm
//  emuThreeDS
//
//  Created by Antique on 20/6/2023.
//

#import "InputBridge.h"

@implementation ButtonInputBridge {
    ButtonBridge<bool>* _cppBridge;
}

-(ButtonInputBridge *) init {
    if(self = [super init]) {
        _cppBridge = new ButtonBridge<bool>(false);
    } return self;
}

-(void) pressChangedHandler:(GCControllerButtonInput * _Nullable)input value:(float)value pressed:(BOOL)pressed {
    _cppBridge->current_value = pressed;
}

-(ButtonBridge<bool> *) getCppBridge {
    return _cppBridge;
}
@end


@implementation AnalogInputBridge {
    AnalogBridge* _cppBridge;
}

-(AnalogInputBridge *) init {
    if (self = [super init]) {
        _cppBridge = new AnalogBridge(Float2D{0, 0});
    } return self;
}

-(void) valueChangedHandler:(GCControllerDirectionPad * _Nullable)input x:(float)xValue y:(float)yValue {
    _cppBridge->current_value.exchange(Float2D{xValue, yValue});
}

-(AnalogBridge *) getCppBridge {
    return _cppBridge;
}
@end
