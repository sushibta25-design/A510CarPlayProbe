#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <notify.h>

static NSString * const kProbePath = @"/var/mobile/A510CarPlayProbe.txt";

static void ProbeWrite(NSString *event) {
    @autoreleasepool {
        NSString *proc = NSProcessInfo.processInfo.processName ?: @"?";
        NSString *bundle = NSBundle.mainBundle.bundleIdentifier ?: @"?";
        NSString *line = [NSString stringWithFormat:@"%@ | process=%@ | bundle=%@ | %@\n",
                          [NSDate date], proc, bundle, event ?: @""];

        NSFileManager *fm = NSFileManager.defaultManager;
        if (![fm fileExistsAtPath:kProbePath]) {
            [@"" writeToFile:kProbePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        NSFileHandle *h = [NSFileHandle fileHandleForWritingAtPath:kProbePath];
        if (h) {
            [h seekToEndOfFile];
            [h writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [h closeFile];
        }
    }
}

static void ProbeSnapshot(NSString *why) {
    ProbeWrite([NSString stringWithFormat:@"SNAPSHOT %@", why]);

    NSArray *roots = @[
        @"/var/mobile/Library/Preferences",
        @"/var/jb/var/mobile/Library/Preferences"
    ];
    NSFileManager *fm = NSFileManager.defaultManager;
    for (NSString *dir in roots) {
        NSArray *files = [fm contentsOfDirectoryAtPath:dir error:nil];
        for (NSString *name in files) {
            NSString *lower = name.lowercaseString;
            if ([lower containsString:@"carbridge"] ||
                [lower containsString:@"carplay"] ||
                [lower containsString:@"a510"]) {
                NSString *full = [dir stringByAppendingPathComponent:name];
                NSDictionary *attrs = [fm attributesOfItemAtPath:full error:nil];
                ProbeWrite([NSString stringWithFormat:@"PREF %@ modified=%@ size=%@",
                            full,
                            attrs[NSFileModificationDate] ?: @"?",
                            attrs[NSFileSize] ?: @"?"]);
            }
        }
    }
}

%hook UIApplication

- (void)didAddSubview:(UIView *)view {
    %orig;
}

%end

%ctor {
    @autoreleasepool {
        ProbeWrite(@"=== PROBE LOADED ===");
        ProbeSnapshot(@"startup");

        int token = 0;
        notify_register_dispatch("com.apple.springboard.lockstate", &token,
                                 dispatch_get_main_queue(), ^(int t) {
            ProbeSnapshot(@"springboard.lockstate");
        });

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:NSOperationQueue.mainQueue
                    usingBlock:^(NSNotification *n) {
            ProbeSnapshot(@"UIApplicationDidBecomeActive");
        }];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationWillResignActiveNotification
                        object:nil
                         queue:NSOperationQueue.mainQueue
                    usingBlock:^(NSNotification *n) {
            ProbeSnapshot(@"UIApplicationWillResignActive");
        }];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UISceneDidActivateNotification
                        object:nil
                         queue:NSOperationQueue.mainQueue
                    usingBlock:^(NSNotification *n) {
            ProbeWrite([NSString stringWithFormat:@"SCENE ACTIVE %@", n.object]);
            ProbeSnapshot(@"scene-active");
        }];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UISceneWillDeactivateNotification
                        object:nil
                         queue:NSOperationQueue.mainQueue
                    usingBlock:^(NSNotification *n) {
            ProbeWrite([NSString stringWithFormat:@"SCENE DEACTIVATE %@", n.object]);
            ProbeSnapshot(@"scene-deactivate");
        }];
    }
}
