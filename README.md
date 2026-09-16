# A510CarPlayProbe

Rootless diagnostic tweak. No NewTerm commands are required.

After installing and respringing:
1. Open CarBridge.
2. Untick A510Player, wait a few seconds.
3. Tick A510Player, wait a few seconds.
4. Connect/disconnect CarPlay or open A510Player if useful.
5. In Filza open `/var/mobile/A510CarPlayProbe.txt` and send that file.

This first probe records process/scene lifecycle and timestamps/sizes of preference files whose names contain CarBridge, CarPlay, or A510. It does not modify CarBridge.
