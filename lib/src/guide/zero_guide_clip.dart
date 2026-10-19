import 'package:flutter/foundation.dart';

/// How a [ZeroGuidePlayer] was closed.
///
/// * [understood] — "เข้าใจแล้ว".
/// * [dismissed] — ✕, the device back button, or the route going away.
enum ZeroGuideOutcome { understood, dismissed }

/// Where one step stands against the clip's clock.
enum ZeroGuideStepState { pending, current, done }

/// The only media type the player can draw (spec `app-guides-media.md` §3.1).
const String kZeroGuideMediaTypeWebp = 'webp';

/// One numbered line under a demo clip — `{ "text": "…", "startMs": 0 }`.
///
/// [text] may mark names with `**bold**` (see [parseZeroGuideSpans]).
/// [startMs] is when the step becomes current; the player also seeks there
/// when the step is tapped.
@immutable
class ZeroGuideStep {
  const ZeroGuideStep({this.text = '', this.startMs = 0});

  factory ZeroGuideStep.fromJson(Map<String, dynamic> json) => ZeroGuideStep(
    text: json['text'] is String ? json['text'] as String : '',
    startMs: zeroGuideToInt(json['startMs']) ?? 0,
  );

  final String text;
  final int startMs;

  Map<String, dynamic> toJson() => {'text': text, 'startMs': startMs};

  @override
  bool operator ==(Object other) =>
      other is ZeroGuideStep && other.text == text && other.startMs == startMs;

  @override
  int get hashCode => Object.hash(text, startMs);
}

/// A demo clip ("คลิปสาธิต") — an animated WebP plus 1–6 timed steps.
///
/// [ZeroGuideClip.fromJson] reads both shapes the apps receive:
///
/// * **a clip from the how-to panel** (`kc-help-screens.md` §5.3
///   `documents[].clips[]`) — `id`, `type: "app_guide"`, `guideKey`, `title`,
///   `mediaUrl`, `width`, `height`, `durationMs`, `steps`;
/// * **an app_guide version** (`app-guides-media.md` §3.1, the apps'
///   `AppGuideContentModel`) — `version`, `revision`, `title`, `subtitle`,
///   `steps`, `media { type, url, width, height, durationMs, bytes }`,
///   `minAppVersion`.
///
/// Missing text becomes `''`; numbers given as strings are accepted.
@immutable
class ZeroGuideClip {
  const ZeroGuideClip({
    this.id,
    this.guideKey,
    this.title = '',
    this.subtitle = '',
    this.mediaUrl = '',
    this.mediaType = kZeroGuideMediaTypeWebp,
    this.width,
    this.height,
    this.durationMs,
    this.steps = const <ZeroGuideStep>[],
    this.version,
    this.revision,
    this.minAppVersion,
  });

  factory ZeroGuideClip.fromJson(Map<String, dynamic> json) {
    final Object? rawMedia = json['media'];
    final Map<String, dynamic>? media = rawMedia is Map
        ? Map<String, dynamic>.from(rawMedia)
        : null;
    final Object? rawSteps = json['steps'];
    return ZeroGuideClip(
      id: _nonEmpty(json['id']),
      guideKey: _nonEmpty(json['guideKey']) ?? _nonEmpty(json['key']),
      title: _text(json['title']),
      subtitle: _text(json['subtitle']),
      mediaUrl: media != null ? _text(media['url']) : _text(json['mediaUrl']),
      mediaType: media != null
          ? _text(media['type'])
          : (_nonEmpty(json['mediaType']) ?? kZeroGuideMediaTypeWebp),
      width: zeroGuideToInt((media ?? json)['width']),
      height: zeroGuideToInt((media ?? json)['height']),
      durationMs: zeroGuideToInt((media ?? json)['durationMs']),
      steps: rawSteps is List
          ? List<ZeroGuideStep>.unmodifiable(
              rawSteps.whereType<Map>().map(
                (Map step) =>
                    ZeroGuideStep.fromJson(Map<String, dynamic>.from(step)),
              ),
            )
          : const <ZeroGuideStep>[],
      version: zeroGuideToInt(json['version']),
      revision: zeroGuideToInt(json['revision']),
      minAppVersion: _nonEmpty(json['minAppVersion']),
    );
  }

