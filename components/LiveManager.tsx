import React, { useEffect, useRef, useState, useCallback } from 'react';
import { GoogleGenAI, LiveServerMessage, Modality, Type, FunctionDeclaration, LiveSession } from '@google/genai';
import { GEMINI_MODEL, SYSTEM_INSTRUCTION, RELACE_TOOL_DESCRIPTION } from '../constants';
import { AppContext, VoiceStatus, LogEntry } from '../types';
import { createPCM16Blob, decodeBase64, decodeAudioData } from '../utils/audioUtils';

interface LiveManagerProps {
  isActive: boolean;
  isRelaceMode: boolean;
  apps: AppContext[];
  onContextSwitch: (appId: string) => void;
  onStatusChange: (status: VoiceStatus) => void;
  onLog: (entry: LogEntry) => void;
}

// Audio context hook with cleanup
function useAudioContexts() {
  const audioCtx = useRef<AudioContext | null>(null);
  const inputCtx = useRef<AudioContext | null>(null);

  const init = async () => {
    if (!audioCtx.current) {
      audioCtx.current = new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: 24000 });
    }
    if (!inputCtx.current) {
      inputCtx.current = new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: 16000 });
    }
    await Promise.all([
      audioCtx.current.state === 'suspended' ? audioCtx.current.resume() : Promise.resolve(),
      inputCtx.current.state === 'suspended' ? inputCtx.current.resume() : Promise.resolve(),
    ]);
  };

  const cleanup = () => {
    audioCtx.current?.close();
    inputCtx.current?.close();
    audioCtx.current = null;
    inputCtx.current = null;
  };

  return { audioCtx, inputCtx, init, cleanup };
}

// Replace ScriptProcessor with AudioWorklet (fallback)
async function setupMicProcessor(
  ctx: AudioContext,
  stream: MediaStream,
  sendChunk: (blob: Blob) => void
) {
  // Try AudioWorklet first
  try {
    await ctx.audioWorklet.addModule('/worklet/pcm-processor.js');
    const workletNode = new AudioWorkletNode(ctx, 'pcm-processor');
    workletNode.port.onmessage = (event) => {
      const pcmBlob = new Blob([event.data], { type: 'audio/pcm' });
      sendChunk(pcmBlob);
    };
    const source = ctx.createMediaStreamSource(stream);
    source.connect(workletNode).connect(ctx.destination);
  } catch {
    // Fallback to ScriptProcessor (deprecated)
    const source = ctx.createMediaStreamSource(stream);
    const processor = ctx.createScriptProcessor(4096, 1, 1);
    processor.onaudioprocess = (e) => {
      const inputData = e.inputBuffer.getChannelData(0);
      const pcmBlob = createPCM16Blob(inputData);
      sendChunk(pcmBlob);
    };
    source.connect(processor);
    processor.connect(ctx.destination);
  }
}

// Tool declarations hook
function useToolDeclarations(apps: AppContext[], isRelaceMode: boolean) {
  return useCallback((): FunctionDeclaration[] => {
    const appNames = apps.map(a => a.name).join(', ');
    const baseTools: FunctionDeclaration[] = [
      {
        name: 'switchContext',
        parameters: {
          type: Type.OBJECT,
          description: `Switch the active window/context to a specific application. Available apps: ${appNames}`,
          properties: {
            appName: { type: Type.STRING, description: 'The name of the application to switch to.' },
          },
          required: ['appName'],
        },
      },
    ];

    if (isRelaceMode) {
      baseTools.push({
        name: 'edit_file',
        description: RELACE_TOOL_DESCRIPTION,
        parameters: {
          type: Type.OBJECT,
          properties: {
            path: { type: Type.STRING, description: 'Absolute file path.' },
            instruction: { type: Type.STRING, description: 'One‑sentence edit instruction.' },
            edit: { type: Type.STRING, description: 'Exact code lines to modify.' },
          },
          required: ['path', 'instruction', 'edit'],
        },
      });
    }
    return baseTools;
  }, [apps, isRelaceMode]);
}

// Secure API key handling (example)
const fetchApiKey = async () => {
  // TODO: In production, fetch from a secure backend to avoid exposing the key in the bundle.
  // const resp = await fetch('/api/get-gemini-key');
  // return resp.json().then(d => d.apiKey);
  return process.env.API_KEY as string;
};

