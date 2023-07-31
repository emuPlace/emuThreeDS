//
//  DirectoryManager.mm
//  emuThreeDS
//
//  Created by Antique on 14/6/2023.
//

#import "DirectoryManager.h"

#include <Foundation/Foundation.h>

namespace DirectoryManager {
const char* BundleDirectory() {
    return [[[NSURL fileURLWithPath:[[NSBundle mainBundle] privateFrameworksPath]] path] UTF8String];
}

const char* DocumentsDirectory() {
    return [[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject] path] UTF8String];
}
}
