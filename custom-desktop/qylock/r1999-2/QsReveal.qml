// Loaded only under the Quickshell lock (Main.qml gates it): sends a verb to
// the unlock-reveal overlay. Kept apart so a real SDDM greeter never imports
// Quickshell.
import QtQuick
import Quickshell

QtObject {
    function run(verb) {
        Quickshell.execDetached(["qs", "-p", Quickshell.env("HOME") + "/.config/custom-desktop/unlock-reveal", "ipc", "call", "reveal", verb])
    }
}