export const LiveManager: React.FC<LiveManagerProps> = ({
  isActive,
  isRelaceMode,
  apps,
  onContextSwitch,
  onStatusChange,
  onLog
}) => {
  const [currentStatus, setCurrentStatus] = useState<VoiceStatus>(VoiceStatus.DISCONNECTED);
  const { audioCtx, inputCtx, init: initAudioContexts, cleanup: cleanupAudioContexts } = useAudioContexts();
  const sessionPromiseRef = useRef<Promise<LiveSession | null> | null>(null);
  const activeSourceRef = useRef<AudioBufferSourceNode | null>(null);
  const nextStartTimeRef = useRef<number>(0);

  const getToolDeclarations = useToolDeclarations(apps, isRelaceMode);

  const updateStatus = useCallback((status: VoiceStatus, message?: string) => {
    onStatusChange(status);
    setCurrentStatus(status);
    if (message) {
      onLog({ id: Date.now().toString(), timestamp: Date.now(), source: 'system', message });
    }
  }, [onStatusChange, onLog]);

  const connect = useCallback(async () => {
    try {
      updateStatus(VoiceStatus.CONNECTING);

      await initAudioContexts();

      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const apiKey = await fetchApiKey();
      const ai = new GoogleGenAI({ apiKey });

      const config = {
        model: GEMINI_MODEL,
        config: {
          responseModalities: [Modality.AUDIO],
          systemInstruction: isRelaceMode
            ? SYSTEM_INSTRUCTION + "\n\nRELACE MODE ACTIVE. You are now in coding mode. Use the 'edit_file' tool for all code modifications. Follow the tool's format strictly."
            : SYSTEM_INSTRUCTION,
          tools: [{ functionDeclarations: getToolDeclarations() }],
          speechConfig: {
            voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Kore' } },
          },
        },
      };

      // Connect to Live API
      sessionPromiseRef.current = ai.live.connect({
        ...config,
        callbacks: {
          onopen: () => {
            updateStatus(VoiceStatus.LISTENING, isRelaceMode ? 'Voice Connected (Relace Mode)' : 'Voice Connected');

            // Setup Mic Input
            if (inputCtx.current) {
              setupMicProcessor(inputCtx.current, stream, (blob) => {
                sessionPromiseRef.current?.then(session => {
                  session?.sendRealtimeInput({ media: blob });
                });
              });
            }
          },
          onmessage: async (msg: LiveServerMessage) => {
            const { serverContent, toolCall } = msg;

            // Handle Audio Output
            const audioData = serverContent?.modelTurn?.parts?.[0]?.inlineData?.data;
            if (audioData && audioCtx.current) {
              updateStatus(VoiceStatus.SPEAKING);
              const ctx = audioCtx.current;
              const buffer = await decodeAudioData(decodeBase64(audioData), ctx, 24000, 1);

              const source = ctx.createBufferSource();
              source.buffer = buffer;
              source.connect(ctx.destination);

              // Scheduling for gapless playback
              const now = ctx.currentTime;
              const start = Math.max(now, nextStartTimeRef.current);
              source.start(start);
              nextStartTimeRef.current = start + buffer.duration;

              activeSourceRef.current = source;

              source.onended = () => {
                if (ctx.currentTime >= nextStartTimeRef.current - 0.1) {
                  updateStatus(VoiceStatus.LISTENING);
                }
              };
            }

            // Handle Turn Complete (Logging)
            if (serverContent?.turnComplete) {
              // Logic to reset state if needed
            }

            // Handle Interruption
            if (serverContent?.interrupted) {
              if (activeSourceRef.current) activeSourceRef.current.stop();
              nextStartTimeRef.current = 0;
              onLog({ id: Date.now().toString(), timestamp: Date.now(), source: 'system', message: 'Interrupted' });
            }

            // Handle Tool Calls
            if (toolCall) {
              for (const fc of toolCall.functionCalls) {
                if (fc.name === 'switchContext') {
                  const appName = (fc.args as any).appName;
                  onLog({ id: fc.id, timestamp: Date.now(), source: 'gemini', message: `Switching to ${appName}` });

                  // Find the app ID
                  const targetApp = apps.find(a => a.name.toLowerCase().includes(appName.toLowerCase()));
                  let result = "App not found";

                  if (targetApp) {
                    onContextSwitch(targetApp.id);
                    result = `Switched to ${targetApp.name}`;
                  } else {
                    result = `Could not find app named ${appName}`;
                  }

                  // Send response back
                  sessionPromiseRef.current?.then(session => {
                    session?.sendToolResponse({
                      functionResponses: {
                        id: fc.id,
                        name: fc.name,
                        response: { result },
                      }
                    });
                  });
                } else if (fc.name === 'edit_file') {
                  const { path, instruction, edit } = fc.args as any;
                  onLog({ id: fc.id, timestamp: Date.now(), source: 'gemini', message: `Relace Edit: ${instruction}` });
                  console.log("RELACE EDIT REQUEST:", { path, instruction, edit });

                  // In a real scenario, this would trigger the apply logic.
                  // For now, we acknowledge it.
                  const result = "Edit request received and logged for Relace Apply.";

                  sessionPromiseRef.current?.then(session => {
                    session?.sendToolResponse({
                      functionResponses: {
                        id: fc.id,
                        name: fc.name,
                        response: { result },
                      }
                    });
                  });
                }
              }
            }
          },
          onclose: () => {
            updateStatus(VoiceStatus.DISCONNECTED, 'Disconnected');
          },
          onerror: (err) => {
            console.error(err);
            updateStatus(VoiceStatus.ERROR, 'Connection Error');
          }
        }
      });

    } catch (error) {
      console.error("Connection failed", error);
      updateStatus(VoiceStatus.ERROR);
    }
  }, [initAudioContexts, inputCtx, audioCtx, getToolDeclarations, isRelaceMode, updateStatus, apps, onContextSwitch, onLog]);

  // Manage connection lifecycle based on isActive prop
  useEffect(() => {
    if (isActive && currentStatus === VoiceStatus.DISCONNECTED) {
      connect();
    }

    return () => {
      // Cleanup context on unmount
      cleanupAudioContexts();

      // Abort pending session
      sessionPromiseRef.current?.then(session => session?.close?.()).catch(() => { });

      // Reset refs
      activeSourceRef.current = null;
      nextStartTimeRef.current = 0;
    };
  }, [isActive, isRelaceMode, connect, cleanupAudioContexts, currentStatus]);

  return null; // Logic only component
};
