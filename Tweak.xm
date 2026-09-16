#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString * const kLogPath=@"/var/mobile/A510CarPlayProbe-v04.txt";
static NSString * const kTarget=@"com.sushibta.a510player";

static void L(NSString *s) {
    @autoreleasepool {
        NSString *line=[NSString stringWithFormat:@"%@ | %@ | %@ | %@\n",
            [NSDate date], NSProcessInfo.processInfo.processName ?: @"?",
            NSBundle.mainBundle.bundleIdentifier ?: @"?", s ?: @""];
        if (![[NSFileManager defaultManager] fileExistsAtPath:kLogPath])
            [@"" writeToFile:kLogPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSFileHandle *h=[NSFileHandle fileHandleForWritingAtPath:kLogPath];
        if (h) { [h seekToEndOfFile]; [h writeData:[line dataUsingEncoding:NSUTF8StringEncoding]]; [h closeFile]; }
    }
}

static NSString *D(id o) {
    @try { return o ? [o description] : @"nil"; }
    @catch (__unused NSException *e) { return @"<desc threw>"; }
}
static BOOL HasTarget(id o) { return [D(o) containsString:kTarget]; }

static void Snapshot(NSString *why) {
    NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.leftyfl1p.carbridge13.plist"];
    NSArray *a=[p[@"bridgedApps"] isKindOfClass:NSArray.class] ? p[@"bridgedApps"] : nil;
    L([NSString stringWithFormat:@"SNAPSHOT %@ CBtarget=%d classes: _SBSCarPlayApplicationInfo=%d FBScene=%d SBApplicationSceneView=%d SBDeviceApplicationSceneView=%d",
       why,[a containsObject:kTarget],
       NSClassFromString(@"_SBSCarPlayApplicationInfo")!=Nil,
       NSClassFromString(@"FBScene")!=Nil,
       NSClassFromString(@"SBApplicationSceneView")!=Nil,
       NSClassFromString(@"SBDeviceApplicationSceneView")!=Nil]);
}

%hook _SBSCarPlayApplicationInfo
- (NSString *)localizedDisplayName {
    NSString *r=%orig;
    if (HasTarget(self) || [r.lowercaseString containsString:@"a510"])
        L([NSString stringWithFormat:@"CARPLAYINFO localizedDisplayName=%@ self=%@",r,D(self)]);
    return r;
}
- (void)setLocalizedDisplayName:(NSString *)v {
    if (HasTarget(self) || [v.lowercaseString containsString:@"a510"])
        L([NSString stringWithFormat:@"CARPLAYINFO setLocalizedDisplayName=%@ self=%@",v,D(self)]);
    %orig;
}
%end

%hook FBScene
- (id)init {
    id r=%orig;
    if (HasTarget(r)) L([NSString stringWithFormat:@"FBSCENE init TARGET %@",D(r)]);
    return r;
}
- (void)attachSceneContext:(id)ctx {
    if (HasTarget(self) || HasTarget(ctx))
        L([NSString stringWithFormat:@"FBSCENE attach TARGET self=%@ ctx=%@",D(self),D(ctx)]);
    %orig;
}
- (void)detachSceneContext:(id)ctx {
    if (HasTarget(self) || HasTarget(ctx))
        L([NSString stringWithFormat:@"FBSCENE detach TARGET self=%@ ctx=%@",D(self),D(ctx)]);
    %orig;
}
%end

%hook SBApplicationSceneView
- (id)initWithSceneHandle:(id)handle referenceSize:(CGSize)size contentOrientation:(NSInteger)co containerOrientation:(NSInteger)cto hostRequester:(id)requester {
    id r=%orig;
    if (HasTarget(handle) || HasTarget(requester) || HasTarget(r))
        L([NSString stringWithFormat:@"SBApplicationSceneView TARGET handle=%@ size=%@ requester=%@",
           D(handle),NSStringFromCGSize(size),D(requester)]);
    return r;
}
%end

%hook SBDeviceApplicationSceneView
- (id)initWithSceneHandle:(id)handle referenceSize:(CGSize)size contentOrientation:(NSInteger)co containerOrientation:(NSInteger)cto hostRequester:(id)requester {
    id r=%orig;
    if (HasTarget(handle) || HasTarget(requester) || HasTarget(r))
        L([NSString stringWithFormat:@"SBDeviceApplicationSceneView TARGET handle=%@ size=%@ requester=%@",
           D(handle),NSStringFromCGSize(size),D(requester)]);
    return r;
}
%end

%ctor {
    @autoreleasepool {
        L(@"A510CarPlayProbe v0.4 LOADED");
        Snapshot(@"startup");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC),dispatch_get_main_queue(),^{ Snapshot(@"after5"); });
        [[NSNotificationCenter defaultCenter] addObserverForName:UISceneDidActivateNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *n){
            if (HasTarget(n.object)) L([NSString stringWithFormat:@"UISCENE TARGET %@",D(n.object)]);
            Snapshot(@"scene-active");
        }];
    }
}
