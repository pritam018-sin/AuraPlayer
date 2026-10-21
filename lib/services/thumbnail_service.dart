import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ThumbnailService {
  static Directory? _cacheDir;
  static File? _scriptFile;
  static bool _isBatchRunning = false;
  static final Set<String> _pendingVideos = {};
  static final ValueNotifier<int> updateNotifier = ValueNotifier<int>(0);

  static const String _powershellScriptContent = r'''
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
                [WindowsShellThumbnail]::Extract($v, $o, 420, 280) | Out-Null
            }
        }
    }
} elseif ($VideoPath -and $OutputPath) {
    [WindowsShellThumbnail]::Extract($VideoPath, $OutputPath, 420, 280) | Out-Null
}
''';

  static Future<void> init() async {
    try {
      final localAppData = Platform.environment['LOCALAPPDATA'] ??
          (Platform.environment['USERPROFILE'] != null
              ? '${Platform.environment['USERPROFILE']}\\AppData\\Local'
              : '.');
      final appDir = Directory('$localAppData\\AuraPlayer');
      if (!appDir.existsSync()) {
        appDir.createSync(recursive: true);
      }

      _cacheDir = Directory('${appDir.path}\\Thumbnails');
      if (!_cacheDir!.existsSync()) {
        _cacheDir!.createSync(recursive: true);
      }

      _scriptFile = File('${appDir.path}\\extract_thumb.ps1');
      if (!_scriptFile!.existsSync() || _scriptFile!.lengthSync() < 100) {
        _scriptFile!.writeAsStringSync(_powershellScriptContent);
      }
    } catch (e) {
      debugPrint('ThumbnailService init error: $e');
    }
  }

  static String _safeFilename(String videoPath) {
    int size = 0;
    try {
      final f = File(videoPath);
      if (f.existsSync()) size = f.lengthSync();
    } catch (_) {}
    final hash = videoPath.toLowerCase().hashCode.abs();
    return 'thumb_${hash}_$size.jpg';
  }

  static File? getCachedThumbnail(String videoPath) {
    if (_cacheDir == null) return null;
    final filename = _safeFilename(videoPath);
    final file = File('${_cacheDir!.path}\\$filename');
    if (file.existsSync() && file.lengthSync() > 100) {
      return file;
    }
    return null;
  }

  static Future<File?> generateThumbnail(String videoPath) async {
    final cached = getCachedThumbnail(videoPath);
    if (cached != null) return cached;

    if (!Platform.isWindows) return null;
    await init();
    if (_cacheDir == null || _scriptFile == null) return null;

    final filename = _safeFilename(videoPath);
    final outFile = File('${_cacheDir!.path}\\$filename');

    try {
      final res = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          _scriptFile!.path,
          '-VideoPath',
          videoPath,
          '-OutputPath',
          outFile.path,
        ],
        runInShell: false,
      );

      if (res.exitCode == 0 && outFile.existsSync() && outFile.lengthSync() > 100) {
        updateNotifier.value++;
        return outFile;
      }
    } catch (e) {
      debugPrint('Single thumbnail generation error: $e');
    }
    return null;
  }

  static Future<void> batchGenerateThumbnails(List<String> videoPaths) async {
    if (!Platform.isWindows || videoPaths.isEmpty) return;
    await init();
    if (_cacheDir == null || _scriptFile == null) return;

    final missing = <MapEntry<String, String>>[];
    for (final v in videoPaths) {
      if (_pendingVideos.contains(v)) continue;
      final cached = getCachedThumbnail(v);
      if (cached == null) {
        final filename = _safeFilename(v);
        missing.add(MapEntry(v, '${_cacheDir!.path}\\$filename'));
        _pendingVideos.add(v);
      }
    }

    if (missing.isEmpty) return;

    // Run batch in background without blocking UI
    _runBatchAsync(missing);
  }

  static Future<void> _runBatchAsync(List<MapEntry<String, String>> items) async {
    if (_isBatchRunning) {
      // Re-queue after small delay
      await Future.delayed(const Duration(seconds: 1));
    }
    _isBatchRunning = true;

    try {
      final tmpBatchFile = File('${_cacheDir!.path}\\batch_${DateTime.now().millisecondsSinceEpoch}.txt');
      final lines = items.map((e) => '${e.key}|${e.value}').join('\r\n');
      await tmpBatchFile.writeAsString(lines);

      final proc = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          _scriptFile!.path,
          '-BatchListFile',
          tmpBatchFile.path,
        ],
        runInShell: false,
      );

      if (proc.exitCode == 0) {
        updateNotifier.value++;
      }

      if (tmpBatchFile.existsSync()) {
        try {
          await tmpBatchFile.delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Batch thumbnail error: $e');
    } finally {
      for (final item in items) {
        _pendingVideos.remove(item.key);
      }
      _isBatchRunning = false;
    }
  }
}
