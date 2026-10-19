import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../button/zero_button.dart';
import '../how_to/zero_help_labels.dart';
import '../theme/zero_ui_colors.dart';
import 'zero_guide_clip.dart';
import 'zero_guide_timeline.dart';

/// Fetches the WebP bytes of a clip. Apps pass their own to read a cached
/// file or a bundled fallback; the default is [zeroGuideDefaultMediaLoader].
typedef ZeroGuideMediaLoader = Future<Uint8List> Function(ZeroGuideClip clip);

/// Opens a frame decoder for the loaded bytes. Defaults to
/// `ui.instantiateImageCodec`; tests pass a fake.
typedef ZeroGuideCodecOpener = Future<ui.Codec> Function(Uint8List bytes);

/// Called when the current step changes while the clip plays or after a step
/// is tapped. [index] is 0-based.
typedef ZeroGuideStepCallback = void Function(int index, ZeroGuideStep step);

/// Called when the clip cannot be loaded or decoded — hand it to the app's
/// logger. The player shows its own error state.
typedef ZeroGuideErrorCallback =
    void Function(Object error, StackTrace stackTrace);

/// Fixed timings of [ZeroGuidePlayer] (same as the apps' former player).
abstract final class ZeroGuideTiming {
  /// Pause between opening and the clip starting on its own.
  static const Duration autoplayDelay = Duration(milliseconds: 700);

  /// Step circle / text colour change.
  static const Duration stepColor = Duration(milliseconds: 200);

  /// Longest a decoded frame may wait while decoding catches up.
  static const Duration catchUpFrame = Duration(milliseconds: 100);
}

const double kZeroGuideMaxStageWidth = 326;
const double kZeroGuideMaxStageHeight = 440;
const Size kZeroGuideFallbackStageSize = Size(390, 640);
const ValueKey<String> kZeroGuideStageKey = ValueKey<String>(
  'zero-guide-stage',
);

/// `http(s)` → the network; anything else → the app's asset bundle.
Future<Uint8List> zeroGuideDefaultMediaLoader(ZeroGuideClip clip) async {
  final String url = clip.mediaUrl;
  if (url.isEmpty) throw StateError('ZeroGuideClip has no mediaUrl');
  final Uri? uri = Uri.tryParse(url);
  final bool network =
      uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  final ByteData data = network
      ? await NetworkAssetBundle(uri).load(url)
      : await rootBundle.load(url);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// Shows [ZeroGuidePlayer] as a dialog and returns how it was closed.
///
/// A route removed from outside (e.g. `Get.back()`) also returns
/// [ZeroGuideOutcome.dismissed], but then [onDismissed] is not called — close
/// it through the player if the app needs the callback.
Future<ZeroGuideOutcome> showZeroGuidePlayer(
  BuildContext context, {
  required ZeroGuideClip clip,
  ZeroGuideMediaLoader? loadMedia,
  ZeroGuideCodecOpener? codecOpener,
  ZeroHelpLabels labels = const ZeroHelpLabels(),
  ZeroUiColors colors = const ZeroUiColors(),
  Color? barrierColor,
  bool useRootNavigator = true,
  VoidCallback? onShown,
  ZeroGuideStepCallback? onStepChanged,
  VoidCallback? onUnderstood,
  VoidCallback? onDismissed,
  ZeroGuideErrorCallback? onError,
}) async {
  final ZeroGuideOutcome? outcome = await showDialog<ZeroGuideOutcome>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: useRootNavigator,
    barrierColor: barrierColor ?? colors.textPrimary.withValues(alpha: 0.9),
    builder: (_) => ZeroGuidePlayer(
      clip: clip,
      loadMedia: loadMedia,
      codecOpener: codecOpener,
      labels: labels,
      colors: colors,
      onShown: onShown,
      onStepChanged: onStepChanged,
      onUnderstood: onUnderstood,
      onDismissed: onDismissed,
      onError: onError,
    ),
  );
  return outcome ?? ZeroGuideOutcome.dismissed;
}

