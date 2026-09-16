#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString * const kPath = @"/var/mobile/A510CarPlayProbe-v02.txt";

static void W(NSString *s) {
    @autoreleasepool {
        NSString *line = [NSString stringWithFormat:@"%@ | %@ | %@\n",
            [NSDate date],
            NSBundle.mainBundle.bundleIdentifier ?: @"?",
            s ?: @""];
        if (![[NSFileManager defaultManager] fileExistsAtPath:kPath])
            [@"" writeToFile:kPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSFileHandle *h=[NSFileHandle fileHandleForWritingAtPath:kPath];
        if (h) {
            [h seekToEndOfFile];
            [h writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [h closeFile];
        }
    }
}

static BOOL Interesting(NSString *name) {
    NSString *n=name.lowercaseString;
    return [n containsString:@"carplay"] ||
           [n containsString:@"scene"] ||
           [n containsString:@"display"] ||
           [n containsString:@"dashboard"];
}

static void DumpMethods(Class c) {
    if (!c) return;
    unsigned int count=0;
    Method *m=class_copyMethodList(c,&count);
    NSMutableArray *a=[NSMutableArray array];
    for (unsigned int i=0;i<count;i++) {
        NSString *s=NSStringFromSelector(method_getName(m[i]));
        if (Interesting(s)) [a addObject:s];
    }
    free(m);
    if (a.count) W([NSString stringWithFormat:@"CLASS %@ METHODS %@",NSStringFromClass(c),a]);
}

static void Snapshot(void) {
    int count=objc_getClassList(NULL,0);
    if (count<=0) return;
    Class *classes=(Class *)malloc(sizeof(Class)*count);
    count=objc_getClassList(classes,count);

    W([NSString stringWithFormat:@"=== RUNTIME SNAPSHOT classes=%d process=%@ ===",
       count, NSProcessInfo.processInfo.processName]);

    for (int i=0;i<count;i++) {
        Class c=classes[i];
        NSString *name=NSStringFromClass(c);
        if (Interesting(name)) DumpMethods(c);
    }
    free(classes);

    NSArray *targets=@[
      @"SpringBoard",
      @"SBApplicationController",
      @"SBApplication",
      @"SBDeviceApplicationSceneView",
      @"SBApplicationSceneView",
      @"FBScene",
      @"FBSScene",
      @"FBSSceneClientSettings",
      @"FBSDisplayConfiguration",
      @"CARSessionStatus",
      @"CRCarPlayAppPolicy",
      @"CRSUIClusterController",
      @"CRSUIApplicationSceneSettings"
    ];
    for (NSString *n in targets) {
        Class c=NSClassFromString(n);
        W([NSString stringWithFormat:@"TARGET %@ = %@",n,c?@"PRESENT":@"ABSENT"]);
        if (c) DumpMethods(c);
    }
}

%ctor {
    @autoreleasepool {
        W(@"PROBE v0.2 LOADED (read-only)");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5*NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            Snapshot();
        });

        [[NSNotificationCenter defaultCenter]
         addObserverForName:UISceneDidActivateNotification
         object:nil queue:NSOperationQueue.mainQueue
         usingBlock:^(NSNotification *n){
            W([NSString stringWithFormat:@"SCENE ACTIVE class=%@ desc=%@",
               NSStringFromClass([n.object class]), n.object]);
         }];
    }
}
