# Hands-on Solo qualification

These checks deliberately change hardware state or interrupt audio. Perform them
when you can hear/observe the result and restore your intended settings afterward.

Record plugin commit, kernel, firmware and the result of each step. The current
read-only snapshot command is `./bin/scarlett-helper --once`.

1. Note all initial states, including Remember 48V. Open the plugin and use the interface indicators or a read-only ALSA snapshot
   as a second observer.
2. Change Air, Line/Inst and direct monitoring individually. Check the interface
   indicators and the observed sound/other UI where appropriate, then restore.
3. Test 48V only when appropriate for connected equipment. Verify the current
   power switch separately from the Remember 48V startup preference.
4. Press the physical buttons individually and check that the open plugin follows
   the device without reopening. Restore the desired states.
5. Leave the popup open and unplug the interface. Confirm controls become
   unavailable. Reconnect and confirm actual hardware state is shown, with no
   settings automatically written by the plugin. Repeat with the popup closed.
6. For startup persistence, choose an intended 48V state and preference, power
   cycle deliberately, and verify the resulting state matches that preference.
   Restore the original preference and intended power state afterward.
7. Change the system theme and test the popup on the available monitors. Record
   anything clipped, misplaced or inconsistent. The automated UI smoke test
   exercises shared palette updates but does not replace this desktop check.

Multiple-device and permission-denied qualification require an appropriate test
setup. Do not change system sound-device permissions merely to complete a report.
