import 'dart:math';
import 'dart:typed_data';

/// Frame timing of an animated WebP, read from its `ANMF` chunks without
/// decoding any pixels — so a step's `startMs` can be mapped to a frame.
class ZeroGuideMediaTimeline {
  ZeroGuideMediaTimeline(List<int> frameDurationsMs, {this.width, this.height})
    : frameDurationsMs = List<int>.unmodifiable(
        frameDurationsMs.map((int duration) => max(duration, 0)),
      ),
      _starts = _startsOf(frameDurationsMs);

  /// A two-frame stand-in used when the file carries no frame timing: the
  /// clock still runs for [durationMs] so the steps advance.
  factory ZeroGuideMediaTimeline.fallback(int durationMs) =>
      ZeroGuideMediaTimeline(<int>[max(durationMs, 0), 0]);

  final List<int> frameDurationsMs;
  final int? width;
  final int? height;
  final List<int> _starts;

  static List<int> _startsOf(List<int> durations) {
    final List<int> starts = <int>[];
    var at = 0;
    for (final int duration in durations) {
      starts.add(at);
      at += max(duration, 0);
    }
    return starts;
  }

  int get frameCount => frameDurationsMs.length;

  int get totalMs => frameCount == 0 ? 0 : _starts.last + frameDurationsMs.last;

  int get lastFrameStartMs => frameCount == 0 ? 0 : _starts.last;

  int startOf(int frame) => _starts[frame.clamp(0, frameCount - 1)];

  /// Index of the frame on screen at [positionMs].
  int frameAt(int positionMs) {
    if (frameCount == 0) return 0;
    var low = 0;
    var high = frameCount - 1;
    while (low < high) {
      final int mid = (low + high + 1) >> 1;
      if (_starts[mid] <= positionMs) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  /// Reads `VP8X` (canvas size) and every `ANMF` duration. Null when [bytes]
  /// is not a RIFF/WEBP file or has no animation frames.
  static ZeroGuideMediaTimeline? parseWebp(Uint8List bytes) {
    if (bytes.length < 12) return null;
    if (_fourCc(bytes, 0) != 'RIFF' || _fourCc(bytes, 8) != 'WEBP') {
      return null;
    }
    final List<int> durations = <int>[];
    int? width;
    int? height;
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final String id = _fourCc(bytes, offset);
      final int size = _uint32(bytes, offset + 4);
      final int body = offset + 8;
      if (body + size > bytes.length) break;
      if (id == 'VP8X' && size >= 10) {
        width = _uint24(bytes, body + 4) + 1;
        height = _uint24(bytes, body + 7) + 1;
      } else if (id == 'ANMF' && size >= 16) {
        durations.add(_uint24(bytes, body + 12));
      }
      offset = body + size + (size & 1);
    }
    if (durations.isEmpty) return null;
    return ZeroGuideMediaTimeline(durations, width: width, height: height);
  }

  static String _fourCc(Uint8List bytes, int offset) =>
      String.fromCharCodes(bytes.sublist(offset, offset + 4));

  static int _uint24(Uint8List bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);

  static int _uint32(Uint8List bytes, int offset) =>
      _uint24(bytes, offset) | (bytes[offset + 3] << 24);
}
