import React, { useEffect, useRef, useState, useCallback } from 'react';
import { GoogleGenAI, LiveServerMessage, Modality, Type, FunctionDeclaration } from '@google/genai';
import { GEMINI_MODEL, SYSTEM_INSTRUCTION } from '../constants';
import { AppContext, VoiceStatus, LogEntry } from '../types';
import { createPCM16Blob, decodeBase64, decodeAudioData } from '../utils/audioUtils';

interface LiveManagerProps {
  isActive: boolean;
  apps: AppContext[];
  onContextSwitch: (appId: string) => void;
  onStatusChange: (status: VoiceStatus) => void;
  onLog: (entry: LogEntry) => void;
}

export const LiveManager: React.FC<LiveManagerProps> = ({ 
  isActive, 
  apps, 
  onContextSwitch, 
  onStatusChange,
  onLog 
}) => {
  const [currentStatus, setCurrentStatus] = useState<VoiceStatus>(VoiceStatus.DISCONNECTED);
  const audioContextRef = useRef<AudioContext | null>(null);
  const inputContextRef = useRef<AudioContext | null>(null);
  const sessionPromiseRef = useRef<Promise<any> | null>(null);
  const activeSourceRef = useRef<AudioBufferSourceNode | null>(null);
  const nextStartTimeRef = useRef<number>(0);
  
  // Define tools based on available apps
  const getToolDeclarations = useCallback((): FunctionDeclaration[] => {
    const appNames = apps.map(a => a.name).join(', ');
    return [{
      name: 'switchContext',
      parameters: {
        type: Type.OBJECT,
        description: `Switch the active window/context to a specific application. Available apps: ${appNames}`,
        properties: {
          appName: {
            type: Type.STRING,
            description: 'The name of the application to switch to.',
          },
        },
        required: ['appName'],
      },
    }];
  }, [apps]);

  // Initialize Audio Contexts
  const ensureAudioContexts = async () => {
    if (!audioContextRef.current) {
      audioContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: 24000 });
    }
    if (!inputContextRef.current) {
      inputContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: 16000 });
    }

    if (audioContextRef.current.state === 'suspended') {
      await audioContextRef.current.resume();
    }
    if (inputContextRef.current.state === 'suspended') {
      await inputContextRef.current.resume();
    }
  };

  const connect = async () => {
    try {
      onStatusChange(VoiceStatus.CONNECTING);
      setCurrentStatus(VoiceStatus.CONNECTING);
      
      await ensureAudioContexts();

      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
      
      const config = {
        model: GEMINI_MODEL,
        config: {
          responseModalities: [Modality.AUDIO],
          systemInstruction: SYSTEM_INSTRUCTION,
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
            onStatusChange(VoiceStatus.LISTENING);
            setCurrentStatus(VoiceStatus.LISTENING);
            onLog({ id: Date.now().toString(), timestamp: Date.now(), source: 'system', message: 'Voice Connected' });

            // Setup Mic Input
            if (!inputContextRef.current) return;
            const source = inputContextRef.current.createMediaStreamSource(stream);
            // Use ScriptProcessor for raw PCM access (standard for Gemini demos)
            const processor = inputContextRef.current.createScriptProcessor(4096, 1, 1);
            
            processor.onaudioprocess = (e) => {
              const inputData = e.inputBuffer.getChannelData(0);
              const pcmBlob = createPCM16Blob(inputData);
              
              sessionPromiseRef.current?.then(session => {
                session.sendRealtimeInput({ media: pcmBlob });
              });
            };
            
            source.connect(processor);
            processor.connect(inputContextRef.current.destination);
          },
          onmessage: async (msg: LiveServerMessage) => {
            const { serverContent, toolCall } = msg;

            // Handle Audio Output
            const audioData = serverContent?.modelTurn?.parts?.[0]?.inlineData?.data;
            if (audioData && audioContextRef.current) {
              onStatusChange(VoiceStatus.SPEAKING);
              const ctx = audioContextRef.current;
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
                   onStatusChange(VoiceStatus.LISTENING);
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

            // Handle Tool Calls (Switching Windows)
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
                    session.sendToolResponse({
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
            onStatusChange(VoiceStatus.DISCONNECTED);
            setCurrentStatus(VoiceStatus.DISCONNECTED);
            onLog({ id: Date.now().toString(), timestamp: Date.now(), source: 'system', message: 'Disconnected' });
          },
          onerror: (err) => {
            console.error(err);
            onStatusChange(VoiceStatus.ERROR);
            onLog({ id: Date.now().toString(), timestamp: Date.now(), source: 'system', message: 'Connection Error' });
          }
        }
      });

    } catch (error) {
      console.error("Connection failed", error);
      onStatusChange(VoiceStatus.ERROR);
    }
  };

  // Manage connection lifecycle based on isActive prop
  useEffect(() => {
    if (isActive && currentStatus === VoiceStatus.DISCONNECTED) {
      connect();
    } 
    // Note: Disconnecting strictly is complex with the SDK's promise-based structure without an explicit 'close' on the session object exposed cleanly in all states.
    // For this demo, we assume the session persists until the component unmounts or specific error.
    // A full implementation would handle cleanup more aggressively.
    return () => {
      // Cleanup context on unmount
      if (inputContextRef.current && inputContextRef.current.state !== 'closed') {
         inputContextRef.current.close();
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isActive]);

  return null; // Logic only component
};
