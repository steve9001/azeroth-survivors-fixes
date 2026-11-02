// Azeroth Survivors desktop wrapper: Chromium (via Electron) without the browser UI, so there is
// no "Press Esc to exit full screen" and no "wow.aethus.pl has control of your pointer" notice.
// Electron's handler for that notice is an empty function (shell/browser/api/
// electron_api_web_contents.cc, UpdateExclusiveAccessBubble); that is the whole trick.
//
//   start.cmd               borderless fullscreen from the start
//   start.cmd --windowed    a 1600x900 window instead
//
// Keys the wrapper handles itself: F11 (toggle fullscreen), Ctrl+Shift+I (DevTools, for
// troubleshooting), Alt+F4 (quit). Everything else, including Esc, goes to the game.

const { app, BrowserWindow, Menu, session, shell } = require('electron');

const HOME = 'https://wow.aethus.pl/';
const windowed = process.argv.includes('--windowed');

// Harmless when WebGPU is already on (it is, by default, in Chromium on Windows); it only
// bypasses the GPU blocklist if your adapter happens to be on it.
app.commandLine.appendSwitch('enable-unsafe-webgpu');

app.whenReady().then(() => {
  Menu.setApplicationMenu(null); // no menu bar, and Alt does not reveal one

  // Grant the page what the game needs, with no prompt; refuse everything else.
  session.defaultSession.setPermissionRequestHandler((_contents, permission, callback) => {
    callback(['pointerLock', 'fullscreen', 'keyboardLock'].includes(permission));
  });

  const win = new BrowserWindow({
    width: 1600,
    height: 900,
    fullscreen: !windowed,
    autoHideMenuBar: true,
    backgroundColor: '#000000',
    title: 'Azeroth Survivors',
    webPreferences: {
      backgroundThrottling: false, // keep the game at full rate when focus flickers
      // Current Electron's defaults, spelled out: the page gets no Node.js access.
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
    },
  });

  win.webContents.on('before-input-event', (event, input) => {
    if (input.type !== 'keyDown') return;
    if (input.key === 'F4' && input.alt && !input.control && !input.shift) {
      // The game swallows every key it sees (winit's web backend calls preventDefault on each
      // keydown), and in Chromium a page that cancels Alt+F4 also cancels the window close.
      // So quit here, before the page gets the key.
      event.preventDefault();
      quit();
    } else if (input.key === 'F11') {
      win.setFullScreen(!win.isFullScreen());
      event.preventDefault();
    } else if (input.control && input.shift && String(input.key).toUpperCase() === 'I') {
      win.webContents.toggleDevTools();
      event.preventDefault();
    }
  });

  // Links the game opens (Discord, the download page) go to the normal browser,
  // and the page itself never navigates away from wow.aethus.pl.
  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });
  win.webContents.on('will-navigate', (event, url) => {
    if (!url.startsWith(HOME)) {
      event.preventDefault();
      shell.openExternal(url);
    }
  });

  win.loadURL(HOME);
});

// A normal quit, so Chromium flushes localStorage (where the game keeps its save) to disk.
// If that has not finished in five seconds (a hung GPU process, say), exit hard instead of
// leaving a frozen fullscreen window behind.
function quit() {
  for (const w of BrowserWindow.getAllWindows()) w.hide();
  app.quit();
  setTimeout(() => app.exit(0), 5000).unref();
}

app.on('window-all-closed', () => quit());
