import 'dart:typed_data';
import 'package:sumo_shared/models/app_guide/app_guide_content_model.dart';

const String kAppGuideReplayHint = 'แตะข้อความที่มี ? บนแถบเพื่อดูซ้ำ';
const String kAppGuideBoldMarker = '**';

enum AppGuideOutcome { understood, dismissed }

enum AppGuideStepState { pending, current, done }

class AppGuideSpan {
  const AppGuideSpan(this.text, {this.bold = false});

  final String text;
  final bool bold;
}

List<AppGuideSpan> parseAppGuideSpans(String text) {
  final List<String> parts = text.split(kAppGuideBoldMarker);
  final bool balanced = parts.length.isOdd;
  final List<AppGuideSpan> spans = <AppGuideSpan>[];
  for (var i = 0; i < parts.length; i++) {
    final bool last = i == parts.length - 1;
    final bool bold = i.isOdd && (balanced || !last);
    final String part = i.isOdd && !bold
        ? '$kAppGuideBoldMarker${parts[i]}'
        : parts[i];
    if (part.isEmpty) continue;
    spans.add(AppGuideSpan(part, bold: bold));
  }
  return spans;
}

typedef AppGuideMediaLoader = Future<Uint8List> Function();

class AppGuideScript {
  const AppGuideScript({required this.key, required this.bundled});

  final String key;
  final AppGuideContentModel bundled;

  String get bundledAsset => bundled.media?.url ?? '';
}

class AppGuidePresentation {
  const AppGuidePresentation({
    required this.key,
    required this.content,
    required this.loadMedia,
  });

  final String key;
  final AppGuideContentModel content;
  final AppGuideMediaLoader loadMedia;

  String get title => content.title ?? '';

  String get subtitle => content.subtitle ?? '';

  List<AppGuideStepModel> get steps => content.stepList;
}
