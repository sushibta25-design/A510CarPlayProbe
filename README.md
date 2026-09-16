# A510CarPlayProbe v0.4

Focused logger for the next layer after CRCarPlayAppPolicy:
- _SBSCarPlayApplicationInfo
- FBScene attach/detach
- SBApplicationSceneView
- SBDeviceApplicationSceneView

It only logs original runtime behavior and does not force an app onto CarPlay.

Test at home:
1. Build/install v0.4 and respring.
2. Leave A510Player ON in CarBridge first.
3. Open A510Player on iPhone once.
4. Toggle A510 OFF -> ON in CarBridge.
5. Send /var/mobile/A510CarPlayProbe-v04.txt.

For the most useful scene-hosting evidence, repeat once while actually connected to CarPlay later.
