using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

internal static class Program
{
    private const int GaRoot = 2;
    private const int GwlExstyle = -20;
    private const int WsExToolWindow = 0x00000080;
    private const int LwaAlpha = 0x2;
    private const int SwRestore = 9;
    private const int SwShow = 5;
    private const int SwShowMaximized = 3;
    private const int SwpNoZorder = 0x0004;
    private const int SwpNoActivate = 0x0010;
    private const int WsExLayered = 0x00080000;
    private const int WmHotkey = 0x0312;
    private const uint ModControl = 0x2;
    private const uint ModAlt = 0x1;
    private const uint VkSpace = 0x20;
    private const int VkControl = 0x11;
    private const int VkMenu = 0x12;
    private const int MaxSlots = 6;
    private const int WhMouseLl = 14;
    private const int WmMouseWheel = 0x020A;

    private const int MonitorAuto = 0;
    private const int MonitorFromCursor = 99;
    private const int MonitorFlagNearest = 2;

    private static readonly List<IntPtr> Monitors = new List<IntPtr>();

    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length > 0 && string.Equals(args[0], "activate", StringComparison.OrdinalIgnoreCase))
        {
            return RunActivateCli(args);
        }

        if (args.Length > 0 && (args[0] == "--help" || args[0] == "/?" || args[0] == "-h"))
        {
            ShowUsage();
            return 0;
        }

        bool openNow = HasArg(args, "open");

        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        using (SwitcherApplicationContext context = new SwitcherApplicationContext(openNow))
        {
            Application.Run(context);
        }

        return 0;
    }

    private static bool HasArg(string[] args, string option)
    {
        for (int i = 0; i < args.Length; i++)
        {
            if (string.Equals(args[i], "--" + option, StringComparison.OrdinalIgnoreCase) ||
                string.Equals(args[i], "/" + option, StringComparison.OrdinalIgnoreCase) ||
                string.Equals(args[i], "-" + option, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }

    private static int RunActivateCli(string[] args)
    {
        try
        {
            Dictionary<string, string> options = ParseOptions(args, 1);
            string slotType = GetRequiredOption(options, "slot-type");
            string slotValue = GetRequiredOption(options, "slot-value");
            int monitor = ParseIntOption(options, "monitor", MonitorAuto);
            string monitorRect = GetOptionalOption(options, "monitor-rect");
            bool maximize = ParseIntOption(options, "maximize", 0) != 0;
            int transparency = Clamp(ParseIntOption(options, "transparency", 255), 25, 255);

            IntPtr hwnd = ResolveTargetWindow(slotType, slotValue);
            if (hwnd == IntPtr.Zero)
            {
                Console.Error.WriteLine("Unable to resolve target window.");
                return 4;
            }

            return ApplyWindowActivation(hwnd, monitor, monitorRect, maximize, transparency) ? 0 : 5;
        }
        catch (ArgumentException ex)
        {
            Console.Error.WriteLine(ex.Message);
            return 3;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.Message);
            return 1;
        }
    }

    private static bool ApplyWindowActivation(IntPtr hwnd, int monitor, string monitorRect, bool maximize, int transparency)
    {
        if (!IsUsableWindow(hwnd))
        {
            return false;
        }

        if (monitor != MonitorAuto)
        {
            MoveWindowToMonitor(hwnd, monitor, monitorRect, maximize);
        }
        else if (maximize)
        {
            ShowWindow(hwnd, SwRestore);
            ShowWindow(hwnd, SwShowMaximized);
        }

        ApplyTransparency(hwnd, transparency);
        return ActivateWindow(hwnd);
    }

    public static bool ActivateWindowHandle(IntPtr hwnd, int monitor, bool maximize, int transparency)
    {
        return ApplyWindowActivation(hwnd, monitor, string.Empty, maximize, transparency);
    }

    public static bool ActivateSavedSlot(SlotAssignment slot)
    {
        if (slot == null)
        {
            return false;
        }

        IntPtr hwnd = ResolveSavedSlotWindow(slot);
        if (hwnd == IntPtr.Zero)
        {
            return false;
        }

        string monitorRect = slot.MonitorRect;
        if (string.IsNullOrWhiteSpace(monitorRect))
        {
            monitorRect = GetMonitorRectString(slot.Monitor);
        }

        return ApplyWindowActivation(hwnd, slot.Monitor, monitorRect, slot.Maximize, Clamp(slot.Transparency, 25, 255));
    }

    private static Dictionary<string, string> ParseOptions(string[] args, int startIndex)
    {
        Dictionary<string, string> options = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        for (int index = startIndex; index < args.Length; index += 2)
        {
            string key = args[index];
            if (!key.StartsWith("--", StringComparison.Ordinal))
            {
                throw new ArgumentException("Invalid argument: " + key);
            }

            if (index + 1 >= args.Length)
            {
                throw new ArgumentException("Missing value for " + key);
            }

            options[key.Substring(2)] = args[index + 1];
        }

        return options;
    }

    private static string GetRequiredOption(Dictionary<string, string> options, string key)
    {
        string value;
        if (!options.TryGetValue(key, out value) || string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Missing required option --" + key);
        }

        return value;
    }

    private static string GetOptionalOption(Dictionary<string, string> options, string key)
    {
        string value;
        return options.TryGetValue(key, out value) ? value : string.Empty;
    }

    private static int ParseIntOption(Dictionary<string, string> options, string key, int defaultValue)
    {
        string value;
        if (!options.TryGetValue(key, out value))
        {
            return defaultValue;
        }

        int parsed;
        if (!int.TryParse(value, out parsed))
        {
            throw new ArgumentException("Invalid integer for --" + key + ": " + value);
        }

        return parsed;
    }

    private static IntPtr ResolveTargetWindow(string slotType, string slotValue)
    {
        if (string.Equals(slotType, "session", StringComparison.OrdinalIgnoreCase))
        {
            long rawHandle;
            if (!long.TryParse(slotValue, out rawHandle))
            {
                throw new ArgumentException("Session slot value must be a window handle.");
            }

            IntPtr hwnd = new IntPtr(rawHandle);
            return IsUsableWindow(hwnd) ? hwnd : IntPtr.Zero;
        }

        if (string.Equals(slotType, "permanent", StringComparison.OrdinalIgnoreCase))
        {
            return FindWindowByProcessName(slotValue);
        }

        throw new ArgumentException("Unsupported slot type: " + slotType);
    }

    private static IntPtr FindWindowByProcessName(string processValue)
    {
        string normalized = NormalizeProcessName(processValue);
        IntPtr best = IntPtr.Zero;

        EnumWindows(
            delegate (IntPtr hwnd, IntPtr lParam)
            {
                if (!IsUsableWindow(hwnd))
                {
                    return true;
                }

                uint processId;
                GetWindowThreadProcessId(hwnd, out processId);
                if (processId == 0)
                {
                    return true;
                }

                try
                {
                    using (Process process = Process.GetProcessById((int)processId))
                    {
                        string candidate = NormalizeProcessName(process.ProcessName);
                        if (string.Equals(candidate, normalized, StringComparison.OrdinalIgnoreCase))
                        {
                            best = hwnd;
                            return false;
                        }
                    }
                }
                catch
                {
                    return true;
                }

                return true;
            },
            IntPtr.Zero);

        return best;
    }

    private static IntPtr FindWindowByProcessAndTitle(string processValue, string titleValue)
    {
        string normalizedProcess = NormalizeProcessName(processValue);
        string normalizedTitle = (titleValue ?? string.Empty).Trim();
        IntPtr containsMatch = IntPtr.Zero;
        IntPtr processMatch = IntPtr.Zero;

        EnumWindows(
            delegate (IntPtr hwnd, IntPtr lParam)
            {
                if (!IsUsableWindow(hwnd))
                {
                    return true;
                }

                uint processId;
                GetWindowThreadProcessId(hwnd, out processId);
                if (processId == 0)
                {
                    return true;
                }

                string processName = string.Empty;
                try
                {
                    using (Process process = Process.GetProcessById((int)processId))
                    {
                        processName = NormalizeProcessName(process.ProcessName);
                    }
                }
                catch
                {
                    return true;
                }

                if (!string.Equals(processName, normalizedProcess, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }

                if (processMatch == IntPtr.Zero)
                {
                    processMatch = hwnd;
                }

                string title = GetWindowTitle(hwnd);
                if (string.IsNullOrWhiteSpace(normalizedTitle))
                {
                    return false;
                }

                if (string.Equals(title, normalizedTitle, StringComparison.OrdinalIgnoreCase))
                {
                    processMatch = hwnd;
                    containsMatch = hwnd;
                    return false;
                }

                if (containsMatch == IntPtr.Zero &&
                    title.IndexOf(normalizedTitle, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    containsMatch = hwnd;
                }

                return true;
            },
            IntPtr.Zero);

        if (containsMatch != IntPtr.Zero)
        {
            return containsMatch;
        }

        return processMatch;
    }

    private static IntPtr ResolveSavedSlotWindow(SlotAssignment slot)
    {
        if (slot == null || string.IsNullOrWhiteSpace(slot.Value))
        {
            return IntPtr.Zero;
        }

        if (string.Equals(slot.Type, "session", StringComparison.OrdinalIgnoreCase))
        {
            IntPtr direct = ResolveTargetWindow("session", slot.Value);
            if (direct != IntPtr.Zero)
            {
                return direct;
            }

            if (!string.IsNullOrWhiteSpace(slot.ProcessName))
            {
                IntPtr fallback = FindWindowByProcessAndTitle(slot.ProcessName, slot.MatchTitle);
                if (fallback != IntPtr.Zero)
                {
                    return fallback;
                }
            }

            return IntPtr.Zero;
        }

        IntPtr titled = FindWindowByProcessAndTitle(slot.Value, slot.MatchTitle);
        if (titled != IntPtr.Zero)
        {
            return titled;
        }

        return ResolveTargetWindow("permanent", slot.Value);
    }

    private static string NormalizeProcessName(string value)
    {
        string normalized = (value ?? string.Empty).Trim();
        if (normalized.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
        {
            normalized = normalized.Substring(0, normalized.Length - 4);
        }

        return normalized;
    }

    private static bool IsUsableWindow(IntPtr hwnd)
    {
        if (hwnd == IntPtr.Zero || !IsWindow(hwnd) || !IsWindowVisible(hwnd))
        {
            return false;
        }

        IntPtr owner = GetWindow(hwnd, 4);
        if (owner != IntPtr.Zero)
        {
            return false;
        }

        int style = GetWindowLong(hwnd, GwlExstyle);
        if ((style & WsExToolWindow) != 0)
        {
            return false;
        }

        return true;
    }

    private static string GetWindowTitle(IntPtr hwnd)
    {
        int length = GetWindowTextLength(hwnd);
        if (length <= 0)
        {
            return string.Empty;
        }

        StringBuilder text = new StringBuilder(length + 1);
        GetWindowText(hwnd, text, text.Capacity);
        return (text.ToString() ?? string.Empty).Trim();
    }

    private static List<WindowInfo> GetRunningWindows()
    {
        List<WindowInfo> windows = new List<WindowInfo>();
        string thisExe = string.Empty;
        try
        {
            thisExe = Process.GetCurrentProcess().MainModule.ModuleName;
        }
        catch
        {
            thisExe = string.Empty;
        }

        EnumWindows(
            delegate (IntPtr hwnd, IntPtr lParam)
            {
                if (!IsUsableWindow(hwnd))
                {
                    return true;
                }

                uint processId;
                GetWindowThreadProcessId(hwnd, out processId);
                if (processId == 0)
                {
                    return true;
                }

                string processName = string.Empty;
                string title = GetWindowTitle(hwnd);
                try
                {
                    using (Process process = Process.GetProcessById((int)processId))
                    {
                        processName = process.ProcessName;
                    }
                }
                catch
                {
                    return true;
                }

                if (string.IsNullOrEmpty(processName))
                {
                    return true;
                }

                if (!string.IsNullOrEmpty(thisExe) && string.Equals(processName + ".exe", thisExe, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }

                if (string.IsNullOrWhiteSpace(title))
                {
                    title = processName;
                }

                windows.Add(new WindowInfo
                {
                    Handle = hwnd,
                    Title = title,
                    ProcessName = processName,
                    IsMinimized = IsIconic(hwnd)
                });

                return true;
            },
            IntPtr.Zero);

        windows.Sort((left, right) => string.Compare(left.Title, right.Title, StringComparison.OrdinalIgnoreCase));
        return windows;
    }

    private static List<MonitorChoice> GetMonitors()
    {
        List<MonitorChoice> choices = new List<MonitorChoice>();
        int index = 1;
        EnumDisplayMonitors(
            IntPtr.Zero,
            IntPtr.Zero,
            delegate (IntPtr monitor, IntPtr hdc, ref RECT rc, IntPtr data)
            {
                MONITORINFO info = new MONITORINFO();
                info.cbSize = Marshal.SizeOf(typeof(MONITORINFO));
                if (GetMonitorInfo(monitor, ref info))
                {
                    choices.Add(new MonitorChoice
                    {
                        Index = index,
                        Handle = monitor,
                        WorkArea = info.rcWork
                    });
                    index += 1;
                }

                return true;
            },
            IntPtr.Zero);

        return choices;
    }

    private static void MoveWindowToMonitor(IntPtr hwnd, int monitorPreference, string monitorRect, bool maximize)
    {
        IntPtr targetMonitor = monitorPreference == MonitorFromCursor
            ? GetMonitorFromCursor()
            : GetMonitorByIdentity(monitorPreference, monitorRect);

        if (targetMonitor == IntPtr.Zero)
        {
            return;
        }

        MONITORINFO monitorInfo = new MONITORINFO();
        monitorInfo.cbSize = Marshal.SizeOf(typeof(MONITORINFO));
        if (!GetMonitorInfo(targetMonitor, ref monitorInfo))
        {
            return;
        }

        RECT workArea = monitorInfo.rcWork;
        ShowWindow(hwnd, SwRestore);

        if (maximize)
        {
            SetWindowPos(
                hwnd,
                IntPtr.Zero,
                workArea.Left,
                workArea.Top,
                workArea.Right - workArea.Left,
                workArea.Bottom - workArea.Top,
                SwpNoZorder | SwpNoActivate);

            ShowWindow(hwnd, SwShowMaximized);
            return;
        }

        RECT windowRect;
        if (!GetWindowRect(hwnd, out windowRect))
        {
            return;
        }

        int width = windowRect.Right - windowRect.Left;
        int height = windowRect.Bottom - windowRect.Top;
        int workWidth = workArea.Right - workArea.Left;
        int workHeight = workArea.Bottom - workArea.Top;
        int newX = workArea.Left + Math.Max(0, (workWidth - width) / 2);
        int newY = workArea.Top + Math.Max(0, (workHeight - height) / 2);

        SetWindowPos(hwnd, IntPtr.Zero, newX, newY, width, height, SwpNoZorder | SwpNoActivate);
        ShowWindow(hwnd, SwShow);
    }

    public static bool ActivateWindow(IntPtr hwnd)
    {
        if (IsIconic(hwnd))
        {
            ShowWindow(hwnd, SwRestore);
        }

        IntPtr foreground = GetForegroundWindow();
        uint currentThread = GetCurrentThreadId();
        uint ignoredProcessId;
        uint foregroundThread = foreground != IntPtr.Zero ? GetWindowThreadProcessId(foreground, out ignoredProcessId) : 0;
        uint targetThread = GetWindowThreadProcessId(hwnd, out ignoredProcessId);

        try
        {
            if (foregroundThread != 0 && foregroundThread != currentThread)
            {
                AttachThreadInput(foregroundThread, currentThread, true);
            }

            if (targetThread != 0 && targetThread != currentThread)
            {
                AttachThreadInput(targetThread, currentThread, true);
            }

            ShowWindow(hwnd, SwShow);
            BringWindowToTop(hwnd);
            SetForegroundWindow(hwnd);
        }
        finally
        {
            if (foregroundThread != 0 && foregroundThread != currentThread)
            {
                AttachThreadInput(foregroundThread, currentThread, false);
            }

            if (targetThread != 0 && targetThread != currentThread)
            {
                AttachThreadInput(targetThread, currentThread, false);
            }
        }

        for (int attempt = 0; attempt < 10; attempt++)
        {
            if (IsForegroundMatch(hwnd))
            {
                return true;
            }

            System.Threading.Thread.Sleep(20);
        }

        return false;
    }

    public static void ApplyTransparency(IntPtr hwnd, int transparency)
    {
        int styles = GetWindowLong(hwnd, GwlExstyle);
        if ((styles & WsExLayered) == 0)
        {
            SetWindowLong(hwnd, GwlExstyle, styles | WsExLayered);
        }

        SetLayeredWindowAttributes(hwnd, 0, (byte)transparency, LwaAlpha);
    }

    public static bool IsForegroundMatch(IntPtr hwnd)
    {
        IntPtr foreground = GetForegroundWindow();
        if (foreground == IntPtr.Zero)
        {
            return false;
        }

        if (foreground == hwnd)
        {
            return true;
        }

        return GetAncestor(foreground, GaRoot) == GetAncestor(hwnd, GaRoot);
    }

    private static IntPtr GetMonitorByIdentity(int index, string monitorRect)
    {
        RECT expectedRect;
        bool hasExpectedRect = TryParseRect(monitorRect, out expectedRect);

        Monitors.Clear();
        EnumDisplayMonitors(
            IntPtr.Zero,
            IntPtr.Zero,
            delegate (IntPtr hMonitor, IntPtr hdc, ref RECT rect, IntPtr data)
            {
                Monitors.Add(hMonitor);
                return true;
            },
            IntPtr.Zero);

        if (hasExpectedRect)
        {
            for (int i = 0; i < Monitors.Count; i++)
            {
                RECT monitorRectValue;
                if (TryGetMonitorRect(Monitors[i], out monitorRectValue) && RectEquals(expectedRect, monitorRectValue))
                {
                    return Monitors[i];
                }
            }
        }

        if (index <= 0 || index > Monitors.Count)
        {
            return IntPtr.Zero;
        }

        return Monitors[index - 1];
    }

    private static IntPtr GetMonitorFromCursor()
    {
        POINT point;
        if (!GetCursorPos(out point))
        {
            return IntPtr.Zero;
        }

        return MonitorFromPoint(point, MonitorFlagNearest);
    }

    private static bool TryParseRect(string value, out RECT rect)
    {
        rect = new RECT();
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        string[] parts = value.Split(',');
        if (parts.Length != 4)
        {
            return false;
        }

        int left;
        int top;
        int right;
        int bottom;
        if (!int.TryParse(parts[0], out left) ||
            !int.TryParse(parts[1], out top) ||
            !int.TryParse(parts[2], out right) ||
            !int.TryParse(parts[3], out bottom))
        {
            return false;
        }

        rect.Left = left;
        rect.Top = top;
        rect.Right = right;
        rect.Bottom = bottom;
        return true;
    }

    private static bool TryGetMonitorRect(IntPtr monitor, out RECT rect)
    {
        rect = new RECT();
        MONITORINFO monitorInfo = new MONITORINFO();
        monitorInfo.cbSize = Marshal.SizeOf(typeof(MONITORINFO));
        if (!GetMonitorInfo(monitor, ref monitorInfo))
        {
            return false;
        }

        rect = monitorInfo.rcMonitor;
        return true;
    }

    private static bool RectEquals(RECT left, RECT right)
    {
        return left.Left == right.Left &&
               left.Top == right.Top &&
               left.Right == right.Right &&
               left.Bottom == right.Bottom;
    }

    private static int Clamp(int value, int min, int max)
    {
        if (value < min)
        {
            return min;
        }

        if (value > max)
        {
            return max;
        }

        return value;
    }

    private static string GetSettingsPath()
    {
        string repoSettings = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "settings.ini"));
        if (Directory.Exists(Path.GetDirectoryName(repoSettings)))
        {
            return repoSettings;
        }

        return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "settings.ini");
    }

    private static string ReadIniString(string path, string section, string key, string defaultValue)
    {
        StringBuilder buffer = new StringBuilder(2048);
        GetPrivateProfileString(section, key, defaultValue ?? string.Empty, buffer, buffer.Capacity, path);
        return buffer.ToString();
    }

    private static int ReadIniInt(string path, string section, string key, int defaultValue)
    {
        string raw = ReadIniString(path, section, key, defaultValue.ToString(CultureInfo.InvariantCulture));
        int parsed;
        if (!int.TryParse(raw, NumberStyles.Integer, CultureInfo.InvariantCulture, out parsed))
        {
            return defaultValue;
        }

        return parsed;
    }

    private static void WriteIniString(string path, string section, string key, string value)
    {
        string directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrWhiteSpace(directory) && !Directory.Exists(directory))
        {
            Directory.CreateDirectory(directory);
        }

        WritePrivateProfileString(section, key, value ?? string.Empty, path);
    }

    public static List<SlotAssignment> LoadSlots()
    {
        List<SlotAssignment> slots = new List<SlotAssignment>();
        string settingsPath = GetSettingsPath();

        for (int index = 1; index <= MaxSlots; index++)
        {
            string section = "Slot_" + index.ToString(CultureInfo.InvariantCulture);
            string value = ReadIniString(settingsPath, section, "Value", string.Empty);
            string name = ReadIniString(settingsPath, section, "Name", string.Empty);
            int defaultSaved = string.IsNullOrWhiteSpace(value) ? 0 : 1;

            SlotAssignment slot = new SlotAssignment();
            slot.Index = index;
            slot.Saved = ReadIniInt(settingsPath, section, "Saved", defaultSaved) != 0;
            slot.Name = string.IsNullOrWhiteSpace(name) ? "Empty" : name;
            slot.Type = ReadIniString(settingsPath, section, "Type", "permanent");
            slot.Value = value;
            slot.ProcessName = ReadIniString(settingsPath, section, "ProcessName", string.Empty);
            slot.MatchTitle = ReadIniString(settingsPath, section, "MatchTitle", string.Empty);
            slot.Monitor = ReadIniInt(settingsPath, section, "Monitor", MonitorAuto);
            slot.Maximize = ReadIniInt(settingsPath, section, "Maximize", 0) != 0;
            slot.Transparency = Clamp(ReadIniInt(settingsPath, section, "Transparency", 255), 25, 255);
            slot.MonitorRect = ReadIniString(settingsPath, section, "MonitorRect", string.Empty);

            if (string.IsNullOrWhiteSpace(slot.ProcessName))
            {
                slot.ProcessName = string.Equals(slot.Type, "permanent", StringComparison.OrdinalIgnoreCase)
                    ? slot.Value
                    : string.Empty;
            }

            slots.Add(slot);
        }

        return slots;
    }

    public static void SaveSlot(SlotAssignment slot)
    {
        if (slot == null)
        {
            return;
        }

        string settingsPath = GetSettingsPath();
        string section = "Slot_" + slot.Index.ToString(CultureInfo.InvariantCulture);
        WriteIniString(settingsPath, section, "Saved", slot.Saved ? "1" : "0");
        WriteIniString(settingsPath, section, "Name", slot.Name);
        WriteIniString(settingsPath, section, "Type", slot.Type);
        WriteIniString(settingsPath, section, "Value", slot.Value);
        WriteIniString(settingsPath, section, "ProcessName", slot.ProcessName);
        WriteIniString(settingsPath, section, "MatchTitle", slot.MatchTitle);
        WriteIniString(settingsPath, section, "Monitor", slot.Monitor.ToString(CultureInfo.InvariantCulture));
        WriteIniString(settingsPath, section, "Maximize", slot.Maximize ? "1" : "0");
        WriteIniString(settingsPath, section, "Transparency", slot.Transparency.ToString(CultureInfo.InvariantCulture));
        WriteIniString(settingsPath, section, "MonitorRect", slot.MonitorRect);
    }

    public static string GetMonitorRectString(int monitor)
    {
        if (monitor <= 0 || monitor == MonitorFromCursor)
        {
            return string.Empty;
        }

        IntPtr monitorHandle = GetMonitorByIdentity(monitor, string.Empty);
        if (monitorHandle == IntPtr.Zero)
        {
            return string.Empty;
        }

        RECT rect;
        if (!TryGetMonitorRect(monitorHandle, out rect))
        {
            return string.Empty;
        }

        return string.Format(
            CultureInfo.InvariantCulture,
            "{0},{1},{2},{3}",
            rect.Left,
            rect.Top,
            rect.Right,
            rect.Bottom);
    }

    private static void ShowUsage()
    {
        Console.WriteLine("Usage:");
        Console.WriteLine("  WindowFlow.Switcher.exe activate --slot-type <session|permanent> --slot-value <value> ");
        Console.WriteLine("                           --monitor <0|1..N|99> --maximize <0|1> --transparency <25..255>");
        Console.WriteLine("  WindowFlow.Switcher.exe [--open]");
        Console.WriteLine("  Starts the native quick-switcher.");
        Console.WriteLine("  Quick-switcher defaults: Ctrl+Alt+Space shows running windows for direct switching.");
        Console.WriteLine("  Ctrl+Alt+WheelUp / Ctrl+Alt+WheelDown cycle through saved slots.");
        Console.WriteLine("  --open opens the picker immediately on startup.");
    }

    private delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);
    private delegate bool MonitorEnumProc(IntPtr hMonitor, IntPtr hdc, ref RECT lprcMonitor, IntPtr dwData);
    private delegate IntPtr LowLevelMouseProc(int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr lprcClip, MonitorEnumProc lpfnEnum, IntPtr dwData);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    private static extern IntPtr MonitorFromPoint(POINT pt, uint dwFlags);

    [DllImport("user32.dll")]
    private static extern bool IsWindow(IntPtr hwnd);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hwnd);

    [DllImport("user32.dll")]
    private static extern IntPtr GetWindow(IntPtr hwnd, uint uCmd);

    [DllImport("user32.dll")]
    private static extern int GetWindowText(IntPtr hwnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    private static extern int GetWindowTextLength(IntPtr hwnd);

    [DllImport("user32.dll")]
    private static extern bool GetWindowRect(IntPtr hwnd, out RECT lpRect);

    [DllImport("user32.dll")]
    private static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFO lpmi);

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hwnd, int nCmdShow);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool SetWindowPos(IntPtr hwnd, IntPtr hwndInsertAfter, int x, int y, int cx, int cy, int flags);

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hwnd);

    [DllImport("user32.dll")]
    private static extern bool BringWindowToTop(IntPtr hwnd);

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    private static extern IntPtr GetAncestor(IntPtr hwnd, uint gaFlags);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint lpdwProcessId);

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll")]
    private static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("user32.dll")]
    private static extern bool IsIconic(IntPtr hwnd);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern int GetWindowLong(IntPtr hwnd, int nIndex);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern int SetWindowLong(IntPtr hwnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool SetLayeredWindowAttributes(IntPtr hwnd, uint crKey, byte bAlpha, uint dwFlags);

    [DllImport("user32.dll")]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll")]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelMouseProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    private static extern uint GetPrivateProfileString(string lpAppName, string lpKeyName, string lpDefault, StringBuilder lpReturnedString, int nSize, string lpFileName);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    private static extern bool WritePrivateProfileString(string lpAppName, string lpKeyName, string lpString, string lpFileName);

    [StructLayout(LayoutKind.Sequential)]
    private struct POINT
    {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MONITORINFO
    {
        public int cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public int dwFlags;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MSLLHOOKSTRUCT
    {
        public POINT pt;
        public uint mouseData;
        public uint flags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    public sealed class MonitorChoice
    {
        public int Index;
        public IntPtr Handle;
        public RECT WorkArea;

        public override string ToString()
        {
            int width = WorkArea.Right - WorkArea.Left;
            int height = WorkArea.Bottom - WorkArea.Top;
            return "Monitor " + Index + " (" + width + "x" + height + ")";
        }
    }

    public sealed class WindowInfo
    {
        public IntPtr Handle;
        public string Title;
        public string ProcessName;
        public bool IsMinimized;
    }

    public sealed class SlotAssignment
    {
        public int Index;
        public bool Saved;
        public string Name;
        public string Type;
        public string Value;
        public string ProcessName;
        public string MatchTitle;
        public int Monitor;
        public bool Maximize;
        public int Transparency;
        public string MonitorRect;

        public bool HasTarget()
        {
            return !string.IsNullOrWhiteSpace(Value) && !string.Equals(Name, "Empty", StringComparison.OrdinalIgnoreCase);
        }

        public string ToMenuText()
        {
            string title = string.IsNullOrWhiteSpace(Name) ? "Empty" : Name;
            return "Slot " + Index.ToString(CultureInfo.InvariantCulture) + " - " + title;
        }
    }

    private sealed class ActivationChoice
    {
        public WindowInfo Window;
        public int Monitor;
        public bool Maximize;
        public int Transparency;
    }

    private sealed class SelectionWindow : Form
    {
        private readonly ListView _list;
        private readonly ComboBox _monitor;
        private readonly ComboBox _slot;
        private readonly CheckBox _maximize;
        private readonly TrackBar _alpha;
        private readonly Label _alphaValue;
        private readonly Button _ok;
        private readonly Button _cancel;
        private readonly Button _refresh;
        private readonly Button _saveSlot;

        private readonly Font _monoFont;

        public ActivationChoice Selection;
        public int RequestedSlotIndex;

        public SelectionWindow()
        {
            FormBorderStyle = FormBorderStyle.FixedToolWindow;
            MaximizeBox = false;
            MinimizeBox = false;
            ShowInTaskbar = false;
            StartPosition = FormStartPosition.Manual;
            Width = 760;
            Height = 470;
            TopMost = true;
            KeyPreview = true;
            Text = "Window Flow";
            Icon = SystemIcons.Application;

            _monoFont = new Font("Consolas", 9);

            Label title = new Label();
            title.Text = "Current Windows (double click / Enter):";
            title.Location = new Point(12, 10);
            title.AutoSize = true;
            Controls.Add(title);

            _list = new ListView();
            _list.View = View.Details;
            _list.FullRowSelect = true;
            _list.MultiSelect = false;
            _list.HideSelection = false;
            _list.Location = new Point(12, 32);
            _list.Size = new Size(730, 315);
            _list.Columns.Add("#", 40, HorizontalAlignment.Right);
            _list.Columns.Add("Window", 360, HorizontalAlignment.Left);
            _list.Columns.Add("Process", 190, HorizontalAlignment.Left);
            _list.Columns.Add("Handle", 100, HorizontalAlignment.Left);
            _list.Font = new Font("Segoe UI", 9);
            _list.DoubleClick += OnActivate;
            Controls.Add(_list);

            _monitor = new ComboBox();
            _monitor.DropDownStyle = ComboBoxStyle.DropDownList;
            _monitor.Location = new Point(12, 360);
            _monitor.Width = 240;
            Controls.Add(_monitor);

            Label slotLabel = new Label();
            slotLabel.Text = "Wheel slot:";
            slotLabel.Location = new Point(12, 404);
            slotLabel.Size = new Size(60, 24);
            slotLabel.TextAlign = ContentAlignment.MiddleLeft;
            Controls.Add(slotLabel);

            _slot = new ComboBox();
            _slot.DropDownStyle = ComboBoxStyle.DropDownList;
            _slot.Location = new Point(76, 405);
            _slot.Width = 240;
            Controls.Add(_slot);

            _maximize = new CheckBox();
            _maximize.Text = "Maximize";
            _maximize.Location = new Point(270, 362);
            _maximize.Size = new Size(90, 22);
            Controls.Add(_maximize);

            Label alphaLabel = new Label();
            alphaLabel.Text = "Opacity:";
            alphaLabel.Location = new Point(370, 360);
            alphaLabel.Size = new Size(56, 24);
            alphaLabel.TextAlign = ContentAlignment.MiddleLeft;
            Controls.Add(alphaLabel);

            _alpha = new TrackBar();
            _alpha.Minimum = 25;
            _alpha.Maximum = 255;
            _alpha.Value = 255;
            _alpha.TickFrequency = 20;
            _alpha.SmallChange = 1;
            _alpha.Location = new Point(432, 354);
            _alpha.Size = new Size(206, 44);
            _alpha.ValueChanged += OnAlphaChanged;
            Controls.Add(_alpha);

            _alphaValue = new Label();
            _alphaValue.Text = "255";
            _alphaValue.Location = new Point(650, 360);
            _alphaValue.Size = new Size(48, 24);
            Controls.Add(_alphaValue);

            _refresh = new Button();
            _refresh.Text = "Refresh";
            _refresh.Location = new Point(330, 405);
            _refresh.Size = new Size(72, 26);
            _refresh.Click += OnRefresh;
            Controls.Add(_refresh);

            _saveSlot = new Button();
            _saveSlot.Text = "Save Slot";
            _saveSlot.Location = new Point(410, 405);
            _saveSlot.Size = new Size(78, 26);
            _saveSlot.Enabled = false;
            _saveSlot.Click += OnSaveSlot;
            Controls.Add(_saveSlot);

            _ok = new Button();
            _ok.Text = "Activate";
            _ok.Location = new Point(576, 405);
            _ok.Size = new Size(66, 26);
            _ok.Enabled = false;
            _ok.Click += OnActivate;
            Controls.Add(_ok);

            _cancel = new Button();
            _cancel.Text = "Cancel";
            _cancel.Location = new Point(652, 405);
            _cancel.Size = new Size(72, 26);
            _cancel.Click += (s, e) => Close();
            Controls.Add(_cancel);

            _list.SelectedIndexChanged += (s, e) =>
            {
                bool hasSelection = _list.SelectedItems.Count > 0;
                _ok.Enabled = hasSelection;
                _saveSlot.Enabled = hasSelection;
            };

            _list.KeyDown += (s, e) =>
            {
                if (e.KeyCode == Keys.Enter)
                {
                    OnActivate(s, EventArgs.Empty);
                }
                else if (e.KeyCode == Keys.Escape)
                {
                    Close();
                }
            };

            this.FormClosed += (s, e) =>
            {
                if (_monoFont != null)
                {
                    _monoFont.Dispose();
                }
            };
        }

        public void Initialize(MonitorChoice[] monitors, List<WindowInfo> windows, SlotAssignment[] slots, int selectedMonitor, bool selectedMax, int selectedAlpha)
        {
            _monitor.Items.Clear();
            _monitor.Items.Add(new ComboMonitor(Program.MonitorAuto, "Auto"));
            _monitor.Items.Add(new ComboMonitor(MonitorFromCursor, "Mouse"));
            for (int i = 0; i < monitors.Length; i++)
            {
                _monitor.Items.Add(new ComboMonitor(monitors[i].Index, monitors[i].ToString()));
            }

            int idx = 0;
            int target = selectedMonitor;
            for (int i = 0; i < _monitor.Items.Count; i++)
            {
                ComboMonitor candidate = _monitor.Items[i] as ComboMonitor;
                if (candidate != null && candidate.Value == target)
                {
                    idx = i;
                    break;
                }
            }

            _monitor.SelectedIndex = idx;
            _maximize.Checked = selectedMax;
            _alpha.Value = Clamp(selectedAlpha, _alpha.Minimum, _alpha.Maximum);
            _alphaValue.Text = _alpha.Value.ToString();

            _slot.Items.Clear();
            for (int i = 0; i < slots.Length; i++)
            {
                _slot.Items.Add(new SlotChoice(slots[i].Index, slots[i].ToMenuText()));
            }

            if (_slot.Items.Count > 0)
            {
                _slot.SelectedIndex = 0;
            }

            _list.Items.Clear();
            for (int i = 0; i < windows.Count; i++)
            {
                WindowInfo window = windows[i];
                ListViewItem item = new ListViewItem((i + 1).ToString(CultureInfo.InvariantCulture));
                item.SubItems.Add(window.Title);
                item.SubItems.Add(window.ProcessName);
                item.SubItems.Add(string.Format(CultureInfo.InvariantCulture, "0x{0:X8}", window.Handle.ToInt64()));
                item.Tag = window;
                if (window.IsMinimized)
                {
                    item.Font = _monoFont;
                }

                _list.Items.Add(item);
            }

            if (_list.Items.Count > 0)
            {
                _list.Items[0].Selected = true;
            }

            bool canSubmit = _list.SelectedItems.Count > 0;
            _ok.Enabled = canSubmit;
            _saveSlot.Enabled = canSubmit;
        }

        public void PositionNearCursor()
        {
            StartPosition = FormStartPosition.Manual;
            Location = EnsureOnScreen(Cursor.Position);
        }

        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == Keys.Escape)
            {
                Close();
                return true;
            }

            if (keyData >= Keys.D1 && keyData <= Keys.D9)
            {
                int index = (keyData - Keys.D1);
                if (index < _list.Items.Count)
                {
                    _list.Items[index].Selected = true;
                    OnActivate(this, EventArgs.Empty);
                    return true;
                }
            }

            return base.ProcessCmdKey(ref msg, keyData);
        }

        private Point EnsureOnScreen(Point location)
        {
            Rectangle screen = Screen.GetWorkingArea(location);
            int x = location.X - 40;
            int y = location.Y + 12;

            if (x + Width > screen.Right)
            {
                x = screen.Right - Width;
            }

            if (y + Height > screen.Bottom)
            {
                y = screen.Bottom - Height;
            }

            if (x < screen.Left)
            {
                x = screen.Left;
            }

            if (y < screen.Top)
            {
                y = screen.Top;
            }

            return new Point(x, y);
        }

        private void OnRefresh(object sender, EventArgs e)
        {
            InitializeFromExisting();
            _ok.Enabled = _list.SelectedItems.Count > 0;
        }

        public void InitializeFromExisting()
        {
            List<WindowInfo> windows = Program.GetRunningWindows();
            object selected = _monitor.SelectedItem;
            bool selectedMax = _maximize.Checked;
            int selectedAlpha = _alpha.Value;

            List<MonitorChoice> monitorChoices = Program.GetMonitors();
            MonitorChoice[] monitorChoiceArray = new MonitorChoice[monitorChoices.Count];
            monitorChoices.CopyTo(monitorChoiceArray);
            SlotAssignment[] slotArray = Program.LoadSlots().ToArray();

            int currentMonitorChoice = selected is ComboMonitor
                ? ((ComboMonitor)selected).Value
                : Program.MonitorAuto;

            Initialize(monitorChoiceArray, windows, slotArray, currentMonitorChoice, selectedMax, selectedAlpha);
        }

        private void OnAlphaChanged(object sender, EventArgs e)
        {
            _alphaValue.Text = _alpha.Value.ToString();
        }

        private void OnActivate(object sender, EventArgs e)
        {
            SubmitSelection(DialogResult.OK);
        }

        private void OnSaveSlot(object sender, EventArgs e)
        {
            if (!(_slot.SelectedItem is SlotChoice))
            {
                return;
            }

            RequestedSlotIndex = ((SlotChoice)_slot.SelectedItem).Value;
            SubmitSelection(DialogResult.Yes);
        }

        private void SubmitSelection(DialogResult dialogResult)
        {
            if (_list.SelectedItems.Count == 0)
            {
                return;
            }

            WindowInfo window = _list.SelectedItems[0].Tag as WindowInfo;
            int monitor = Program.MonitorAuto;
            if (_monitor.SelectedItem is ComboMonitor)
            {
                monitor = ((ComboMonitor)_monitor.SelectedItem).Value;
            }

            Selection = new ActivationChoice
            {
                Window = window,
                Monitor = monitor,
                Maximize = _maximize.Checked,
                Transparency = _alpha.Value
            };

            DialogResult = dialogResult;
            Close();
        }

        private sealed class ComboMonitor
        {
            public int Value;
            public string Text;

            public ComboMonitor(int value, string text)
            {
                Value = value;
                Text = text;
            }

            public override string ToString()
            {
                return Text;
            }
        }

        private sealed class SlotChoice
        {
            public int Value;
            public string Text;

            public SlotChoice(int value, string text)
            {
                Value = value;
                Text = text;
            }

            public override string ToString()
            {
                return Text;
            }
        }
    }

    private sealed class MouseWheelHook : IDisposable
    {
        private IntPtr _hook;
        private readonly LowLevelMouseProc _proc;

        public event EventHandler WheelUp;
        public event EventHandler WheelDown;

        public MouseWheelHook()
        {
            _proc = HookCallback;
            _hook = SetWindowsHookEx(WhMouseLl, _proc, GetModuleHandle(null), 0);
        }

        public bool IsInstalled
        {
            get { return _hook != IntPtr.Zero; }
        }

        private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0 &&
                wParam.ToInt32() == WmMouseWheel &&
                IsModifierPressed(VkControl) &&
                IsModifierPressed(VkMenu))
            {
                MSLLHOOKSTRUCT data = (MSLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(MSLLHOOKSTRUCT));
                short delta = unchecked((short)((data.mouseData >> 16) & 0xFFFF));

                if (delta > 0)
                {
                    if (WheelUp != null)
                    {
                        WheelUp(this, EventArgs.Empty);
                    }
                }
                else if (delta < 0)
                {
                    if (WheelDown != null)
                    {
                        WheelDown(this, EventArgs.Empty);
                    }
                }

                return new IntPtr(1);
            }

            return CallNextHookEx(_hook, nCode, wParam, lParam);
        }

        private static bool IsModifierPressed(int virtualKey)
        {
            return (GetAsyncKeyState(virtualKey) & 0x8000) != 0;
        }

        public void Dispose()
        {
            if (_hook != IntPtr.Zero)
            {
                UnhookWindowsHookEx(_hook);
                _hook = IntPtr.Zero;
            }
        }
    }

    private sealed class HotkeyWindow : NativeWindow, IDisposable
    {
        private const int HotkeyId = 1;
        private bool _disposed;

        public event EventHandler Activated;
        private bool _registered;

        public bool IsRegistered
        {
            get { return _registered; }
        }

        public bool Register()
        {
            CreateHandle(new CreateParams());
            _registered = RegisterHotKey(Handle, HotkeyId, ModControl | ModAlt, VkSpace);
            return _registered;
        }

        public void Unregister()
        {
            if (_registered && Handle != IntPtr.Zero)
            {
                UnregisterHotKey(Handle, HotkeyId);
            }
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == WmHotkey && m.WParam.ToInt32() == HotkeyId)
            {
                if (Activated != null)
                {
                    Activated(this, EventArgs.Empty);
                }

                return;
            }

            base.WndProc(ref m);
        }

        public void Dispose()
        {
            if (_disposed)
            {
                return;
            }

            Unregister();
            DestroyHandle();
            _disposed = true;
        }
    }

    private sealed class SwitcherApplicationContext : ApplicationContext
    {
        private readonly NotifyIcon _tray;
        private readonly HotkeyWindow _hotkey;
        private readonly MouseWheelHook _wheelHook;
        private readonly ContextMenu _menu;
        private readonly List<SlotAssignment> _slots;
        private bool _openNow;
        private bool _pickerOpen;

        private int _lastMonitor;
        private bool _lastMaximize;
        private int _lastTransparency;
        private int _currentSlotIndex;

        public SwitcherApplicationContext(bool openNow)
        {
            _openNow = openNow;
            _lastMonitor = Program.MonitorAuto;
            _lastMaximize = false;
            _lastTransparency = 255;
            _currentSlotIndex = 0;
            _slots = Program.LoadSlots();

            _tray = new NotifyIcon();
            _tray.Visible = true;
            _tray.Text = "Window Flow Switcher";
            _tray.Icon = SystemIcons.Application;

            _menu = new ContextMenu();
            _menu.MenuItems.Add("Open Switcher", OnOpen);
            _menu.MenuItems.Add("Exit", OnExit);
            _tray.ContextMenu = _menu;
            _tray.DoubleClick += OnOpen;

            _tray.BalloonTipTitle = "Window Flow";
            _hotkey = new HotkeyWindow();
            _hotkey.Activated += OnHotkey;
            _wheelHook = new MouseWheelHook();
            _wheelHook.WheelUp += OnWheelUp;
            _wheelHook.WheelDown += OnWheelDown;
            if (_hotkey.Register())
            {
                _tray.BalloonTipText = "Ctrl+Alt+Space opens the picker. Ctrl+Alt+Wheel cycles saved slots.";
            }
            else
            {
                _tray.BalloonTipText = "Window Flow is running. Open Switcher from tray, then use --open to test directly.";
                MessageBox.Show(
                    "Ctrl+Alt+Space is already in use. Use tray 'Open Switcher' or launch with --open.",
                    "Window Flow",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
            }
            _tray.ShowBalloonTip(2000);
            Application.Idle += OnApplicationIdle;
        }

        private void OnApplicationIdle(object sender, EventArgs e)
        {
            Application.Idle -= OnApplicationIdle;
            if (_openNow)
            {
                _openNow = false;
                ShowPicker();
            }

            _tray.ShowBalloonTip(2000);
        }

        private void OnOpen(object sender, EventArgs e)
        {
            ShowPicker();
        }

        private void OnExit(object sender, EventArgs e)
        {
            ExitThread();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                if (_tray != null)
                {
                    _tray.Visible = false;
                    _tray.Dispose();
                }

                if (_hotkey != null)
                {
                    _hotkey.Dispose();
                }

                if (_wheelHook != null)
                {
                    _wheelHook.Dispose();
                }
            }

            base.Dispose(disposing);
        }

        private void OnHotkey(object sender, EventArgs e)
        {
            ShowPicker();
        }

        private void ShowPicker()
        {
            if (_pickerOpen)
            {
                return;
            }

            List<WindowInfo> windows = Program.GetRunningWindows();
            if (windows.Count == 0)
            {
                MessageBox.Show("No eligible windows found.", "Window Flow", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            _pickerOpen = true;
            try
            {
                using (SelectionWindow window = new SelectionWindow())
                {
                    List<MonitorChoice> monitorList = Program.GetMonitors();
                    MonitorChoice[] monitors = new MonitorChoice[monitorList.Count];
                    monitorList.CopyTo(monitors);
                    SlotAssignment[] slotArray = _slots.ToArray();
                    window.Initialize(monitors, windows, slotArray, _lastMonitor, _lastMaximize, _lastTransparency);
                    window.PositionNearCursor();
                    DialogResult result = window.ShowDialog();
                    if (result != DialogResult.OK && result != DialogResult.Yes)
                    {
                        return;
                    }

                    ActivationChoice selected = window.Selection;
                    if (selected == null || selected.Window == null)
                    {
                        return;
                    }

                    int monitor = selected.Monitor;
                    bool maximize = selected.Maximize;
                    int transparency = selected.Transparency;

                    _lastMonitor = monitor;
                    _lastMaximize = maximize;
                    _lastTransparency = transparency;

                    if (result == DialogResult.Yes)
                    {
                        SaveSelectionToSlot(window.RequestedSlotIndex, selected);
                    }

                    if (!Program.ActivateWindowHandle(selected.Window.Handle, monitor, maximize, transparency))
                    {
                        MessageBox.Show("Could not activate selected window. It may have closed.", "Window Flow", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    }
                }
            }
            finally
            {
                _pickerOpen = false;
            }
        }

        private void SaveSelectionToSlot(int slotIndex, ActivationChoice selected)
        {
            if (slotIndex <= 0 || slotIndex > _slots.Count || selected == null || selected.Window == null)
            {
                return;
            }

            SlotAssignment slot = _slots[slotIndex - 1];
            slot.Saved = true;
            slot.Name = selected.Window.Title;
            slot.Type = "permanent";
            slot.Value = selected.Window.ProcessName;
            slot.ProcessName = selected.Window.ProcessName;
            slot.MatchTitle = selected.Window.Title;
            slot.Monitor = selected.Monitor;
            slot.Maximize = selected.Maximize;
            slot.Transparency = selected.Transparency;
            slot.MonitorRect = Program.GetMonitorRectString(selected.Monitor);
            Program.SaveSlot(slot);
            _currentSlotIndex = slot.Index - 1;
            ShowTrayStatus("Saved " + slot.ToMenuText());
        }

        private void OnWheelUp(object sender, EventArgs e)
        {
            CycleSlots(-1);
        }

        private void OnWheelDown(object sender, EventArgs e)
        {
            CycleSlots(1);
        }

        private void CycleSlots(int direction)
        {
            if (_pickerOpen || _slots.Count == 0)
            {
                return;
            }

            for (int attempt = 0; attempt < _slots.Count; attempt++)
            {
                _currentSlotIndex += direction;
                if (_currentSlotIndex >= _slots.Count)
                {
                    _currentSlotIndex = 0;
                }
                else if (_currentSlotIndex < 0)
                {
                    _currentSlotIndex = _slots.Count - 1;
                }

                SlotAssignment slot = _slots[_currentSlotIndex];
                if (!slot.HasTarget())
                {
                    continue;
                }

                if (Program.ActivateSavedSlot(slot))
                {
                    ShowTrayStatus("Activated " + slot.ToMenuText());
                    return;
                }
            }

            ShowTrayStatus("No saved slots are currently available.");
        }

        private void ShowTrayStatus(string text)
        {
            _tray.BalloonTipTitle = "Window Flow";
            _tray.BalloonTipText = text;
            _tray.ShowBalloonTip(1200);
        }
    }

}
