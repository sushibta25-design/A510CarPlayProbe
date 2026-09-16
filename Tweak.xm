#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString * const P = @"/var/mobile/A510CarPlayProbe-v06.txt";
static NSString * const T = @"com.sushibta.a510player";

static void L(NSString *s) {
    @autoreleasepool {
        NSString *line = [NSString stringWithFormat:@"%@ | %@ | %@ | %@\n",
            [NSDate date],
            NSProcessInfo.processInfo.processName ?: @"?",
            NSBundle.mainBundle.bundleIdentifier ?: @"?",
            s ?: @""];
        if (![[NSFileManager defaultManager] fileExistsAtPath:P]) {
            [@"" writeToFile:P atomically:YES
                    encoding:NSUTF8StringEncoding error:nil];
        }
        NSFileHandle *h = [NSFileHandle fileHandleForWritingAtPath:P];
        if (h) {
            [h seekToEndOfFile];
            [h writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [h closeFile];
        }
    }
}

static void Snap(NSString *why) {
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.leftyfl1p.carbridge13.plist"];
    NSArray *a = [p[@"bridgedApps"] isKindOfClass:NSArray.class] ?
                  p[@"bridgedApps"] : nil;

    UIApplication *app = UIApplication.sharedApplication;
    NSMutableArray *scenes = [NSMutableArray array];

    for (UIScene *scene in app.connectedScenes) {
        NSString *role = scene.session.role ?: @"?";
        NSString *sid = scene.session.persistentIdentifier ?: @"?";
        NSString *state = [NSString stringWithFormat:@"%ld",
                           (long)scene.activationState];
        [scenes addObject:[NSString stringWithFormat:
            @"{%@ role=%@ state=%@}", sid, role, state]];
    }

    L([NSString stringWithFormat:
       @"SNAP %@ CB=%d scenes=%@",
       why, [a containsObject:T], scenes]);
}

%ctor {
    @autoreleasepool {
        L(@"A510CarPlayProbe v0.6 SAFE LOADED");

        dispatch_async(dispatch_get_main_queue(), ^{
            Snap(@"startup");

            NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;

            [nc addObserverForName:UISceneWillConnectNotification
                            object:nil
                             queue:NSOperationQueue.mainQueue
                        usingBlock:^(NSNotification *n) {
                L([NSString stringWithFormat:@"UIScene WILL CONNECT %@", n.object]);
                Snap(@"will-connect");
            }];

            [nc addObserverForName:UISceneDidActivateNotification
                            object:nil
                             queue:NSOperationQueue.mainQueue
                        usingBlock:^(NSNotification *n) {
                L([NSString stringWithFormat:@"UIScene DID ACTIVATE %@", n.object]);
                Snap(@"did-activate");
            }];

            [nc addObserverForName:UISceneWillDeactivateNotification
                            object:nil
                             queue:NSOperationQueue.mainQueue
                        usingBlock:^(NSNotification *n) {
                L([NSString stringWithFormat:@"UIScene WILL DEACTIVATE %@", n.object]);
                Snap(@"will-deactivate");
            }];

            [nc addObserverForName:UISceneDidDisconnectNotification
                            object:nil
                             queue:NSOperationQueue.mainQueue
                        usingBlock:^(NSNotification *n) {
                L([NSString stringWithFormat:@"UIScene DID DISCONNECT %@", n.object]);
                Snap(@"did-disconnect");
            }];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         5 * NSEC_PER_SEC),
                           dispatch_get_main_queue(), ^{
                Snap(@"after5");
            });
        });
    }
}
