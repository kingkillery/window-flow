
import { AppContext } from './types';

export const DEFAULT_APPS: AppContext[] = [
  {
    id: 'cursor',
    name: 'Cursor',
    description: 'AI Code Editor',
    icon: '⌨️',
    uri: 'cursor://file',
    processName: 'Cursor.exe',
    color: 'blue',
    shortcut: 'Alt+C',
    category: 'Development',
  },
  {
    id: 'browser',
    name: 'Browser',
    description: 'Chrome / Arc',
    icon: '🌐',
    uri: 'https://google.com',
    processName: 'chrome.exe',
    color: 'orange',
    shortcut: 'Alt+B',
    category: 'Browsing',
  },
  {
    id: 'terminal',
    name: 'Terminal',
    description: 'Command Line',
    icon: '💻',
    uri: 'terminal://',
    processName: 'WindowsTerminal.exe',
    color: 'gray',
    shortcut: 'Alt+T',
    category: 'Development',
  },
  {
    id: 'spotify',
    name: 'Spotify',
    description: 'Music Player',
    icon: '🎵',
    uri: 'spotify:',
    processName: 'Spotify.exe',
    color: 'green',
    shortcut: 'Alt+S',
    category: 'Media',
  },
  {
    id: 'slack',
    name: 'Slack',
    description: 'Team Comms',
    icon: '💬',
    uri: 'slack://',
    processName: 'Slack.exe',
    color: 'purple',
    shortcut: 'Alt+L',
    category: 'Social',
  }
];

export const GEMINI_MODEL = 'gemini-2.5-flash-native-audio-preview-09-2025';

export const SYSTEM_INSTRUCTION = `
You are FocusFlow, a high-performance workflow orchestrator. 
Your job is to help the user switch contexts rapidly using voice commands.
You are connected to a dashboard that simulates window management.
When the user asks to switch to an app (e.g., "Go to Cursor", "Open Spotify"), use the 'switchContext' tool.
Be brief, professional, and efficient. Like a ship's computer.
If the user asks to create a new context, guide them to use the UI but acknowledge the request.
`;
