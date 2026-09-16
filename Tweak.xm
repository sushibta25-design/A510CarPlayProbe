#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface NSObject (A510CarPlayProbePolicy)
- (BOOL)isCarPlaySupported;
- (BOOL)canDisplayOnCarScreen;
@end

static NSString * const kLogPath = @"/var/mobile/A510CarPlayProbe-v03.txt";
static NSString * const kTargetBundle = @"com.sushibta.a510player";

static void PLog(NSString *msg) {
    @autoreleasepool {
        NSString *line = [NSString stringWithFormat:@"%@ | proc=%@ | bundle=%@ | %@\n",
                          [NSDate date],
                          NSProcessInfo.processInfo.processName ?: @"?",
                          NSBundle.mainBundle.bundleIdentifier ?: @"?",
                          msg ?: @""];
        if (![[NSFileManager defaultManager] fileExistsAtPath:kLogPath]) {
            [@"" writeToFile:kLogPath atomically:YES
                    encoding:NSUTF8StringEncoding error:nil];
        }
        NSFileHandle *h = [NSFileHandle fileHandleForWritingAtPath:kLogPath];
        if (h) {
            [h seekToEndOfFile];
            [h writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [h closeFile];
        }
    }
}

static NSString *SafeDesc(id obj) {
    @try { return obj ? [obj description] : @"nil"; }
    @catch (__unused NSException *e) { return @"<description threw>"; }
}

static NSString *FindTargetBundleInObject(id obj) {
    if (!obj) return nil;
    NSString *d = SafeDesc(obj);
    return [d containsString:kTargetBundle] ? kTargetBundle : nil;
}

static void LogPolicyObject(id obj, NSString *where) {
    if (!obj) return;
    Class c = object_getClass(obj);
    if (!c) return;
    if (![NSStringFromClass([obj class]) containsString:@"CRCarPlayAppPolicy"]) return;

    BOOL supported = NO, display = NO;
    @try {
        if ([obj respondsToSelector:@selector(isCarPlaySupported)])
            supported = [obj isCarPlaySupported];
        if ([obj respondsToSelector:@selector(canDisplayOnCarScreen)])
            display = [obj canDisplayOnCarScreen];
    } @catch (__unused NSException *e) {}

    NSString *target = FindTargetBundleInObject(obj);
    PLog([NSString stringWithFormat:
          @"POLICY %@ class=%@ targetInDesc=%@ supported=%d display=%d desc=%@",
          where, NSStringFromClass([obj class]), target ?: @"NO",
          supported, display, SafeDesc(obj)]);
}

static void Snapshot(NSString *why) {
    PLog([NSString stringWithFormat:@"=== SNAPSHOT %@ ===", why]);

    Class policy = NSClassFromString(@"CRCarPlayAppPolicy");
    PLog([NSString stringWithFormat:@"CRCarPlayAppPolicy=%@",
          policy ? @"PRESENT" : @"ABSENT"]);

    NSString *pref = @"/var/mobile/Library/Preferences/com.leftyfl1p.carbridge13.plist";
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:pref];
    id bridged = d[@"bridgedApps"];
    BOOL enabled = [bridged isKindOfClass:[NSArray class]] &&
                   [(NSArray *)bridged containsObject:kTargetBundle];
    PLog([NSString stringWithFormat:@"CARBRIDGE bridgedApps target=%d value=%@",
          enabled, bridged ?: @"nil"]);
}

%hook CRCarPlayAppPolicy

- (BOOL)isCarPlaySupported {
    BOOL r = %orig;
    LogPolicyObject(self, [NSString stringWithFormat:@"isCarPlaySupported -> %d", r]);
    return r;
}

- (BOOL)canDisplayOnCarScreen {
    BOOL r = %orig;
    LogPolicyObject(self, [NSString stringWithFormat:@"canDisplayOnCarScreen -> %d", r]);
    return r;
}

- (void)setCarPlaySupported:(BOOL)v {
    PLog([NSString stringWithFormat:@"POLICY setCarPlaySupported:%d self=%@", v, SafeDesc(self)]);
    %orig;
    LogPolicyObject(self, @"after setCarPlaySupported");
}

- (void)setCanDisplayOnCarScreen:(BOOL)v {
    PLog([NSString stringWithFormat:@"POLICY setCanDisplayOnCarScreen:%d self=%@", v, SafeDesc(self)]);
    %orig;
    LogPolicyObject(self, @"after setCanDisplayOnCarScreen");
}

%end

%ctor {
    @autoreleasepool {
        PLog(@"A510CarPlayProbe v0.3 LOADED");
        Snapshot(@"startup");

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5*NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            Snapshot(@"after-5s");
        });

        [[NSNotificationCenter defaultCenter]
         addObserverForName:UIApplicationDidBecomeActiveNotification
         object:nil queue:NSOperationQueue.mainQueue
         usingBlock:^(__unused NSNotification *n) {
            Snapshot(@"UIApplicationDidBecomeActive");
        }];

        [[NSNotificationCenter defaultCenter]
         addObserverForName:UISceneDidActivateNotification
         object:nil queue:NSOperationQueue.mainQueue
         usingBlock:^(NSNotification *n) {
            PLog([NSString stringWithFormat:@"SCENE ACTIVE %@", SafeDesc(n.object)]);
            Snapshot(@"scene-active");
        }];
    }
}