/// The demo-clip player ("คลิปสาธิต") shared by provider, company and
/// super-app — the card the apps' `AppGuidePlayerDialog` used to draw.
///
/// Title and subtitle, the animated WebP on a stage sized from the clip,
/// numbered steps that light up as the clip reaches each `startMs`, then
/// "ดูอีกครั้ง" and "เข้าใจแล้ว", plus ✕ at the top.
///
/// * Starts on its own after [ZeroGuideTiming.autoplayDelay]. Tapping a step
///   jumps the clip to that step's `startMs`.
/// * **Reduced motion** (`MediaQuery.disableAnimations`): the clip does not
///   start on its own — the first frame stays still, tapping a step shows
///   that step's frame, and the first button reads "เล่นคลิป" to play it on
///   request. Colour changes are instant.
/// * "เข้าใจแล้ว" → [onUnderstood]; ✕ or the device back button →
///   [onDismissed]. Then [onClose] with the outcome, or, when [onClose] is
///   null, `Navigator.pop(outcome)` — which is how [showZeroGuidePlayer]
///   hosts it.
/// * A clip that cannot be loaded or decoded shows "โหลดคลิปสาธิตไม่สำเร็จ"
///   with "ลองอีกครั้ง" in place of the picture and reports through
///   [onError]; the steps stay readable and "เข้าใจแล้ว" still works.
///
/// UI only: no logging, no API calls, nothing stored — the app records
/// shown / understood / dismissed itself from the callbacks.
class ZeroGuidePlayer extends StatefulWidget {
  const ZeroGuidePlayer({
    super.key,
    required this.clip,
    this.loadMedia,
    this.codecOpener,
    this.labels = const ZeroHelpLabels(),
    this.colors = const ZeroUiColors(),
    this.onShown,
    this.onStepChanged,
    this.onUnderstood,
    this.onDismissed,
    this.onError,
    this.onClose,
  });

  final ZeroGuideClip clip;

  /// Defaults to [zeroGuideDefaultMediaLoader].
  final ZeroGuideMediaLoader? loadMedia;

  /// Defaults to `ui.instantiateImageCodec`.
  final ZeroGuideCodecOpener? codecOpener;

  final ZeroHelpLabels labels;
  final ZeroUiColors colors;

  /// Once, after the first frame of the player is on screen.
  final VoidCallback? onShown;
  final ZeroGuideStepCallback? onStepChanged;
  final VoidCallback? onUnderstood;
  final VoidCallback? onDismissed;
  final ZeroGuideErrorCallback? onError;

  /// Replaces the default `Navigator.pop(outcome)` — for embedding the player
  /// somewhere other than its own route.
  final ValueChanged<ZeroGuideOutcome>? onClose;

  @override
  State<ZeroGuidePlayer> createState() => ZeroGuidePlayerState();
}

