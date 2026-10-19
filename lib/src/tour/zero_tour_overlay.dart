import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../how_to/zero_help_labels.dart';
import '../theme/zero_ui_colors.dart';
import 'zero_tour_registry.dart';
import 'zero_tour_step.dart';

/// A running tour started by [ZeroTourOverlay.show] / [ZeroTourOverlay.showAuto].
class ZeroTourSession {
  ZeroTourSession._();

  final Completer<ZeroTourResult> _done = Completer<ZeroTourResult>();
  OverlayEntry? _entry;
  List<String> Function()? _stopView;

  /// Completes once, when the tour ends for any reason.
  Future<ZeroTourResult> get result => _done.future;

  /// Whether the tour is still on screen (or still preparing).
  bool get isActive => !_done.isCompleted;

  /// Removes the tour silently: no callback runs and [result] completes with
  /// [ZeroTourOutcome.closed]. Use it when the app leaves the screen on its
  /// own (e.g. a push notification opens another page).
  void close() {
    if (!isActive) return;
    final List<String> missing = _stopView?.call() ?? const <String>[];
    _finish(ZeroTourResult(outcome: ZeroTourOutcome.closed, missing: missing));
  }

  void _finish(ZeroTourResult result) {
    if (_done.isCompleted) return;
    _entry?.remove();
    _entry = null;
    _stopView = null;
    _done.complete(result);
  }
}

/// Signature of the "ดูคลิปสาธิต" handler. The tour hides itself until the
/// returned future completes, so the app can `await` its own clip player.
typedef ZeroTourClipHandler = Future<void> Function(ZeroTourStep step);

/// "พาชมหน้านี้" — dims the screen, cuts a hole around one [ZeroTourAnchor] at
/// a time and shows a bubble with the step's text (spec `kc-help-screens.md`
/// §2, §6.3, §8.2).
///
/// UI only: it records nothing and calls no API. Report what happened from
/// the callbacks (or from [ZeroTourSession.result]):
///
/// | callback | send |
/// |---|---|
/// | [onShown] | `tour_shown` |
/// | [onAnchorMissing] | `anchor_missing` (once per anchor per run) |
/// | [onCompleted] | `tour_completed` |
/// | [onSkipped] | `tour_skipped` |
/// | [onCancelled] / `onBlocked` | nothing — not seen |
///
/// Anchor rules (same as the back office): before the first bubble every
/// anchor is given up to [anchorWait]; a missing one is skipped; more than
/// half missing cancels the tour without calling [onCompleted]. An anchor
/// that disappears mid-tour gets another [anchorWait], then is skipped.
///
/// The device back button counts as "ข้าม". The tour never navigates, and
/// scrolls a hidden anchor into view with [Scrollable.ensureVisible]
/// (instantly when the platform asks for reduced motion).
///
/// ```dart
/// final session = ZeroTourOverlay.show(
///   context,
///   steps: tour.steps, // List<ZeroTourStep> parsed from help_json
///   onShown: () => help.track('tour_shown'),
///   onAnchorMissing: (id) => help.track('anchor_missing', anchor: id),
///   onCompleted: (_) => help.markSeen(completed: true),
///   onSkipped: (_) => help.markSeen(completed: false),
/// );
/// ```
abstract final class ZeroTourOverlay {
  /// Starts a tour right away (from the sheet's "เริ่มพาชม" / "พาชมอีกครั้ง").
  ///
  /// While anchors are being waited for, a small card with "ยกเลิก" is shown.
  static ZeroTourSession show(
    BuildContext context, {
    required List<ZeroTourStep> steps,
    ZeroTourAnchorBook? book,
    ZeroHelpLabels labels = const ZeroHelpLabels(),
    ZeroUiColors colors = const ZeroUiColors(),
    Duration anchorWait = kZeroTourAnchorWait,
    VoidCallback? onShown,
    void Function(int index, ZeroTourStep step)? onStep,
    ValueChanged<String>? onAnchorMissing,
    ValueChanged<ZeroTourResult>? onCompleted,
    ValueChanged<ZeroTourResult>? onSkipped,
    ValueChanged<ZeroTourResult>? onCancelled,
    ZeroTourClipHandler? onClipTap,
  }) => _open(
    context,
    _TourConfig(
      auto: false,
      steps: List<ZeroTourStep>.unmodifiable(steps),
      labels: labels,
      colors: colors,
      anchorWait: anchorWait,
      onShown: onShown,
      onStep: onStep,
      onAnchorMissing: onAnchorMissing,
      onCompleted: onCompleted,
      onSkipped: onSkipped,
      onCancelled: onCancelled,
      onClipTap: onClipTap,
    ),
    book,
  );

