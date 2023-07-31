//
//  CitraWrapper.h
//  emuThreeDS
//
//  Created by Antique on 14/6/2023.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface PerformanceStatistics : NSObject
@property (nonatomic, assign) double systemFps;
@property (nonatomic, assign) double gameFps;
@property (nonatomic, assign) double frameTime;
@property (nonatomic, assign) double emulationSpeed;

-(PerformanceStatistics *) initWithSystemFps:(double)systemFps gameFps:(double)gameFps frameTime:(double)frameTime emulationSpeed:(double)emulationSpeed;
@end

@interface SaveStateInfo : NSObject
@property (nonatomic, assign) int slot;
@property (nonatomic, assign) int time;

-(SaveStateInfo *) initWithSlot:(int)slot time:(int)time;
@end


// MARK: PROTOCOLS BEGIN
@protocol ImportingProgressDelegate <NSObject>
@optional
-(void) importingProgressDidChange:(NSURL *)url received:(CGFloat)received total:(CGFloat)total;
@end

@protocol PerformanceStatisticsDelegate <NSObject>
@optional
-(void) performanceStatisticsDidChange:(PerformanceStatistics *)statistics;
@end
// MARK: PROTOCOLS END

@interface CitraWrapper : NSObject {
    uint64_t _title_id;
    NSString *_path;
    
    NSInteger *_currentTime, *_lastTime;
    
    BOOL _isRunning, _isPaused;
}

-(CitraWrapper *) init;
+(CitraWrapper *) sharedInstance NS_SWIFT_NAME(shared());


@property (nonatomic, assign, nullable) id<ImportingProgressDelegate> importingProgressDelegate;
@property (nonatomic, assign, nullable) id<PerformanceStatisticsDelegate> performanceStatisticsDelegate;


-(void) importCIAs:(NSArray<NSURL *> *)urls NS_SWIFT_NAME(importCIAs(urls:));
-(NSArray<NSString *> *) importedCIAs NS_SWIFT_NAME(importedCIAs());


-(void) prepareLayer:(CAMetalLayer *)layer NS_SWIFT_NAME(prepare(layer:));
-(void) insertRom:(NSString *)path NS_SWIFT_NAME(insert(path:));
-(void) runEmulation NS_SWIFT_NAME(run());
-(void) pauseEmulation NS_SWIFT_NAME(pause());
-(void) resumeEmulation NS_SWIFT_NAME(resume());


-(uint16_t*) GetIcon:(NSString *)path NS_SWIFT_NAME(getIcon(path:));
-(NSString *) GetPublisher:(NSString *)path NS_SWIFT_NAME(getPublisher(path:));
-(NSString *) GetRegion:(NSString *)path NS_SWIFT_NAME(getRegion(path:));
-(NSString *) GetTitle:(NSString *)path NS_SWIFT_NAME(getTitle(path:));


-(void) addCheat:(NSString *)path NS_SWIFT_NAME(addCheat(path:));
-(void) getCheats NS_SWIFT_NAME(getCheats());
-(void) removeCheat:(NSInteger)index NS_SWIFT_NAME(removeCheat(index:));
-(void) updateCheat:(NSInteger)index withPath:(NSString *)path NS_SWIFT_NAME(updateCheat(index:path:));


-(NSArray <SaveStateInfo *> *) saveStates;
-(void) loadState:(NSInteger)index;
-(void) saveState;


-(void) touchesBegan:(CGPoint)point NS_SWIFT_NAME(touchesBegan(point:));
-(void) touchesEnded NS_SWIFT_NAME(touchesEnded());
-(void) touchesMoved:(CGPoint)point NS_SWIFT_NAME(touchesMoved(point:));


-(void) orientationChanged:(UIDeviceOrientation)orientation with:(CAMetalLayer *)layer;
@end

NS_ASSUME_NONNULL_END
