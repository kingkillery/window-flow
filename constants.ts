
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

export const RELACE_TOOL_DESCRIPTION = `Use this tool to propose an edit to an existing file or create a new file. If you are performing an edit follow these formatting rules:
- Abbreviate sections of the code in your response that will remain the same by replacing those sections with a comment like "// ... rest of code ...", "// ... keep existing code ...", "// ... code remains the same".
- Be precise with the location of these comments within your edit snippet. A less intelligent model will use the context clues you provide to accurately merge your edit snippet.
- If applicable, it can help to include some concise information about the specific code segments you wish to retain "// ... keep calculateTotalFunction ... ".
- If you plan on deleting a section, you must provide the context to delete it.
- Preserve the indentation and code structure of exactly how you believe the final code will look.
- Be as length efficient as possible without omitting key context.
To create a new file, simply specify the content of the file in the edit field.`;
