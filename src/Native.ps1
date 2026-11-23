# Native calls. C# 5 syntax, as compiled by Add-Type in PowerShell 5.1.
Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace WinQuiet {
    public static class Native {
        [StructLayout(LayoutKind.Sequential)]
        struct FILETIME { public uint Low; public uint High; public ulong Value { get { return ((ulong)High << 32) | Low; } } }

        [StructLayout(LayoutKind.Sequential)]
        struct MEMORYSTATUSEX {
            public uint dwLength, dwMemoryLoad;
            public ulong ullTotalPhys, ullAvailPhys, ullTotalPageFile, ullAvailPageFile, ullTotalVirtual, ullAvailVirtual, ullAvailExtendedVirtual;
        }

        [DllImport("kernel32.dll")] static extern bool GetSystemTimes(out FILETIME idle, out FILETIME kernel, out FILETIME user);
        [DllImport("kernel32.dll")] static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX m);
        [DllImport("kernel32.dll")] static extern uint SetThreadExecutionState(uint flags);
        [DllImport("user32.dll")] public static extern uint GetClipboardSequenceNumber();
        [DllImport("user32.dll")] public static extern bool LockWorkStation();
        [DllImport("shell32.dll", CharSet = CharSet.Unicode)] static extern int SHEmptyRecycleBin(IntPtr hwnd, string root, uint flags);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        static extern IntPtr SendMessageTimeout(IntPtr hwnd, uint msg, IntPtr wp, string lp, uint flags, uint timeout, out IntPtr result);

        static ulong lastIdle, lastTotal;

        public static double CpuPercent() {
            FILETIME i, k, u;
            if (!GetSystemTimes(out i, out k, out u)) return 0;
            ulong idle = i.Value, total = k.Value + u.Value;
            ulong dIdle = idle - lastIdle, dTotal = total - lastTotal;
            bool first = lastTotal == 0;
            lastIdle = idle; lastTotal = total;
            if (first || dTotal == 0) return 0;
            return Math.Max(0, Math.Min(100, 100.0 * (dTotal - dIdle) / dTotal));
        }

        public static double[] Memory() {
            MEMORYSTATUSEX m = new MEMORYSTATUSEX();
            m.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX));
            GlobalMemoryStatusEx(ref m);
            return new double[] { m.ullTotalPhys - m.ullAvailPhys, m.ullTotalPhys, m.dwMemoryLoad };
        }

        public static void KeepAwake(bool on) {
            SetThreadExecutionState(on ? 0x80000003u : 0x80000000u);
        }

        public static int EmptyBin() { return SHEmptyRecycleBin(IntPtr.Zero, null, 7); }

        public static void BroadcastThemeChange() {
            IntPtr r;
            SendMessageTimeout((IntPtr)0xffff, 0x001A, IntPtr.Zero, "ImmersiveColorSet", 2, 500, out r);
        }
    }

    public class HotkeyWindow : NativeWindow, IDisposable {
        [DllImport("user32.dll")] static extern bool RegisterHotKey(IntPtr h, int id, uint mods, uint vk);
        [DllImport("user32.dll")] static extern bool UnregisterHotKey(IntPtr h, int id);
        readonly System.Collections.Generic.List<int> ids = new System.Collections.Generic.List<int>();
        public event EventHandler Pressed;
        public int LastId;

        public HotkeyWindow() { CreateHandle(new CreateParams()); }

        public bool Register(int id, uint mods, uint vk) {
            bool ok = RegisterHotKey(Handle, id, mods | 0x4000, vk);
            if (ok) ids.Add(id);
            return ok;
        }

        protected override void WndProc(ref Message m) {
            if (m.Msg == 0x0312) {
                LastId = m.WParam.ToInt32();
                EventHandler h = Pressed;
                if (h != null) h(this, EventArgs.Empty);
            }
            base.WndProc(ref m);
        }

        public void Dispose() {
            foreach (int id in ids) UnregisterHotKey(Handle, id);
            ids.Clear();
            DestroyHandle();
        }
    }
}
'@