/// Public so tests (here and in the apps) can read the clock.
class ZeroGuidePlayerState extends State<ZeroGuidePlayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);

  Uint8List? _bytes;
  ZeroGuideMediaTimeline? _timeline;
  ui.Codec? _codec;
  ui.Codec? _decodingCodec;
  ui.Image? _frame;
  ui.Image? _pending;
  Object? _error;
  int _decodedIndex = -1;
  int _shownAtMs = 0;
  int _generation = 0;
  Timer? _delay;
  bool _autoplay = true;
  bool _delayDone = false;
  bool _started = false;
  bool _initialised = false;
  bool _reduceMotion = false;
  bool _closed = false;
  int _baseMs = 0;
  int _positionMs = 0;
  int _current = -1;

  List<ZeroGuideStep> get _steps => widget.clip.steps;

  ZeroHelpLabels get _labels => widget.labels;

  ZeroUiColors get _colors => widget.colors;

  int get positionMs => _started ? _positionMs : 0;

  bool get isPlaying => _ticker.isActive;

  bool get isFinished =>
      _started &&
      _timeline != null &&
      _positionMs >= _timeline!.lastFrameStartMs;

  /// -1 before the clip starts, `steps.length` once it has finished.
  int get currentStep => _current;

  int get decodedFrame => _decodedIndex;

  ui.Image? get frame => _frame;

  ZeroGuideMediaTimeline? get timeline => _timeline;

  Object? get error => _error;

  bool get isLoading => _error == null && _timeline == null;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onShown?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_initialised) return;
    _initialised = true;
    _restart(autoplay: !_reduceMotion);
    unawaited(_load());
  }

  @override
  void dispose() {
    _generation++;
    _delay?.cancel();
    _ticker.dispose();
    _codec?.dispose();
    _codec = null;
    _dropPending();
    _frame?.dispose();
    _frame = null;
    super.dispose();
  }

  ZeroGuideMediaTimeline _fallbackTimeline() {
    final int lastStart = _steps.isEmpty ? 0 : _steps.last.startMs;
    final int duration = widget.clip.durationMs ?? 0;
    return ZeroGuideMediaTimeline.fallback(max(duration, lastStart));
  }

  Future<void> _load() async {
    final int generation = _generation;
    final Uint8List bytes;
    try {
      bytes = await (widget.loadMedia ?? zeroGuideDefaultMediaLoader)(
        widget.clip,
      );
    } catch (e, stackTrace) {
      if (generation == _generation) _fail(e, stackTrace);
      return;
    }
    if (!mounted || generation != _generation) return;
    ZeroGuideMediaTimeline? parsed;
    try {
      parsed = ZeroGuideMediaTimeline.parseWebp(bytes);
    } catch (_) {
      parsed = null;
    }
    setState(() {
      _bytes = bytes;
      _timeline = parsed ?? _fallbackTimeline();
    });
    _maybeStartClock();
    unawaited(_openCodec());
  }

  void _fail(Object error, StackTrace stackTrace) {
    if (!mounted || _closed) return;
    _generation++;
    _delay?.cancel();
    if (_ticker.isActive) _ticker.stop();
    _codec?.dispose();
    _codec = null;
    _decodingCodec = null;
    _dropPending();
    setState(() => _error = error);
    widget.onError?.call(error, stackTrace);
  }

  void _retry() {
    setState(() {
      _error = null;
      _bytes = null;
      _timeline = null;
      _restart(autoplay: !_reduceMotion);
    });
    unawaited(_load());
  }

  void _restart({required bool autoplay, bool delay = true}) {
    _generation++;
    _delay?.cancel();
    if (_ticker.isActive) _ticker.stop();
    _codec?.dispose();
    _codec = null;
    _decodingCodec = null;
    _dropPending();
    _decodedIndex = -1;
    _shownAtMs = 0;
    _autoplay = autoplay;
    _delayDone = !delay;
    _started = false;
    _baseMs = 0;
    _positionMs = 0;
    _current = -1;
    if (autoplay && delay) {
      _delay = Timer(ZeroGuideTiming.autoplayDelay, () {
        _delayDone = true;
        _maybeStartClock();
      });
    }
    if (_bytes != null) unawaited(_openCodec());
  }

  void _replay() {
    setState(() => _restart(autoplay: true, delay: !_reduceMotion));
    _maybeStartClock();
  }

  void _maybeStartClock() {
    if (!mounted || _started || _timeline == null || _error != null) return;
    if (_autoplay && !_delayDone) return;
    _started = true;
    if (_autoplay) _ticker.start();
    _updateStep();
    unawaited(_syncFrame());
  }

  void _onTick(Duration elapsed) {
    final ZeroGuideMediaTimeline? timeline = _timeline;
    if (timeline == null) return;
    _positionMs = min(_baseMs + elapsed.inMilliseconds, timeline.totalMs);
    if (_positionMs >= timeline.totalMs) _ticker.stop();
    _updateStep();
    _showPendingIfDue();
    unawaited(_syncFrame());
  }

  /// Jumps the clip to step [index]'s `startMs`. Keeps playing from there,
  /// or stays still under reduced motion.
  void seekToStep(int index) {
    final ZeroGuideMediaTimeline? timeline = _timeline;
    if (timeline == null || _error != null || _closed) return;
    if (index < 0 || index >= _steps.length) return;
    final int target = _steps[index].startMs.clamp(0, timeline.totalMs);
    _delay?.cancel();
    _delayDone = true;
    if (_ticker.isActive) _ticker.stop();
    _started = true;
    _baseMs = target;
    _positionMs = target;
    _shownAtMs = target;
    if (_codec != null && timeline.frameAt(target) < _decodedIndex) {
      // Frames only decode forward — rewinding means a fresh decoder.
      _generation++;
      _codec?.dispose();
      _codec = null;
      _decodingCodec = null;
      _dropPending();
      _decodedIndex = -1;
      unawaited(_openCodec());
    } else {
      unawaited(_syncFrame());
    }
    if (!_reduceMotion && target < timeline.totalMs) _ticker.start();
    _updateStep();
  }

  int _stepAt(int position) {
    if (!_started) return -1;
    if (isFinished) return _steps.length;
    var current = -1;
    for (var i = 0; i < _steps.length; i++) {
      if (_steps[i].startMs <= position) current = i;
    }
    return current;
  }

  void _updateStep() {
    final int next = _stepAt(_positionMs);
    if (next == _current || !mounted) return;
    setState(() => _current = next);
    if (next >= 0 && next < _steps.length) {
      widget.onStepChanged?.call(next, _steps[next]);
    }
  }

  Future<void> _openCodec() async {
    final Uint8List? bytes = _bytes;
    if (bytes == null) return;
    final int generation = _generation;
    try {
      final ui.Codec codec =
          await (widget.codecOpener ?? ui.instantiateImageCodec)(bytes);
      if (!mounted || generation != _generation) {
        codec.dispose();
        return;
      }
      _codec?.dispose();
      _codec = codec;
      _dropPending();
      _decodedIndex = -1;
      await _syncFrame();
    } catch (e, stackTrace) {
      if (generation == _generation) _fail(e, stackTrace);
    }
  }

  int _targetFrame(ui.Codec codec) {
    final ZeroGuideMediaTimeline? timeline = _timeline;
    final int position = _started ? _positionMs : 0;
    final int frame = timeline == null ? 0 : timeline.frameAt(position);
    return min(frame, max(codec.frameCount - 1, 0));
  }

  bool _owns(ui.Codec codec, int generation) =>
      mounted && generation == _generation && identical(_codec, codec);

  bool get _catchUpDue =>
      !_ticker.isActive ||
      positionMs - _shownAtMs >= ZeroGuideTiming.catchUpFrame.inMilliseconds;

  Future<void> _syncFrame() async {
    final ui.Codec? codec = _codec;
    if (codec == null || identical(_decodingCodec, codec)) return;
    final int generation = _generation;
    _decodingCodec = codec;
    try {
      while (_owns(codec, generation) && _decodedIndex < _targetFrame(codec)) {
        final ui.FrameInfo info = await codec.getNextFrame();
        if (!_owns(codec, generation)) {
          info.image.dispose();
          return;
        }
        _decodedIndex++;
        if (_decodedIndex < _targetFrame(codec) && !_catchUpDue) {
          _hold(info.image);
        } else {
          _show(info.image);
        }
      }
    } catch (e, stackTrace) {
      if (_owns(codec, generation)) _fail(e, stackTrace);
    } finally {
      if (identical(_decodingCodec, codec)) _decodingCodec = null;
    }
  }

  void _hold(ui.Image image) {
    _dropPending();
    _pending = image;
  }

  void _dropPending() {
    _pending?.dispose();
    _pending = null;
  }

  void _showPendingIfDue() {
    final ui.Image? pending = _pending;
    if (pending == null || !_catchUpDue) return;
    _pending = null;
    _show(pending);
  }

  void _show(ui.Image image) {
    final ui.Image? old = _frame;
    _dropPending();
    _shownAtMs = positionMs;
    setState(() => _frame = image);
    if (old != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  void _close(ZeroGuideOutcome outcome) {
    if (_closed) return;
    _closed = true;
    _generation++;
    _delay?.cancel();
    if (_ticker.isActive) _ticker.stop();
    switch (outcome) {
      case ZeroGuideOutcome.understood:
        widget.onUnderstood?.call();
      case ZeroGuideOutcome.dismissed:
        widget.onDismissed?.call();
    }
    final ValueChanged<ZeroGuideOutcome>? onClose = widget.onClose;
    if (onClose != null) {
      onClose(outcome);
    } else {
      Navigator.of(context).pop(outcome);
    }
  }

  ZeroGuideStepState _stateOf(int index) {
    if (_error != null) return ZeroGuideStepState.current;
    if (index < _current) return ZeroGuideStepState.done;
    if (index == _current) return ZeroGuideStepState.current;
    return ZeroGuideStepState.pending;
  }

  Size get _mediaSize {
    final int width = widget.clip.width ?? 0;
    final int height = widget.clip.height ?? 0;
    if (width > 0 && height > 0) {
      return Size(width.toDouble(), height.toDouble());
    }
    final int timelineWidth = _timeline?.width ?? 0;
    final int timelineHeight = _timeline?.height ?? 0;
    if (timelineWidth > 0 && timelineHeight > 0) {
      return Size(timelineWidth.toDouble(), timelineHeight.toDouble());
    }
    final ui.Image? image = _frame;
    if (image != null && image.width > 0 && image.height > 0) {
      return Size(image.width.toDouble(), image.height.toDouble());
    }
    return kZeroGuideFallbackStageSize;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _closed,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _close(ZeroGuideOutcome.dismissed);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: _colors.surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  Flexible(child: _stageArea()),
                  _stepList(),
                  _buttons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final String subtitle = widget.clip.subtitle;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 60, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  widget.clip.title,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: _colors.textPrimary,
                  ),
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: _colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _CloseButton(
            label: _labels.clipClose,
            colors: _colors,
            onPressed: () => _close(ZeroGuideOutcome.dismissed),
          ),
        ),
      ],
    );
  }

  Widget _stageArea() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size stage = _mediaSize;
        final double maxWidth = min(
          constraints.maxWidth - 32,
          kZeroGuideMaxStageWidth,
        );
        final double maxHeight = min(
          constraints.maxHeight,
          kZeroGuideMaxStageHeight,
        );
        final double scale = max(
          0,
          min(maxWidth / stage.width, maxHeight / stage.height),
        );
        return Align(
          heightFactor: 1,
          child: Container(
            key: kZeroGuideStageKey,
            width: stage.width * scale,
            height: stage.height * scale,
            decoration: BoxDecoration(
              color: _colors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _colors.overlayDark.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _colors.divider, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _stageContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _stageContent() {
    if (_error != null) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Icon(
                  TablerIcons.alert_circle,
                  size: 32,
                  color: _colors.iconTertiary,
                ),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _labels.clipError,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _colors.textSecondary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _retry,
                  style: TextButton.styleFrom(
                    foregroundColor: _colors.textPrimary,
                  ),
                  icon: const Icon(TablerIcons.refresh, size: 18),
                  label: Text(_labels.clipRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: Semantics(
            image: true,
            label: '${_labels.demoClip}: ${widget.clip.title}',
            child: ExcludeSemantics(
              child: RawImage(
                image: _frame,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
        if (_frame == null && isLoading)
          Center(
            child: Semantics(
              label: _labels.clipLoading,
              child: _reduceMotion
                  ? Icon(
                      TablerIcons.video,
                      size: 28,
                      color: _colors.iconTertiary,
                    )
                  : SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: _colors.iconTertiary,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _stepList() {
    final List<ZeroGuideStep> steps = _steps;
    final bool canSeek = _timeline != null && _error == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
              child: ZeroGuideStepRow(
                number: i + 1,
                spans: parseZeroGuideSpans(steps[i].text),
                state: _stateOf(i),
                colors: _colors,
                semanticsPrefix: _labels.clipStepFor(i + 1),
                animate: !_reduceMotion,
                onTap: canSeek ? () => seekToStep(i) : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buttons() {
    final bool failed = _error != null;
    final String first = _reduceMotion && !_ticker.isActive
        ? _labels.clipPlay
        : _labels.clipReplay;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        spacing: 12,
        children: [
          if (!failed)
            Expanded(
              child: ZeroButton(
                text: first,
                enabled: _timeline != null,
                height: 48,
                fontSize: 15,
                borderRadius: 12,
                colors: _colors,
                textColor: _colors.textPrimary,
                borderColor: _colors.inputBorder,
                backgroundColor: Colors.transparent,
                onPressed: _replay,
              ),
            ),
          Expanded(
            child: ZeroButton(
              text: _labels.clipUnderstood,
              enabled: true,
              height: 48,
              fontSize: 15,
              borderRadius: 12,
              colors: _colors,
              textColor: _colors.textInverse,
              onPressed: () => _close(ZeroGuideOutcome.understood),
            ),
          ),
        ],
      ),
    );
  }
}

/// One numbered step under the clip. Tappable when [onTap] is given.
class ZeroGuideStepRow extends StatelessWidget {
  const ZeroGuideStepRow({
    super.key,
    required this.number,
    required this.spans,
    required this.state,
    this.colors = const ZeroUiColors(),
    this.semanticsPrefix,
    this.animate = true,
    this.onTap,
  });

  final int number;
  final List<ZeroGuideSpan> spans;
  final ZeroGuideStepState state;
  final ZeroUiColors colors;

  /// e.g. "ขั้นที่ 2" — read before the step text.
  final String? semanticsPrefix;

  /// False under reduced motion: colour changes are instant.
  final bool animate;
  final VoidCallback? onTap;

  Color get circleColor => switch (state) {
    ZeroGuideStepState.pending => colors.divider,
    ZeroGuideStepState.current => colors.primary,
    ZeroGuideStepState.done => colors.guideStepDone,
  };

  Color get textColor => switch (state) {
    ZeroGuideStepState.pending => colors.guideStepPending,
    ZeroGuideStepState.current => colors.textPrimary,
    ZeroGuideStepState.done => colors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final Duration duration = animate
        ? ZeroGuideTiming.stepColor
        : Duration.zero;
    final String plain = spans.map((ZeroGuideSpan s) => s.text).join();
    final String? prefix = semanticsPrefix;
    return Semantics(
      button: onTap != null,
      selected: state == ZeroGuideStepState.current,
      label: prefix == null ? plain : '$prefix: $plain',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: AnimatedContainer(
                duration: duration,
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: colors.textInverse,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: duration,
                style: DefaultTextStyle.of(context).style.merge(
                  TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: textColor,
                    fontWeight: state == ZeroGuideStepState.current
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      for (final ZeroGuideSpan span in spans)
                        TextSpan(
                          text: span.text,
                          style: span.bold
                              ? const TextStyle(fontWeight: FontWeight.w700)
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({
    required this.label,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final ZeroUiColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          color: colors.overlayDark,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.close_rounded,
                size: 22,
                color: colors.textInverse,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
