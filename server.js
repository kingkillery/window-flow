const express = require('express');
const { exec } = require('child_process');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

const AHK_PATH = '"C:\\Program Files\\AutoHotkey\\AutoHotkey.exe"';
const SCRIPT_PATH = path.join(__dirname, 'control.ahk');

console.log("FocusFlow Backend initializing...");

app.post('/focus', (req, res) => {
  const { processName, appName } = req.body;
  
  if (!processName) {
    return res.status(400).send('Missing processName');
  }

  console.log(`[FocusFlow] Switching to: ${appName} (${processName})`);
  
  // Execute AHK script
  const command = `${AHK_PATH} "${SCRIPT_PATH}" "${processName}"`;
  
  exec(command, (error, stdout, stderr) => {
    if (error) {
      console.error(`exec error: ${error}`);
      // We don't fail hard here because sometimes AHK returns non-zero even if it worked, 
      // or if the window wasn't found we want to know.
      return res.status(500).json({ status: 'error', message: 'AHK execution failed or window not found' });
    }
    console.log(`stdout: ${stdout}`);
    res.json({ status: 'success', message: 'Window focus requested' });
  });
});

app.get('/health', (req, res) => res.send('OK'));

const PORT = 3001;
app.listen(PORT, () => {
  console.log(`FocusFlow Local Server running on port ${PORT}`);
  console.log(`Make sure 'control.ahk' is in the same directory.`);
});