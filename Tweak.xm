#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString * const P=@"/var/mobile/A510CarPlayProbe-v05.txt";
static NSString * const T=@"com.sushibta.a510player";

static NSString *D(id x){ @try{return x?[x description]:@"nil";}@catch(__unused NSException*e){return @"<err>";}}
static BOOL H(id x){return [D(x) containsString:T];}
static void L(NSString*s){
 @autoreleasepool{
  NSString*l=[NSString stringWithFormat:@"%@ | %@ | %@ | %@\n",[NSDate date],
   NSProcessInfo.processInfo.processName?:@"?",NSBundle.mainBundle.bundleIdentifier?:@"?",s?:@""];
  if(![[NSFileManager defaultManager] fileExistsAtPath:P])
   [@"" writeToFile:P atomically:YES encoding:NSUTF8StringEncoding error:nil];
  NSFileHandle*h=[NSFileHandle fileHandleForWritingAtPath:P];
  if(h){[h seekToEndOfFile];[h writeData:[l dataUsingEncoding:NSUTF8StringEncoding]];[h closeFile];}
 }
}
static void Snap(NSString*w){
 NSDictionary*p=[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.leftyfl1p.carbridge13.plist"];
 NSArray*a=[p[@"bridgedApps"] isKindOfClass:NSArray.class]?p[@"bridgedApps"]:nil;
 L([NSString stringWithFormat:@"SNAP %@ CB=%d",w,[a containsObject:T]]);
}

%hook FBSDisplayConfiguration
- (BOOL)isCarDisplay { BOOL r=%orig; if(r)L([NSString stringWithFormat:@"DISPLAY isCarDisplay=1 %@",D(self)]); return r; }
- (BOOL)isCarInstrumentsDisplay { BOOL r=%orig; if(r)L([NSString stringWithFormat:@"DISPLAY instruments=1 %@",D(self)]); return r; }
%end

%hook FBSScene
- (id)display {
 id r=%orig;
 if(H(self)||H(r)) L([NSString stringWithFormat:@"FBSSCENE display TARGET scene=%@ display=%@",D(self),D(r)]);
 return r;
}
- (id)fbsDisplay {
 id r=%orig;
 if(H(self)||H(r)) L([NSString stringWithFormat:@"FBSSCENE fbsDisplay TARGET scene=%@ display=%@",D(self),D(r)]);
 return r;
}
%end

%hook SBApplicationSceneView
- (id)initWithSceneHandle:(id)h referenceSize:(CGSize)s contentOrientation:(NSInteger)c containerOrientation:(NSInteger)cc hostRequester:(id)rq {
 id r=%orig;
 if(H(h)||H(r)||H(rq)) L([NSString stringWithFormat:@"APPVIEW TARGET size=%@ handle=%@ requester=%@",NSStringFromCGSize(s),D(h),D(rq)]);
 return r;
}
%end

%hook SBDeviceApplicationSceneView
- (id)initWithSceneHandle:(id)h referenceSize:(CGSize)s contentOrientation:(NSInteger)c containerOrientation:(NSInteger)cc hostRequester:(id)rq {
 id r=%orig;
 if(H(h)||H(r)||H(rq)) L([NSString stringWithFormat:@"DEVICEVIEW TARGET size=%@ handle=%@ requester=%@",NSStringFromCGSize(s),D(h),D(rq)]);
 return r;
}
%end

%hook UIApplication
- (void)_connectUISceneFromFBSScene:(id)scene transitionContext:(id)ctx {
 if(H(scene)||[NSBundle.mainBundle.bundleIdentifier isEqualToString:T])
  L([NSString stringWithFormat:@"CONNECT UI SCENE scene=%@ ctx=%@",D(scene),D(ctx)]);
 %orig;
}
%end

%ctor{
 @autoreleasepool{
  L(@"A510CarPlayProbe v0.5 LOADED");
  Snap(@"startup");
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC),dispatch_get_main_queue(),^{Snap(@"after5");});
  [[NSNotificationCenter defaultCenter] addObserverForName:UISceneDidActivateNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification*n){
   if(H(n.object)||[NSBundle.mainBundle.bundleIdentifier isEqualToString:T])
    L([NSString stringWithFormat:@"UISCENE ACTIVE %@",D(n.object)]);
   Snap(@"scene-active");
  }];
 }
}