  /// Offers a tour automatically (spec §6.3).
  ///
  /// Waits for the anchors invisibly (the screen stays usable), then applies
  /// [checkZeroAutoTour]: first anchor missing, or more than half missing ⇒
  /// nothing is shown, [onAnchorMissing] runs for each missing anchor,
  /// `onBlocked` runs and the result is [ZeroTourOutcome.blocked] — never
  /// [onCompleted]. Otherwise the card "พาชม N จุด ใช้ไม่ถึง 1 นาที" appears
  /// with [เริ่มเลย] (runs the tour) and [ไว้ทีหลัง] ([onPostponed],
  /// [ZeroTourOutcome.postponed]; the back button does the same here).
  ///
  /// Deciding *whether* to offer (seen state, `autoTour`, app version, at
  /// most once per app launch, three "later"s) stays in the app.
  static ZeroTourSession showAuto(
    BuildContext context, {
    required List<ZeroTourStep> steps,
    ZeroTourAnchorBook? book,
    ZeroHelpLabels labels = const ZeroHelpLabels(),
    ZeroUiColors colors = const ZeroUiColors(),
    Duration anchorWait = kZeroTourAnchorWait,
    VoidCallback? onShown,
    void Function(int index, ZeroTourStep step)? onStep,
    ValueChanged<String>? onAnchorMissing,
    ValueChanged<ZeroTourResult>? onCompleted,
    ValueChanged<ZeroTourResult>? onSkipped,
    ValueChanged<ZeroTourResult>? onCancelled,
    ValueChanged<ZeroTourResult>? onBlocked,
    VoidCallback? onPostponed,
    ZeroTourClipHandler? onClipTap,
  }) => _open(
    context,
    _TourConfig(
      auto: true,
      steps: List<ZeroTourStep>.unmodifiable(steps),
      labels: labels,
      colors: colors,
      anchorWait: anchorWait,
      onShown: onShown,
      onStep: onStep,
      onAnchorMissing: onAnchorMissing,
      onCompleted: onCompleted,
      onSkipped: onSkipped,
      onCancelled: onCancelled,
      onBlocked: onBlocked,
      onPostponed: onPostponed,
      onClipTap: onClipTap,
    ),
    book,
  );

  static ZeroTourSession _open(
    BuildContext context,
    _TourConfig config,
    ZeroTourAnchorBook? book,
  ) {
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    final ZeroTourAnchorBook? anchors =
        book ?? ZeroTourRegistry.maybeOf(context);
    final ModalRoute<dynamic>? hostRoute = ModalRoute.of(context);
    final ZeroTourSession session = ZeroTourSession._();
    final OverlayEntry entry = OverlayEntry(
      builder: (_) => _ZeroTourView(
        config: config,
        book: anchors,
        hostRoute: hostRoute,
        session: session,
      ),
    );
    session._entry = entry;
    overlay.insert(entry);
    return session;
  }
}

@immutable
class _TourConfig {
  const _TourConfig({
    required this.auto,
    required this.steps,
    required this.labels,
    required this.colors,
    required this.anchorWait,
    this.onShown,
    this.onStep,
    this.onAnchorMissing,
    this.onCompleted,
    this.onSkipped,
    this.onCancelled,
    this.onBlocked,
    this.onPostponed,
    this.onClipTap,
  });

