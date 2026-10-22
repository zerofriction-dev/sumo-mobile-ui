import 'package:flutter/foundation.dart';

/// How long a tour waits for a missing anchor before giving up on it
/// (spec `kc-help-screens.md` §6.2 `anchor_missing`, §6.3).
const Duration kZeroTourAnchorWait = Duration(milliseconds: 1500);

/// One stop of a "พาชมหน้านี้" tour.
///
/// Mirrors one entry of `help_json.tours[].steps[]` (spec §4.5). The package
/// never fetches it — the app parses the server response and hands steps in.
@immutable
class ZeroTourStep {
  const ZeroTourStep({
    this.anchor,
    required this.title,
    required this.body,
    this.clipId,
  });

  /// Builds a step from one `steps[]` object of `help_json`
  /// (`anchor`, `title`, `body`, `clipId`). Missing text becomes `''`.
  factory ZeroTourStep.fromJson(Map<String, dynamic> json) => ZeroTourStep(
    anchor: _nonEmpty(json['anchor']),
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    clipId: _nonEmpty(json['clipId']),
  );

  /// Id of the [ZeroTourAnchor] to point at. Null or empty = a card in the
  /// middle of the screen (allowed for the first step only, by the server).
  final String? anchor;

  final String title;
  final String body;

  /// When set, the bubble shows a "ดูคลิปสาธิต" link that calls the overlay's
  /// `onClipTap` with this step.
  final String? clipId;

  /// Whether this step points at an anchor (rather than being a centred card).
  bool get hasAnchor => anchor != null && anchor!.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'anchor': anchor,
    'title': title,
    'body': body,
    'clipId': clipId,
  };

  static String? _nonEmpty(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  @override
  bool operator ==(Object other) =>
      other is ZeroTourStep &&
      other.anchor == anchor &&
      other.title == title &&
      other.body == body &&
      other.clipId == clipId;

  @override
  int get hashCode => Object.hash(anchor, title, body, clipId);

  @override
  String toString() => 'ZeroTourStep(anchor: $anchor, title: $title)';
}

/// Result of [planZeroTour]: which steps can be shown and which anchors are
/// missing.
@immutable
class ZeroTourPlan {
  const ZeroTourPlan({
    required this.playable,
    required this.missing,
    required this.cancelled,
  });

  /// Steps to show, in order. Empty when [cancelled].
  final List<ZeroTourStep> playable;

  /// Anchor ids that were not found, in step order.
  final List<String> missing;

  /// True when nothing is left to show, or more than half of the steps that
  /// have an anchor are missing — the tour must not run and must not count
  /// as seen (spec §6.3, AC-13).
  final bool cancelled;
}

/// Splits [steps] into what can be shown, given which anchors exist.
///
/// Same rule as the back office (`planHelpTour`): centred cards always stay,
/// a step whose anchor is missing is dropped, and the tour is cancelled when
/// more than half of the anchored steps are missing.
ZeroTourPlan planZeroTour(
  List<ZeroTourStep> steps,
  bool Function(String anchor) isAnchorFound,
) {
  final List<ZeroTourStep> playable = <ZeroTourStep>[];
  final List<String> missing = <String>[];
  int withAnchor = 0;

  for (final ZeroTourStep step in steps) {
    if (!step.hasAnchor) {
      playable.add(step);
      continue;
    }
    withAnchor += 1;
    if (isAnchorFound(step.anchor!)) {
      playable.add(step);
    } else {
      missing.add(step.anchor!);
    }
  }

  final bool cancelled = playable.isEmpty || missing.length * 2 > withAnchor;

  return ZeroTourPlan(
    playable: cancelled ? const <ZeroTourStep>[] : playable,
    missing: missing,
    cancelled: cancelled,
  );
}

/// Why an automatic tour was not offered.
enum ZeroAutoTourBlock {
  /// The first step points at an anchor that is not on screen.
  firstMissing,

  /// More than half of the anchored steps are missing.
  overHalf,
}

/// Result of [checkZeroAutoTour].
@immutable
class ZeroAutoTourCheck {
  const ZeroAutoTourCheck({
    required this.show,
    required this.block,
    required this.missing,
  });

  /// Whether the automatic invitation card may be shown.
  final bool show;

  /// Why not, when [show] is false.
  final ZeroAutoTourBlock? block;

  /// Anchor ids that were not found.
  final List<String> missing;
}

/// Gate before offering a tour automatically (owner's decision 16 Oct 2026,
/// same as the back office's `checkHelpAutoTourAnchors`):
///
/// * first step's anchor missing ⇒ do not offer (a centred first card never
///   counts as missing);
/// * more than half of the anchored steps missing ⇒ do not offer;
/// * otherwise offer, skipping whichever steps are missing.
///
/// Not offered = not seen: the app must not record the tour as completed.
ZeroAutoTourCheck checkZeroAutoTour(
  List<ZeroTourStep> steps,
  bool Function(String anchor) isAnchorFound,
) {
  final ZeroTourPlan plan = planZeroTour(steps, isAnchorFound);
  final ZeroTourStep? first = steps.isEmpty ? null : steps.first;

  if (first != null && first.hasAnchor && !isAnchorFound(first.anchor!)) {
    return ZeroAutoTourCheck(
      show: false,
      block: ZeroAutoTourBlock.firstMissing,
      missing: plan.missing,
    );
  }
  if (plan.cancelled) {
    return ZeroAutoTourCheck(
      show: false,
      block: ZeroAutoTourBlock.overHalf,
      missing: plan.missing,
    );
  }
  return ZeroAutoTourCheck(show: true, block: null, missing: plan.missing);
}

/// How a tour ended.
enum ZeroTourOutcome {
  /// "เสร็จแล้ว" on the last step ⇒ the app records `tour_completed`.
  completed,

  /// "ข้าม" or the device back button ⇒ the app records `tour_skipped`.
  skipped,

  /// Too many anchors missing, nothing left to show, or "ยกเลิก" while
  /// preparing. Not seen — record nothing but the `anchor_missing` events.
  cancelled,

  /// Automatic tour only: "ไว้ทีหลัง" on the invitation card. The app keeps
  /// its own local counter (spec §6.1).
  postponed,

  /// Automatic tour only: the anchor gate refused to offer the tour
  /// ([checkZeroAutoTour]). Not seen.
  blocked,

  /// Closed from code with [ZeroTourSession.close]. No callback runs.
  closed,
}

/// What a finished tour reports.
@immutable
class ZeroTourResult {
  const ZeroTourResult({required this.outcome, this.missing = const []});

  final ZeroTourOutcome outcome;

  /// Every anchor id found missing during this run (before or mid-tour).
  final List<String> missing;

  @override
  String toString() => 'ZeroTourResult($outcome, missing: $missing)';
}
