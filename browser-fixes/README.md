# Azeroth Survivors in a browser, without the fullscreen and mouse-capture overlays

For Windows 11. Everything here targets the live game at https://wow.aethus.pl/ and changes
nothing about the game itself; it only changes what is wrapped around it.

## The problem, in two sentences

Edge and Chrome draw two notices over any page that goes fullscreen or captures the mouse:
"Press Esc to exit full screen" and "wow.aethus.pl has control of your pointer". They are one
Chromium feature (the "exclusive access bubble"), there is no setting, flag or policy to turn it
off, and the game re-triggers it because pressing Esc for the game menu releases the mouse and
the next click captures it again.

## What is in this folder

| path | what | fixes |
|---|---|---|
| `electron-wrapper/` | the game in a Chromium window with no browser UI at all | both overlays (recommended) |
| `kiosk/edge-kiosk.cmd`, `kiosk/chrome-kiosk.cmd` | Edge or Chrome in kiosk mode, one double-click | the fullscreen notice only |
| `firefox/user.js` | Firefox preferences that switch both warnings off | both, but the game is known to struggle in Firefox |

Try them in that order. Option A takes about five minutes the first time; B is a thirty-second
experiment; C is the fallback.

---

## Option A (recommended): the Electron wrapper

### Why it works

Electron is Chromium without the browser. The code path that shows the two notices is an
empty function in Electron (`UpdateExclusiveAccessBubble` in
`shell/browser/api/electron_api_web_contents.cc`), mouse capture is granted silently, and WebGPU
is on by default on Windows exactly as in Chrome, since it is the same engine. The game's own
page script only refuses to run when it is framed or served from another host; a plain top-level
load of the real URL passes that check, so the wrapper plays the real site, saves included.

### Setup (once)

1. Copy the whole `electron-wrapper` folder somewhere on the PC, for example
   `C:\Games\AzerothSurvivors\`. Any folder works; avoid OneDrive-synced folders, which fight
   with `node_modules`.
2. Double-click **`setup.cmd`**.
   - If Node.js is not installed, it installs Node.js LTS with `winget` (Windows' built-in
     package manager) and then tells you to close the window and run `setup.cmd` again. The
     second run is needed because a new window picks up the updated PATH.
   - It then runs `npm install` and Electron's own `install.js`, which download Electron (about
     100 MB) into a `node_modules` folder next to the scripts. Nothing is installed system-wide apart from Node.js.
3. Double-click **`start.cmd`**. The game opens borderless fullscreen.

If SmartScreen complains about `setup.cmd` or `start.cmd`, that is the generic warning for any
script downloaded from the internet: "More info" then "Run anyway". Both files are short and
readable in Notepad.

### Using it

| key | does |
|---|---|
| **F11** | toggle fullscreen / window |
| **Alt+F4** | quit |
| **Esc** | goes to the game only; it never leaves fullscreen |
| **Ctrl+Shift+I** | Chromium DevTools, for troubleshooting only |

- `start.cmd --windowed` starts in a 1600x900 window instead of fullscreen.
- Links the game opens (Discord, the Windows download) open in your normal browser.
- A desktop shortcut: right-click `start.cmd`, **Send to**, **Desktop (create shortcut)**.
  You can rename it and give it an icon in the shortcut's Properties.
- Game updates arrive automatically: the wrapper loads the live site every time. To update
  Electron itself, run `setup.cmd` again (it runs `npm install`, which keeps `electron`
  at the newest release).

### Moving your save from Edge

The wrapper has its own browser profile, so it starts with no progress. The game has an
export/import of its own:

1. In Edge, in the game: **Options > Saves**, download the save. You get a file named like
   `AzerothSurvivors 2026-10-29 20-15-03.sav`.
2. In the wrapper, in the game: **Options > Saves > Import Save**, pick that file, confirm.

### Troubleshooting

- **"This browser has no WebGPU"** on a capable PC usually means the game landed on the wrong GPU
  or the driver is old. Windows **Settings > System > Display > Graphics**, add
  `electron-wrapper\node_modules\electron\dist\electron.exe`, set it to **High performance**,
  then restart the wrapper. Update the GPU driver if that is not enough. You can confirm WebGPU
  from DevTools (Ctrl+Shift+I, Console tab) with `!!navigator.gpu`, which should print `true`.
- **A black window and nothing else**: wait; the first load pulls a lot of data. If it stays
  black, open DevTools and read the Console; the game prints what it is doing.
- **"Too many people are playing!!!"**: the site's own daily request cap, not the wrapper.
  Try again later.
- **Fullscreen got lost after pressing Esc**: press F11.
- **`setup.cmd` says winget is not recognised**: install "App Installer" from the Microsoft
  Store, or install Node.js LTS by hand from https://nodejs.org/ and run `setup.cmd` again.

### What the wrapper does and does not do

`main.js` is under 100 lines and worth reading. It loads one URL, grants the page exactly three
permissions (mouse capture, fullscreen, keyboard lock), refuses everything else, blocks
navigation away from wow.aethus.pl, and gives the page no Node.js access (`nodeIntegration`
off, `contextIsolation` and `sandbox` on). It phones home to nothing. The only downloads are
`setup.cmd`'s: Node.js from winget's Microsoft-curated source and Electron from the npm
registry, which fetches the Electron binary from the Electron project's GitHub releases.

---

## Option B: Edge or Chrome in kiosk mode (quick, partial)

Chromium's source skips the "Press Esc to exit full screen" notice when the browser runs in
kiosk mode (`IsRunningInAppMode()` in
`chrome/browser/ui/exclusive_access/exclusive_access_manager.cc`). It does **not** skip the
"has control of your pointer" notice, which will still appear after each time you press Esc.
So this removes the more frequent of the two nags, not both.

1. Double-click `kiosk\edge-kiosk.cmd` (or `chrome-kiosk.cmd`).
2. Play. **Esc** will not leave fullscreen in kiosk mode; **Alt+F4** quits.

Notes:

- The script starts the browser with its own profile folder
  (`%LocalAppData%\AzerothSurvivors\edge-kiosk`) so it always starts cleanly even when Edge is
  already open with your normal profile. That means a separate save; move it with
  Options > Saves as described above. If you would rather use your normal profile, delete the
  `--user-data-dir=...` part of the command and close every Edge window before running it.
- Edge's kiosk mode also hides the address bar and tabs; that is the point.

---

## Option C: Firefox with the warnings switched off

Firefox has real preferences for both warnings. They are in Firefox's own preference list
(`modules/libpref/init/all.js`):

| preference | default | set to |
|---|---|---|
| `full-screen-api.warning.timeout` | 3000 | `0` |
| `full-screen-api.warning.delay` | 500 | `-1` |
| `full-screen-api.keyboardlock-warning.timeout` | 4000 | `0` |
| `pointer-lock-api.warning.timeout` | 3000 | `0` |

Two ways to apply them:

- **`user.js`** (portable): close Firefox, open `about:support` beforehand to find
  **Profile Folder > Open Folder**, copy `firefox\user.js` into that folder, start Firefox.
  Firefox applies the file on every start; delete it to undo.
- **By hand**: `about:config`, search each name, set the value.

Firefox has had WebGPU on Windows since version 141 (July 2025), so the game can start there.
Two caveats, both from the game's own code and page: the site lists Chrome, Edge and Safari as
the browsers to use, not Firefox, and its script carries a note that Firefox players lost the GPU
device with an out-of-memory error at 14 to 16 GB after about five minutes. Treat Firefox as the
fallback, not the plan.

---

## What does not work (so you do not spend time on it)

- **Edge or Chrome settings, `edge://flags`, group policy**: nothing controls this bubble.
  Vivaldi's and Opera's forums say the same for every Chromium browser.