  final bool auto;
  final List<ZeroTourStep> steps;
  final ZeroHelpLabels labels;
  final ZeroUiColors colors;
  final Duration anchorWait;
  final VoidCallback? onShown;
  final void Function(int index, ZeroTourStep step)? onStep;
  final ValueChanged<String>? onAnchorMissing;
  final ValueChanged<ZeroTourResult>? onCompleted;
  final ValueChanged<ZeroTourResult>? onSkipped;
  final ValueChanged<ZeroTourResult>? onCancelled;
  final ValueChanged<ZeroTourResult>? onBlocked;
  final VoidCallback? onPostponed;
  final ZeroTourClipHandler? onClipTap;
}

enum _Phase { resolving, invite, running }

class _ZeroTourView extends StatefulWidget {
  const _ZeroTourView({
    required this.config,
    required this.book,
    required this.hostRoute,
    required this.session,
  });

  final _TourConfig config;
  final ZeroTourAnchorBook? book;
  final ModalRoute<dynamic>? hostRoute;
  final ZeroTourSession session;

  @override
  State<_ZeroTourView> createState() => _ZeroTourViewState();
}

class _ZeroTourViewState extends State<_ZeroTourView>
    with WidgetsBindingObserver {
  static const double _holePadding = 6;
  static const double _gap = 12;
  static const double _margin = 16;

  _Phase _phase = _Phase.resolving;
  List<ZeroTourStep> _playable = const <ZeroTourStep>[];
  final List<String> _missing = <String>[];
  int _index = 0;
  BuildContext? _target;
  Rect? _hole;
  bool _shownReported = false;
  bool _ended = false;
  bool _paused = false;
  int _runId = 0;
  LocalHistoryEntry? _backEntry;

  _TourConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.session._stopView = _stopSilently;
    widget.hostRoute?.animation?.addStatusListener(_onHostStatus);
    if (!_config.auto) _ensureBackHandler();
    _start();
  }

  @override
  void dispose() {
    _runId += 1;
    WidgetsBinding.instance.removeObserver(this);
    widget.hostRoute?.animation?.removeStatusListener(_onHostStatus);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _scheduleHoleUpdate();

  // ───────────────────────────── flow ─────────────────────────────

  Future<void> _start() async {
    final int id = ++_runId;
    final ZeroTourAnchorBook? book = widget.book;
    final List<String> anchors = <String>{
      for (final ZeroTourStep step in _config.steps)
        if (step.hasAnchor) step.anchor!,
    }.toList();

    final List<bool> found = await Future.wait(<Future<bool>>[
      for (final String anchor in anchors)
        book == null
            ? Future<bool>.value(false)
            : book.waitFor(anchor, timeout: _config.anchorWait),
    ]);
    if (!mounted || id != _runId || _ended) return;

    final Set<String> foundSet = <String>{
      for (int i = 0; i < anchors.length; i++)
        if (found[i]) anchors[i],
    };
    bool isFound(String anchor) => foundSet.contains(anchor);

    final ZeroTourPlan plan = planZeroTour(_config.steps, isFound);
    for (final String anchor in plan.missing) {
      _reportMissing(anchor);
    }

    if (_config.auto && !checkZeroAutoTour(_config.steps, isFound).show) {
      _end(ZeroTourOutcome.blocked);
      return;
    }
    if (plan.cancelled) {
      _end(ZeroTourOutcome.cancelled);
      return;
    }

    _playable = plan.playable;
    if (_config.auto) {
      _ensureBackHandler();
      setState(() => _phase = _Phase.invite);
    } else {
      await _run();
    }
  }

  Future<void> _run() async {
    _ensureBackHandler();
    setState(() => _phase = _Phase.running);
    await _goTo(0, 1);
  }

  /// Moves to [position]; an anchor that vanished mid-tour gets one more
  /// wait, then its step is dropped in the direction of travel.
  Future<void> _goTo(int position, int direction) async {
    final int id = _runId;
    int pos = position;

    while (pos >= 0 && pos < _playable.length) {
      final ZeroTourStep step = _playable[pos];

      if (!step.hasAnchor) {
        _showStep(pos, null);
        return;
      }

      final BuildContext? target = await _resolve(step.anchor!);
      if (!mounted || id != _runId || _ended) return;

      if (target != null && target.mounted) {
        _showStep(pos, target);
        return;
      }

      _reportMissing(step.anchor!);
      _playable = <ZeroTourStep>[
        for (int i = 0; i < _playable.length; i++)
          if (i != pos) _playable[i],
      ];
      if (direction < 0) pos -= 1;
    }

    if (direction > 0 && _playable.isNotEmpty) {
      _end(ZeroTourOutcome.completed);
    } else if (_playable.isEmpty) {
      _end(ZeroTourOutcome.cancelled);
    } else {
      await _goTo(0, 1);
    }
  }

  Future<BuildContext?> _resolve(String anchor) async {
    final ZeroTourAnchorBook? book = widget.book;
    if (book == null) return null;
    final BuildContext? now = book.contextOf(anchor);
    if (now != null) return now;
    final bool ok = await book.waitFor(anchor, timeout: _config.anchorWait);
    return ok ? book.contextOf(anchor) : null;
  }

  void _showStep(int position, BuildContext? target) {
    setState(() {
      _index = position;
      _target = target;
      _hole = null;
    });
    if (!_shownReported) {
      _shownReported = true;
      _config.onShown?.call();
    }
    _config.onStep?.call(position, _playable[position]);

    if (target != null) {
      final bool reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      final int id = _runId;
      Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 250),
      ).whenComplete(() {
        if (mounted && id == _runId) _scheduleHoleUpdate();
      });
      _scheduleHoleUpdate();
    }
  }

  void _next() {
    if (_phase != _Phase.running) return;
    if (_index >= _playable.length - 1) {
      _end(ZeroTourOutcome.completed);
    } else {
      _goTo(_index + 1, 1);
    }
  }

  void _back() {
    if (_phase == _Phase.running && _index > 0) _goTo(_index - 1, -1);
  }

  Future<void> _clip(ZeroTourStep step) async {
    final ZeroTourClipHandler? handler = _config.onClipTap;
    if (handler == null) return;
    setState(() => _paused = true);
    try {
      await handler(step);
    } finally {
      if (mounted) {
        setState(() => _paused = false);
        _scheduleHoleUpdate();
      }
    }
  }

  void _reportMissing(String anchor) {
    if (_missing.contains(anchor)) return;
    _missing.add(anchor);
    _config.onAnchorMissing?.call(anchor);
  }

  void _end(ZeroTourOutcome outcome) {
    if (_ended) return;
    _ended = true;
    _runId += 1;
    _removeBackHandler();

    final ZeroTourResult result = ZeroTourResult(
      outcome: outcome,
      missing: List<String>.unmodifiable(_missing),
    );
    switch (outcome) {
      case ZeroTourOutcome.completed:
        _config.onCompleted?.call(result);
      case ZeroTourOutcome.skipped:
        _config.onSkipped?.call(result);
      case ZeroTourOutcome.cancelled:
        _config.onCancelled?.call(result);
      case ZeroTourOutcome.blocked:
        _config.onBlocked?.call(result);
      case ZeroTourOutcome.postponed:
        _config.onPostponed?.call();
      case ZeroTourOutcome.closed:
        break;
    }
    widget.session._finish(result);
  }

  List<String> _stopSilently() {
    _ended = true;
    _runId += 1;
    _removeBackHandler();
    return List<String>.unmodifiable(_missing);
  }

  // ───────────────────── back button / host route ─────────────────────

  /// A local history entry on the screen's own route makes the device back
  /// button close the tour instead of the screen, without pushing a route
  /// (so `Get.currentRoute` and route observers never see the tour).
  void _ensureBackHandler() {
    final ModalRoute<dynamic>? route = widget.hostRoute;
    if (_backEntry != null || route == null || !route.isActive) return;
    final LocalHistoryEntry entry = LocalHistoryEntry(
      onRemove: _onBackEntryRemoved,
    );
    _backEntry = entry;
    route.addLocalHistoryEntry(entry);
  }

  void _removeBackHandler() {
    final LocalHistoryEntry? entry = _backEntry;
    _backEntry = null;
    final ModalRoute<dynamic>? route = widget.hostRoute;
    if (entry != null && route != null && route.isActive) {
      route.removeLocalHistoryEntry(entry);
    }
  }

  void _onBackEntryRemoved() {
    if (_backEntry == null || _ended) return;
    _backEntry = null;
    _end(
      _phase == _Phase.invite
          ? ZeroTourOutcome.postponed
          : _phase == _Phase.resolving
          ? ZeroTourOutcome.cancelled
          : ZeroTourOutcome.skipped,
    );
  }

  void _onHostStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_ended) {
      _backEntry = null;
      widget.session.close();
    }
  }

  // ───────────────────────────── geometry ─────────────────────────────

  void _scheduleHoleUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHole());
    WidgetsBinding.instance.scheduleFrame();
  }

  void _updateHole() {
    if (!mounted || _phase != _Phase.running) return;
    final BuildContext? target = _target;
    final RenderObject? me = context.findRenderObject();
    if (target == null || !target.mounted || me is! RenderBox || !me.hasSize) {
      return;
    }
    final RenderObject? box = target.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;

    final Offset topLeft = box.localToGlobal(Offset.zero, ancestor: me);
    final Rect raw = topLeft & box.size;
    final Rect screen = Offset.zero & me.size;
    final Rect hole = raw.inflate(_holePadding).intersect(screen.deflate(4));
    final Rect safe = hole.isEmpty ? raw : hole;
    if (safe != _hole) setState(() => _hole = safe);
  }

  // ───────────────────────────── build ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Auto mode waits invisibly — the screen stays usable for those 1.5 s.
    if (_phase == _Phase.resolving && _config.auto) {
      return const SizedBox.shrink();
    }

    final ZeroUiColors colors = _config.colors;
    final bool anchored = _phase == _Phase.running && _target != null;
    final Rect? hole = anchored ? _hole : null;

    return Offstage(
      offstage: _paused,
      child: BlockSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Size size = constraints.biggest;
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: CustomPaint(
                      painter: _ScrimPainter(
                        hole: hole,
                        scrim: colors.overlayDark,
                        ring: colors.primary,
                      ),
                    ),
                  ),
                ),
                if (anchored && hole == null)
                  const SizedBox.shrink()
                else if (hole != null)
                  _positionedBubble(size, hole)
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(_margin),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: _card(null, 0),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _positionedBubble(Size size, Rect hole) {
    final double width = math.min(size.width - _margin * 2, 360);
    final double left = (hole.center.dx - width / 2).clamp(
      _margin,
      math.max(_margin, size.width - _margin - width),
    );
    final bool below = hole.center.dy < size.height / 2;
    final double arrowX = (hole.center.dx - left).clamp(20, width - 20);

    return Positioned(
      left: left,
      width: width,
      top: below ? hole.bottom + _gap : null,
      bottom: below ? null : size.height - hole.top + _gap,
      child: _card(below ? AxisDirection.up : AxisDirection.down, arrowX),
    );
  }

  /// [arrow] = which way the little pointer faces (null = centred card).
  Widget _card(AxisDirection? arrow, double arrowX) {
    final ZeroUiColors colors = _config.colors;
    final Widget body = switch (_phase) {
      _Phase.resolving => _PreparingBody(
        labels: _config.labels,
        colors: colors,
        onCancel: () => _end(ZeroTourOutcome.cancelled),
      ),
      _Phase.invite => _InviteBody(
        labels: _config.labels,
        colors: colors,
        stops: _playable.length,
        onStart: _run,
        onLater: () => _end(ZeroTourOutcome.postponed),
      ),
      _Phase.running => _StepBody(
        labels: _config.labels,
        colors: colors,
        step: _playable[_index],
        index: _index,
        total: _playable.length,
        onNext: _next,
        onBack: _back,
        onSkip: () => _end(ZeroTourOutcome.skipped),
        onClip: _config.onClipTap == null ? null : _clip,
      ),
    };

    final Widget card = Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: _config.labels.tourLabel,
      child: Material(
        color: colors.surface,
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(16), child: body),
      ),
    );

    if (arrow == null) return card;
    final Widget pointer = Padding(
      padding: EdgeInsets.only(left: arrowX - 8),
      child: CustomPaint(
        size: const Size(16, 8),
        painter: _ArrowPainter(
          color: colors.surface,
          up: arrow == AxisDirection.up,
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (arrow == AxisDirection.up) pointer,
        card,
        if (arrow == AxisDirection.down) pointer,
      ],
    );
  }
}

