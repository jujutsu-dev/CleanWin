using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Threading;
using System.Windows.Forms;

namespace WinQuiet.Launcher
{
    // Extracts the embedded open scripts and runs them in Windows PowerShell.
    // Files live in an administrators-only folder: the script runs elevated,
    // so a standard process must not be able to replace it.
    internal static class Program
    {
        private const string Title = "WinQuiet";
        private const string ResourcePrefix = "app/";
        private const string InstanceMutex = @"Local\WinQuiet.SingleInstance";

        [STAThread]
        private static int Main(string[] args)
        {
            try
            {
                Mutex running;
                if (Mutex.TryOpenExisting(InstanceMutex, out running))
                {
                    running.Dispose();
                    MessageBox.Show("WinQuiet is already running. Its icon is in the notification area.", Title,
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return 0;
                }

                string root = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), Title);
                Extract(root);
                Launch(root, args.Contains("--tray", StringComparer.OrdinalIgnoreCase));
                return 0;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Could not start WinQuiet:\n" + ex.Message, Title,
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 1;
            }
        }

        private static void Extract(string root)
        {
            SecureDirectory(root);
            SecureDirectory(Path.Combine(root, "src"));
            SecureDirectory(Path.Combine(root, "data"));

            Assembly assembly = Assembly.GetExecutingAssembly();
            string[] resources = assembly.GetManifestResourceNames()
                .Where(n => n.StartsWith(ResourcePrefix, StringComparison.Ordinal)).ToArray();
            if (resources.Length == 0) throw new InvalidOperationException("The program has no embedded scripts.");

            foreach (string name in resources)
            {
                string relative = name.Substring(ResourcePrefix.Length).Replace('/', Path.DirectorySeparatorChar);
                string target = Path.Combine(root, relative);

                // Delete plus CreateNew prevents writing through a planted hard link.
                if (File.Exists(target)) File.Delete(target);
                using (Stream input = assembly.GetManifestResourceStream(name))
                using (FileStream output = new FileStream(target, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                {
                    input.CopyTo(output);
                }
            }
        }

        private static void SecureDirectory(string path)
        {
            if (File.Exists(path)) throw new IOException("Found a file instead of a folder: " + path);
            if (Directory.Exists(path) && (File.GetAttributes(path) & FileAttributes.ReparsePoint) != 0)
                throw new IOException("The folder is a link, launch stopped: " + path);

            SecurityIdentifier admins = new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null);
            SecurityIdentifier system = new SecurityIdentifier(WellKnownSidType.LocalSystemSid, null);
            DirectorySecurity security = new DirectorySecurity();
            security.SetOwner(admins);
            security.SetAccessRuleProtection(true, false);
            foreach (SecurityIdentifier sid in new[] { admins, system })
            {
                security.AddAccessRule(new FileSystemAccessRule(sid, FileSystemRights.FullControl,
                    InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit,
                    PropagationFlags.None, AccessControlType.Allow));
            }

            if (Directory.Exists(path)) Directory.SetAccessControl(path, security);
            else Directory.CreateDirectory(path, security);
        }

        private static void Launch(string root, bool tray)
        {
            // Absolute path: powershell.exe must not be picked up from the current folder or PATH.
            string powershell = Path.Combine(Environment.SystemDirectory, @"WindowsPowerShell\v1.0\powershell.exe");
            if (!File.Exists(powershell)) throw new FileNotFoundException("Windows PowerShell 5.1 was not found.", powershell);

            string script = Path.Combine(root, "WinQuiet.ps1");
            string arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -STA -File \"" + script + "\"";
            if (tray) arguments += " -Tray";

            ProcessStartInfo info = new ProcessStartInfo(powershell, arguments)
            {
                UseShellExecute = false,
                CreateNoWindow = true,
                WorkingDirectory = root
            };
            using (Process.Start(info)) { }
        }
    }
}
