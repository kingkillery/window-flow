using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;

internal static class Program
{
    private const int GaRoot = 2;
    private const int GwlExstyle = -20;
    private const int LwaAlpha = 0x2;
    private const int SwRestore = 9;
    private const int SwShow = 5;
    private const int SwShowMaximized = 3;
    private const int SwpNoZorder = 0x0004;
    private const int SwpNoActivate = 0x0010;
    private const int WsExLayered = 0x00080000;
    private static readonly List<IntPtr> Monitors = new List<IntPtr>();

    private static int Main(string[] args)
    {
        try
        {
            if (args.Length == 0 || !string.Equals(args[0], "activate", StringComparison.OrdinalIgnoreCase))
            {
                Console.Error.WriteLine("Usage: WindowFlow.Switcher.exe activate --slot-type <session|permanent> --slot-value <value> --monitor <0|1..N|99> --maximize <0|1> --transparency <25..255>");
                return 2;
            }

            Dictionary<string, string> options = ParseOptions(args, 1);
            string slotType = GetRequiredOption(options, "slot-type");
            string slotValue = GetRequiredOption(options, "slot-value");
            int monitor = ParseIntOption(options, "monitor", 0);
            string monitorRect = GetOptionalOption(options, "monitor-rect");
            bool maximize = ParseIntOption(options, "maximize", 0) != 0;
            int transparency = Clamp(ParseIntOption(options, "transparency", 255), 25, 255);

            IntPtr hwnd = ResolveTargetWindow(slotType, slotValue);
            if (hwnd == IntPtr.Zero)
            {
                Console.Error.WriteLine("Unable to resolve target window.");
                return 4;
            }

            if (monitor != 0)
            {
                MoveWindowToMonitor(hwnd, monitor, monitorRect, maximize);
            }
            else if (maximize)
            {
                ShowWindow(hwnd, SwRestore);
                ShowWindow(hwnd, SwShowMaximized);
            }

            ApplyTransparency(hwnd, transparency);

            if (!ActivateWindow(hwnd))
            {
                Console.Error.WriteLine("Unable to activate target window.");
                return 5;
            }

            return 0;
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

        if (GetWindow(hwnd, 4) != IntPtr.Zero)
        {
            return false;
        }

        return true;
    }

    private static void MoveWindowToMonitor(IntPtr hwnd, int monitorPreference, string monitorRect, bool maximize)
    {
        IntPtr targetMonitor = monitorPreference == 99
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

    private static bool ActivateWindow(IntPtr hwnd)
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

    private static void ApplyTransparency(IntPtr hwnd, int transparency)
    {
        int styles = GetWindowLong(hwnd, GwlExstyle);
        if ((styles & WsExLayered) == 0)
        {
            SetWindowLong(hwnd, GwlExstyle, styles | WsExLayered);
        }

        SetLayeredWindowAttributes(hwnd, 0, (byte)transparency, LwaAlpha);
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

        return MonitorFromPoint(point, 2);
    }

    private static bool IsForegroundMatch(IntPtr hwnd)
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

    private delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);
    private delegate bool MonitorEnumProc(IntPtr hMonitor, IntPtr hdc, ref RECT lprcMonitor, IntPtr dwData);

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

    [StructLayout(LayoutKind.Sequential)]
    private struct POINT
    {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct RECT
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
}