- **"Install this site as an app" in Edge (a PWA)**: still Edge's UI, same two notices.
- **Wrappers built on WebView2** (Pake, Tauri on Windows, anything "Edge WebView"): WebView2
  shows the same pointer notice and Microsoft has said there is no way to hide it
  (WebView2Feedback discussion #4050).
- **"Disable Pointer Lock" browser extensions**: they stop the notice by refusing mouse capture,
  which breaks the game's camera.
- The native Windows download on the site avoids all of this, but it is an unsigned binary with
  no published checksum; that is a separate decision.

## For the curious: why the notices behave the way they do

From Chromium's source (`chrome/browser/ui/exclusive_access/`): the bubble shows for 3.8 s on
every fullscreen or pointer-lock state change, and re-arms itself after 15 minutes without
input. Chromium re-captures the mouse silently only when the *page* released it; when *you*
pressed Esc, the next capture shows the notice again. That is why a game whose menu key is Esc
triggers it so often. Kiosk mode suppresses only the fullscreen-exit text. Electron inherits all
of this machinery but implements the "show the bubble" call as a no-op, which is why Option A
removes both at once.

Sources:
- Chromium: https://source.chromium.org/chromium/chromium/src/+/main:chrome/browser/ui/exclusive_access/exclusive_access_manager.cc
- Electron: https://github.com/electron/electron/blob/main/shell/browser/api/electron_api_web_contents.cc (search `UpdateExclusiveAccessBubble`)
- WebView2 cannot hide it: https://github.com/MicrosoftEdge/WebView2Feedback/discussions/4050
- Firefox prefs: https://support.mozilla.org/en-US/questions/1179622
- Firefox 141 WebGPU on Windows: https://www.gigazine.net/gsc_news/en/20250723-firefox-141
- Vivaldi forum, no Chromium switch: https://forum.vivaldi.net/topic/95942/how-an-i-can-disable-press-esc-to-exit-full-screen-mode
