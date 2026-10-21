param (
    [string]$VideoPath,
    [string]$OutputPath,
    [string]$BatchListFile
)

Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class WindowsShellThumbnail
{
    [ComImport]
    [Guid("bcc18b79-ba16-442f-80c4-8a59c30c463b")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IShellItemImageFactory
    {
        [PreserveSig]
        int GetImage(
            [In, MarshalAs(UnmanagedType.Struct)] SIZE size,
            [In] SIIGBF flags,
            [Out] out IntPtr phbm);
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct SIZE
    {
        public int cx;
        public int cy;
        public SIZE(int cx, int cy) { this.cx = cx; this.cy = cy; }
    }

    [Flags]
    private enum SIIGBF
    {
        SIIGBF_RESIZETOFIT = 0x00,
        SIIGBF_BIGGERSIZEOK = 0x01,
        SIIGBF_MEMORYONLY = 0x02,
        SIIGBF_ICONONLY = 0x04,
        SIIGBF_THUMBNAILONLY = 0x08,
        SIIGBF_INCACHEONLY = 0x10,
    }

    [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
    private static extern int SHCreateItemFromParsingName(
        [In] string pszPath,
        [In] IntPtr pbc,
        [In, MarshalAs(UnmanagedType.LPStruct)] Guid riid,
        [Out, MarshalAs(UnmanagedType.Interface)] out IShellItemImageFactory ppv);

    public static bool Extract(string filePath, string outputPath, int width, int height)
    {
        IntPtr hBitmap = IntPtr.Zero;
        try
        {
            if (System.IO.File.Exists(outputPath)) return true;
            if (!System.IO.File.Exists(filePath)) return false;

            Guid uuid = new Guid("bcc18b79-ba16-442f-80c4-8a59c30c463b");
            IShellItemImageFactory factory;
            int hr = SHCreateItemFromParsingName(filePath, IntPtr.Zero, uuid, out factory);
            if (hr != 0 || factory == null) return false;

            hr = factory.GetImage(new SIZE(width, height), SIIGBF.SIIGBF_RESIZETOFIT | SIIGBF.SIIGBF_BIGGERSIZEOK, out hBitmap);
            if (hr != 0 || hBitmap == IntPtr.Zero) return false;

            using (Bitmap bmp = Bitmap.FromHbitmap(hBitmap))
            {
                bmp.Save(outputPath, ImageFormat.Jpeg);
            }
            return true;
        }
        catch
        {
            return false;
        }
        finally
        {
            if (hBitmap != IntPtr.Zero)
            {
                DeleteObject(hBitmap);
            }
        }
    }

    [DllImport("gdi32.dll")]
    private static extern bool DeleteObject(IntPtr hObject);
}
"@ -ReferencedAssemblies System.Drawing

if ($BatchListFile -and (Test-Path $BatchListFile)) {
    Get-Content $BatchListFile | ForEach-Object {
        $parts = $_ -split '\|'
        if ($parts.Length -eq 2) {
            $v = $parts[0].Trim()
            $o = $parts[1].Trim()
            if ($v -and $o) {
                [WindowsShellThumbnail]::Extract($v, $o, 400, 260) | Out-Null
            }
        }
    }
} elseif ($VideoPath -and $OutputPath) {
    [WindowsShellThumbnail]::Extract($VideoPath, $OutputPath, 400, 260) | Out-Null
}