// ───────────────────────────── bubble bodies ─────────────────────────────

class _TourTag extends StatelessWidget {
  const _TourTag({required this.labels, required this.colors});

  final ZeroHelpLabels labels;
  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [
      Icon(TablerIcons.hand_click, size: 14, color: colors.primaryInk),
      Flexible(
        child: Text(
          labels.tourLabel,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.primaryInk,
          ),
        ),
      ),
    ],
  );
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.labels,
    required this.colors,
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
    required this.onClip,
  });

  final ZeroHelpLabels labels;
  final ZeroUiColors colors;
  final ZeroTourStep step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final ValueChanged<ZeroTourStep>? onClip;

  @override
  Widget build(BuildContext context) {
    final bool isFirst = index == 0;
    final bool isLast = index >= total - 1;
    final ValueChanged<ZeroTourStep>? clip = onClip;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _TourTag(labels: labels, colors: colors),
            ),
            const SizedBox(width: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                '${index + 1}/$total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            step.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.body,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: colors.textSecondary,
          ),
        ),
        if (clip != null && step.clipId != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => clip(step),
              style: TextButton.styleFrom(
                foregroundColor: colors.primaryInk,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(TablerIcons.video, size: 16),
              label: Text(labels.demoClip),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
              ),
              child: Text(labels.skip),
            ),
            const SizedBox(width: 8),
            Expanded(
              // Wraps to a second line instead of overflowing on narrow
              // screens or with large text.
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!isFirst)
                    OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.inputBorder),
                      ),
                      child: Text(labels.back),
                    ),
                  FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primaryFill,
                      foregroundColor: colors.textInverse,
                    ),
                    child: Text(isLast ? labels.done : labels.next),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InviteBody extends StatelessWidget {
  const _InviteBody({
    required this.labels,
    required this.colors,
    required this.stops,
    required this.onStart,
    required this.onLater,
  });

  final ZeroHelpLabels labels;
  final ZeroUiColors colors;
  final int stops;
  final VoidCallback onStart;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: _TourTag(labels: labels, colors: colors),
      ),
      const SizedBox(height: 8),
      Semantics(
        header: true,
        child: Text(
          labels.autoTourTitleFor(stops),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        spacing: 8,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onLater,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.inputBorder),
              ),
              child: Text(labels.autoTourLater),
            ),
          ),
          Expanded(
            child: FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryFill,
                foregroundColor: colors.textInverse,
              ),
              child: Text(labels.autoTourStart),
            ),
          ),
        ],
      ),
    ],
  );
}

