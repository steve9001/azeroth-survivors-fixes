// Azeroth Survivors: switch off Firefox's fullscreen and pointer-lock warnings.
//
// Install: close Firefox; copy this file into your profile folder (find it first via
// about:support > Profile Folder > Open Folder); start Firefox. Applied on every start.
// Undo: delete the file and reset the four values in about:config.
//
// The names and defaults come from Firefox's own modules/libpref/init/all.js.
user_pref("full-screen-api.warning.timeout", 0);               // default 3000 ms; 0 = never shown
user_pref("full-screen-api.warning.delay", -1);                // default 500 ms; negative = never
user_pref("full-screen-api.keyboardlock-warning.timeout", 0);  // default 4000 ms
user_pref("pointer-lock-api.warning.timeout", 0);              // default 3000 ms
