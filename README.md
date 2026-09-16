# A510CarPlayProbe v0.2

Read-only runtime inventory probe for iOS 16.

Install the DEB and respring. No camera is required.
After respring, wait about 10 seconds, then optionally open the CarPlay UI if available.
Send `/var/mobile/A510CarPlayProbe-v02.txt`.

This version deliberately does NOT hook private methods or modify CarPlay behavior.
It inventories loaded classes/selectors so the next enabler can target the actual iOS 16 runtime instead of copying iOS 14 hooks.