class _PreparingBody extends StatelessWidget {
  const _PreparingBody({
    required this.labels,
    required this.colors,
    required this.onCancel,
  });

  final ZeroHelpLabels labels;
  final ZeroUiColors colors;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 12,
    children: [
      SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
      ),
      Expanded(
        child: Semantics(
          liveRegion: true,
          child: Text(
            labels.preparing,
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
          ),
        ),
      ),
      OutlinedButton(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.inputBorder),
        ),
        child: Text(labels.cancel),
      ),
    ],
  );
}

// ───────────────────────────── painters ─────────────────────────────

class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({
    required this.hole,
    required this.scrim,
    required this.ring,
  });

  final Rect? hole;
  final Color scrim;
  final Color ring;

  static const Radius _radius = Radius.circular(12);

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()..addRect(Offset.zero & size);
    final Rect? cut = hole;
    if (cut != null) {
      path
        ..addRRect(RRect.fromRectAndRadius(cut, _radius))
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(path, Paint()..color = scrim);
    if (cut != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(cut, _radius),
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter oldDelegate) =>
      oldDelegate.hole != hole ||
      oldDelegate.scrim != scrim ||
      oldDelegate.ring != ring;
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color, required this.up});

  final Color color;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = up
        ? (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width / 2, 0)
            ..lineTo(size.width, size.height))
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width / 2, size.height)
            ..lineTo(size.width, 0));
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.up != up;
}
