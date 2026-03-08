
import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { LiveManager } from './components/LiveManager';
import { DEFAULT_APPS } from './constants';
import { AppContext, VoiceStatus, LogEntry } from './types';
import { Mic, MicOff, Command, Activity, Maximize2, ExternalLink, Plus, Settings, Save, AlertCircle, Layers, MousePointer2, Zap } from 'lucide-react';

const App: React.FC = () => {
  const [apps, setApps] = useState<AppContext[]>(DEFAULT_APPS);
  const [activeAppId, setActiveAppId] = useState<string>(DEFAULT_APPS[0].id);
  const [activeCategory, setActiveCategory] = useState<string>('All');

  const [isVoiceActive, setIsVoiceActive] = useState<boolean>(false);
  const [isRelaceMode, setIsRelaceMode] = useState<boolean>(false);
  const [voiceStatus, setVoiceStatus] = useState<VoiceStatus>(VoiceStatus.DISCONNECTED);
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [editingAppId, setEditingAppId] = useState<string | null>(null);
  const [backendStatus, setBackendStatus] = useState<'unknown' | 'connected' | 'disconnected'>('unknown');

  const scrollThrottleRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Check Backend Health on Mount
  useEffect(() => {
    const checkHealth = async () => {
      try {
        await fetch('http://localhost:3001/health', { method: 'GET', signal: AbortSignal.timeout(2000) });
        setBackendStatus('connected');
        handleLog({ id: 'init-be', timestamp: Date.now(), source: 'system', message: 'Local AHK Backend Connected' });
      } catch (e) {
        setBackendStatus('disconnected');
      }
    };
    checkHealth();
    const interval = setInterval(checkHealth, 30000);
    return () => clearInterval(interval);
  }, []);

  const handleLog = useCallback((entry: LogEntry) => {
    setLogs(prev => [entry, ...prev].slice(0, 10));
  }, []);

  // --- Computed Data ---
  const uniqueCategories = useMemo(() => {
    const cats = new Set(apps.map(a => a.category));
    return ['All', ...Array.from(cats)];
  }, [apps]);

  const filteredApps = useMemo(() => {
    return activeCategory === 'All'
      ? apps
      : apps.filter(a => a.category === activeCategory);
  }, [apps, activeCategory]);

  // --- Window Switching Logic ---
  const handleContextSwitch = useCallback(async (appId: string) => {
    setActiveAppId(appId);
    const app = apps.find(a => a.id === appId);

    if (app) {
      handleLog({
        id: Date.now().toString(),
        timestamp: Date.now(),
        source: 'system',
        message: `Focusing ${app.name}...`
      });

      // 1. Try Backend (AutoHotkey)
      try {
        const res = await fetch('http://localhost:3001/focus', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ processName: app.processName, appName: app.name })
        });
        if (res.ok) {
          return; // Success, AHK took over
        }
      } catch (e) {
        // Backend failed or not present
        if (backendStatus === 'connected') setBackendStatus('disconnected');
      }

      // 2. Fallback: URI Scheme / Visual Simulation
      try {
        window.open(app.uri, '_blank');
      } catch (e) {
        console.warn("Blocked popup or invalid URI scheme");
      }
    }
  }, [apps, backendStatus, handleLog]);

  // --- Hotkey Listener ---
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Global Toggle: Ctrl + Space
      if (e.ctrlKey && e.code === 'Space') {
        e.preventDefault();
        setIsVoiceActive(prev => !prev);
        return;
      }

      // App Hotkeys
      if (!editingAppId) { // Disable hotkeys while editing
        apps.forEach(app => {
          if (!app.shortcut) return;

          const parts = app.shortcut.toLowerCase().split('+').map(p => p.trim());
          const keyChar = parts[parts.length - 1];

          const wantsCtrl = parts.includes('ctrl');
          const wantsAlt = parts.includes('alt');
          const wantsShift = parts.includes('shift');

          // Normalize key check
          const eventKey = e.key.toLowerCase();
          const isMatch = (
            eventKey === keyChar &&
            e.ctrlKey === wantsCtrl &&
            e.altKey === wantsAlt &&
            e.shiftKey === wantsShift
          );

          if (isMatch) {
            e.preventDefault();
            handleContextSwitch(app.id);
          }
        });
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [apps, editingAppId, handleContextSwitch]);

  // --- Alt + Scroll Cycling Listener ---
  useEffect(() => {
    const handleWheel = (e: WheelEvent) => {
      if (e.altKey && filteredApps.length > 0) {
        e.preventDefault();

        // Throttle checks
        if (scrollThrottleRef.current) return;

        const direction = e.deltaY > 0 ? 1 : -1; // Down = Next, Up = Prev

        // Find current index in the FILTERED list
        let currentIndex = filteredApps.findIndex(a => a.id === activeAppId);

        // If current app isn't in view, start from 0
        if (currentIndex === -1) currentIndex = 0;

        let nextIndex = (currentIndex + direction) % filteredApps.length;
        if (nextIndex < 0) nextIndex = filteredApps.length - 1;

        const nextApp = filteredApps[nextIndex];

        // Execute switch
        handleContextSwitch(nextApp.id);

        // Set throttle
        scrollThrottleRef.current = setTimeout(() => {
          scrollThrottleRef.current = null;
        }, 150); // 150ms throttle for smooth scrolling
      }
    };

    // { passive: false } is required to preventDefault on wheel events
    window.addEventListener('wheel', handleWheel, { passive: false });
    return () => {
      window.removeEventListener('wheel', handleWheel);
      if (scrollThrottleRef.current) clearTimeout(scrollThrottleRef.current);
    };
  }, [filteredApps, activeAppId, handleContextSwitch]);


  // --- App Editing ---
  const updateApp = (id: string, field: keyof AppContext, value: string) => {
    setApps(prev => prev.map(a => a.id === id ? { ...a, [field]: value } : a));
  };

  const activeApp = apps.find(a => a.id === activeAppId) || apps[0];

  return (
    <div className="min-h-screen bg-neon-dark text-gray-200 overflow-hidden flex flex-col font-sans selection:bg-neon-blue selection:text-black">

      {/* Header */}
      <header className="h-16 border-b border-gray-800 flex items-center justify-between px-6 bg-black/50 backdrop-blur-md fixed top-0 w-full z-50">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-gradient-to-br from-neon-blue to-neon-purple rounded-lg flex items-center justify-center shadow-lg shadow-neon-blue/20">
            <Activity size={18} className="text-white" />
          </div>
          <h1 className="font-mono font-bold text-xl tracking-tighter">
            FOCUS<span className="text-neon-blue">FLOW</span>
          </h1>
          {backendStatus === 'disconnected' && (
            <span className="text-xs text-red-500 flex items-center gap-1 bg-red-500/10 px-2 py-1 rounded ml-4 border border-red-500/20">
              <AlertCircle size={12} /> Backend Offline
            </span>
          )}
        </div>

        <div className="flex items-center space-x-6">
          <div className={`flex items-center space-x-2 px-3 py-1 rounded-full text-xs font-bold font-mono border ${voiceStatus === VoiceStatus.SPEAKING ? 'border-neon-green text-neon-green bg-neon-green/10' :
              voiceStatus === VoiceStatus.LISTENING ? 'border-neon-blue text-neon-blue bg-neon-blue/10' :
                'border-gray-700 text-gray-500'
            }`}>
            <div className={`w-2 h-2 rounded-full ${voiceStatus === VoiceStatus.DISCONNECTED ? 'bg-gray-500' : 'animate-pulse ' + (voiceStatus === VoiceStatus.SPEAKING ? 'bg-neon-green' : 'bg-neon-blue')
              }`} />
            <span>{voiceStatus}</span>
          </div>

          <button
            onClick={() => setIsRelaceMode(!isRelaceMode)}
            className={`p-2 rounded-full transition-all duration-300 ${isRelaceMode ? 'bg-yellow-500/20 text-yellow-400 hover:bg-yellow-500/30' : 'bg-gray-800 text-gray-500 hover:text-gray-300'
              }`}
            title="Toggle Relace Mode"
          >
            <Zap size={20} />
          </button>

          <button
            onClick={() => setIsVoiceActive(!isVoiceActive)}
            className={`p-2 rounded-full transition-all duration-300 ${isVoiceActive ? 'bg-red-500/20 text-red-400 hover:bg-red-500/30' : 'bg-neon-blue/20 text-neon-blue hover:bg-neon-blue/30'
              }`}
            title="Toggle Voice Control (Ctrl + Space)"
          >
            {isVoiceActive ? <MicOff size={20} /> : <Mic size={20} />}
          </button>
        </div>
      </header>

      <LiveManager
        isActive={isVoiceActive}
        isRelaceMode={isRelaceMode}
        apps={apps}
        onContextSwitch={handleContextSwitch}
        onStatusChange={setVoiceStatus}
        onLog={handleLog}
      />

      <main className="flex-1 pt-24 pb-12 px-6 flex flex-col lg:flex-row gap-8 max-w-7xl mx-auto w-full h-screen">

        {/* Left Panel: Context Grid */}
        <section className="flex-1 flex flex-col space-y-4 min-h-0">
          <div className="flex flex-col gap-4">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-mono text-gray-500 uppercase tracking-widest flex items-center gap-2">
                <Layers size={14} /> Context Groups
              </h2>
              <div className="text-[10px] text-gray-600 font-mono flex items-center gap-2">
                <span className="flex items-center gap-1"><MousePointer2 size={10} /> Alt + Scroll to Cycle</span>
              </div>
            </div>

            {/* Category Selector Pills */}
            <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
              {uniqueCategories.map(cat => (
                <button
                  key={cat}
                  onClick={() => setActiveCategory(cat)}
                  className={`
                    px-4 py-1.5 rounded-full text-xs font-bold font-mono whitespace-nowrap transition-all
                    ${activeCategory === cat
                      ? 'bg-neon-blue/20 text-neon-blue border border-neon-blue shadow-[0_0_10px_rgba(0,243,255,0.2)]'
                      : 'bg-gray-900 text-gray-500 border border-gray-800 hover:border-gray-600 hover:text-gray-300'
                    }
                  `}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 overflow-y-auto pr-2 pb-20 custom-scrollbar flex-1">
            {filteredApps.map((app) => {
              const isActive = app.id === activeAppId;
              const isEditing = editingAppId === app.id;

              return (
                <div
                  key={app.id}
                  className={`
                    relative group p-5 rounded-2xl border transition-all duration-300 flex flex-col justify-between min-h-[140px]
                    ${isActive
                      ? 'bg-gray-900 border-neon-blue shadow-[0_0_20px_-10px_rgba(0,243,255,0.3)]'
                      : 'bg-gray-950 border-gray-800 hover:border-gray-600'
                    }
                  `}
                >
                  {/* Card Header */}
                  <div className="flex justify-between items-start mb-2">
                    <span className="text-4xl select-none">{app.icon}</span>
                    <div className="flex gap-2">
                      <button
                        onClick={(e) => { e.stopPropagation(); setEditingAppId(isEditing ? null : app.id); }}
                        className={`p-2 rounded-full hover:bg-gray-800 text-gray-500 hover:text-white transition-colors`}
                      >
                        {isEditing ? <Save size={14} /> : <Settings size={14} />}
                      </button>
                      {isActive && <div className="w-2 h-2 bg-neon-blue rounded-full mt-2 shadow-[0_0_10px_#00f3ff]" />}
                    </div>
                  </div>

                  {/* Card Content */}
                  <div className="space-y-2">
                    <div className="flex justify-between items-center">
                      <h3 className={`font-bold text-lg ${isActive ? 'text-white' : 'text-gray-400 group-hover:text-gray-200'}`}>
                        {app.name}
                      </h3>
                      {!isEditing && (
                        <div className="flex flex-col items-end">
                          <span className="text-[10px] font-mono text-gray-600">{app.category}</span>
                          <span className="text-[10px] font-mono bg-gray-800 px-2 py-0.5 rounded text-neon-blue border border-gray-700 mt-1">
                            {app.shortcut}
                          </span>
                        </div>
                      )}
                    </div>

                    {isEditing ? (
                      <div className="space-y-2 animate-fadeIn bg-black/40 p-2 rounded border border-gray-800">
                        <div className="grid grid-cols-2 gap-2">
                          <div>
                            <label className="text-[8px] text-gray-500 font-mono uppercase block mb-1">Process</label>
                            <input
                              className="w-full bg-black/50 border border-gray-700 rounded px-2 py-1 text-[10px] text-green-400 font-mono focus:border-neon-blue outline-none"
                              value={app.processName}
                              onChange={(e) => updateApp(app.id, 'processName', e.target.value)}
                              placeholder="app.exe"
                            />
                          </div>
                          <div>
                            <label className="text-[8px] text-gray-500 font-mono uppercase block mb-1">Hotkey</label>
                            <input
                              className="w-full bg-black/50 border border-gray-700 rounded px-2 py-1 text-[10px] text-yellow-400 font-mono focus:border-neon-blue outline-none"
                              value={app.shortcut}
                              onChange={(e) => updateApp(app.id, 'shortcut', e.target.value)}
                              placeholder="Alt+Key"
                            />
                          </div>
                        </div>
                        <div>
                          <label className="text-[8px] text-gray-500 font-mono uppercase block mb-1">Category</label>
                          <input
                            className="w-full bg-black/50 border border-gray-700 rounded px-2 py-1 text-[10px] text-blue-400 font-mono focus:border-neon-blue outline-none"
                            value={app.category}
                            onChange={(e) => updateApp(app.id, 'category', e.target.value)}
                            placeholder="e.g. Dev, Media"
                          />
                        </div>
                      </div>
                    ) : (
                      <p className="text-xs text-gray-600 font-mono truncate">
                        {app.processName || "No process defined"}
                      </p>
                    )}
                  </div>

                  {/* Quick Switch Button (Only visible on hover if not editing) */}
                  {!isEditing && (
                    <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                      <button
                        onClick={() => handleContextSwitch(app.id)}
                        className="pointer-events-auto opacity-0 group-hover:opacity-100 transition-opacity duration-200 bg-white text-black px-4 py-2 rounded-full font-bold text-xs flex items-center gap-2 transform translate-y-4 group-hover:translate-y-0 shadow-xl"
                      >
                        <ExternalLink size={12} /> SWITCH
                      </button>
                    </div>
                  )}
                </div>
              );
            })}

            <div className="border border-dashed border-gray-800 rounded-2xl flex flex-col items-center justify-center text-gray-600 hover:text-gray-400 hover:border-gray-600 transition-colors cursor-pointer min-h-[140px]">
              <Plus size={32} className="mb-2" />
              <span className="text-xs font-mono">ADD PROCESS</span>
            </div>
          </div>
        </section>

        {/* Right Panel: Active Focus */}
        <aside className="lg:w-1/3 flex flex-col space-y-6">

          <div className="flex-1 bg-gray-900/50 rounded-3xl border border-gray-800 relative overflow-hidden flex flex-col">
            <div className="bg-gray-950 p-4 border-b border-gray-800 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-red-500/20 border border-red-500/50" />
                <div className="w-3 h-3 rounded-full bg-yellow-500/20 border border-yellow-500/50" />
                <div className="w-3 h-3 rounded-full bg-green-500/20 border border-green-500/50" />
              </div>
              <div className="font-mono text-xs text-gray-500 uppercase tracking-wider flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-neon-blue animate-pulse" />
                {activeApp.category}
              </div>
            </div>

            <div className="flex-1 flex flex-col items-center justify-center p-8 text-center space-y-6 relative">
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-40 h-40 bg-neon-purple/20 blur-[100px] rounded-full pointer-events-none" />

              <div className="relative z-10">
                <div className="text-8xl mb-4 animate-bounce-slow cursor-default">
                  {activeApp.icon}
                </div>
                <h2 className="text-3xl font-bold text-white mb-2">{activeApp.name}</h2>
                <div className="inline-flex items-center gap-2 bg-gray-800 px-3 py-1 rounded-full text-xs font-mono text-neon-blue border border-gray-700">
                  <Command size={10} />
                  {activeApp.shortcut}
                </div>
              </div>

              <div className="z-10 space-y-2 w-full max-w-xs">
                <button
                  onClick={() => handleContextSwitch(activeAppId)}
                  className="w-full bg-white text-black hover:bg-gray-200 px-8 py-3 rounded-full font-bold flex items-center justify-center gap-2 transition-all hover:scale-105 shadow-[0_0_15px_rgba(255,255,255,0.3)]"
                >
                  <Maximize2 size={18} />
                  BRING TO FRONT
                </button>
                {backendStatus === 'disconnected' && (
                  <p className="text-[10px] text-red-400/70">Backend offline. Visual simulation only.</p>
                )}
              </div>
            </div>
          </div>

          <div className="h-48 bg-black rounded-2xl border border-gray-800 p-4 font-mono text-xs overflow-hidden flex flex-col shadow-inner">
            <div className="text-gray-500 mb-2 flex items-center gap-2 border-b border-gray-900 pb-2">
              <Command size={12} /> SYSTEM_LOG
            </div>
            <div className="flex-1 overflow-y-auto space-y-2 custom-scrollbar">
              {logs.length === 0 && <span className="text-gray-700 italic">Ready for input...</span>}
              {logs.map((log) => (
                <div key={log.id} className="flex gap-2 animate-pulse-once">
                  <span className="text-gray-600 min-w-[60px]">[{new Date(log.timestamp).toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' })}]</span>
                  <span className={`${log.source === 'gemini' ? 'text-neon-purple' :
                      log.source === 'user' ? 'text-neon-blue' : 'text-gray-400'
                    }`}>
                    {log.source === 'gemini' ? '> ' : ''}{log.message}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </aside>

      </main>
    </div>
  );
};

export default App;
