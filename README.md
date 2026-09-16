# A510CarPlayProbe v0.5.1
Use this build for the in-car test.

1. Install and respring before connecting CarPlay.
2. Leave A510Player OFF in CarBridge and connect wired CarPlay.
3. Wait 10 sec; try to find/open A510Player (expected absent).
4. Tick A510Player ON in CarBridge.
5. Return to CarPlay, wait 10 sec, open A510Player from CarPlay.
6. Keep it open 10 sec, then return Home.
7. Send /var/mobile/A510CarPlayProbe-v05.txt.

Do not delete the log between OFF and ON.

Build fix: removed the direct FBSDisplayConfiguration isCarDisplay hook that caused the Logos parse error.
