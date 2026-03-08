
export interface AppContext {
  id: string;
  name: string;
  description: string;
  icon: string; // Emoji or simple string identifier
  uri: string; // The Deep Link or URL (e.g., 'vscode://', 'https://google.com')
  processName: string; // The executable name for AHK (e.g., 'cursor.exe', 'chrome.exe')
  color: string;
  shortcut: string; // Keyboard shortcut (e.g., 'Alt+1')
  category: string; // Grouping identifier (e.g., 'Development', 'Social')
}

export enum VoiceStatus {
  DISCONNECTED = 'DISCONNECTED',
  CONNECTING = 'CONNECTING',
  LISTENING = 'LISTENING',
  SPEAKING = 'SPEAKING',
  ERROR = 'ERROR',
}

export interface LogEntry {
  id: string;
  timestamp: number;
  source: 'user' | 'gemini' | 'system';
  message: string;
}

// Audio Type Definitions for manual implementation
export interface PCM16Blob {
  data: string; // Base64 encoded
  mimeType: string;
}
