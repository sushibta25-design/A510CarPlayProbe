# A510CarPlayProbe v0.3

Focused read-only-ish diagnostic probe: it hooks CRCarPlayAppPolicy getters/setters
only to log their original values; it does not change the returned values.

Test:
1. Install v0.3 DEB and respring.
2. Keep A510Player unticked in CarBridge, open/close CarBridge once.
3. Tick A510Player, open/close CarBridge once.
4. If CarPlay is available, connect it and repeat OFF/ON once.
5. Send /var/mobile/A510CarPlayProbe-v03.txt

Target bundle: com.sushibta.a510player
