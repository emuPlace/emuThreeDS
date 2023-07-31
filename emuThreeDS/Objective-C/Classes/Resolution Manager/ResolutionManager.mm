//
//  ResolutionManager.mm
//  emuThreeDS
//
//  Created by Antique on 18/6/2023.
//

#import "ResolutionManager.h"

#include <UIKit/UIKit.h>

namespace ResolutionManager {
float Height() {
    return [[UIScreen mainScreen] nativeBounds].size.height;
}

float Width() {
    return [[UIScreen mainScreen] nativeBounds].size.width;
}
}