  /// `clips[].id` inside the panel (what a tour step's `clipId` points at).
  /// Null for an app_guide version.
  final String? id;

  /// app_guide key, e.g. `provider.job.photo_angles`.
  final String? guideKey;

  final String title;

  /// Shown under [title]; hidden when empty.
  final String subtitle;

  /// `https://…webp` (panel / server) or a bundled asset path. The default
  /// loader picks the network for `http(s)` and the asset bundle otherwise.
  final String mediaUrl;

  final String mediaType;
  final int? width;
  final int? height;
  final int? durationMs;
  final List<ZeroGuideStep> steps;

  final int? version;
  final int? revision;
  final String? minAppVersion;

  /// Whether the player can show it: at least one step, a WebP, a URL.
  bool get isPlayable =>
      steps.isNotEmpty &&
      mediaType == kZeroGuideMediaTypeWebp &&
      mediaUrl.isNotEmpty;

  /// The clip whose [id] is [clipId] — for a tour step's `clipId`. Null when
  /// [clipId] is null or no clip matches.
  static ZeroGuideClip? byId(Iterable<ZeroGuideClip> clips, String? clipId) {
    if (clipId == null) return null;
    for (final ZeroGuideClip clip in clips) {
      if (clip.id == clipId) return clip;
    }
    return null;
  }

  ZeroGuideClip copyWith({
    String? mediaUrl,
    String? title,
    String? subtitle,
    List<ZeroGuideStep>? steps,
  }) => ZeroGuideClip(
    id: id,
    guideKey: guideKey,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    mediaType: mediaType,
    width: width,
    height: height,
    durationMs: durationMs,
    steps: steps ?? this.steps,
    version: version,
    revision: revision,
    minAppVersion: minAppVersion,
  );

  /// The panel shape (§5.3 `clips[]`).
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'type': 'app_guide',
    if (guideKey != null) 'guideKey': guideKey,
    'title': title,
    if (subtitle.isNotEmpty) 'subtitle': subtitle,
    'mediaUrl': mediaUrl,
    'width': width,
    'height': height,
    'durationMs': durationMs,
    'steps': [for (final ZeroGuideStep step in steps) step.toJson()],
  };

  static String _text(Object? value) => value is String ? value : '';

  static String? _nonEmpty(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}

/// One run of step text, bold or not.
@immutable
class ZeroGuideSpan {
  const ZeroGuideSpan(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  bool operator ==(Object other) =>
      other is ZeroGuideSpan && other.text == text && other.bold == bold;

  @override
  int get hashCode => Object.hash(text, bold);
}

const String _kBoldMarker = '**';

/// Splits step text on `**`: `แตะ **ปุ่มเอ**` → `แตะ ` + bold `ปุ่มเอ`.
/// An unpaired trailing `**` is kept as text.
List<ZeroGuideSpan> parseZeroGuideSpans(String text) {
  final List<String> parts = text.split(_kBoldMarker);
  final bool balanced = parts.length.isOdd;
  final List<ZeroGuideSpan> spans = <ZeroGuideSpan>[];
  for (var i = 0; i < parts.length; i++) {
    final bool last = i == parts.length - 1;
    final bool bold = i.isOdd && (balanced || !last);
    final String part = i.isOdd && !bold
        ? '$_kBoldMarker${parts[i]}'
        : parts[i];
    if (part.isEmpty) continue;
    spans.add(ZeroGuideSpan(part, bold: bold));
  }
  return spans;
}

/// `int`, `num` or a numeric string → `int`; anything else → null.
int? zeroGuideToInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
