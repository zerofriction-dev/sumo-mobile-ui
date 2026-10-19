import 'package:flutter/foundation.dart';

/// Every piece of fixed wording drawn by the "สอนใช้งาน" widgets —
/// [ZeroHelpButton], [ZeroHowToSheet], the [ZeroTourOverlay] bubble and
/// [ZeroGuidePlayer].
///
/// The defaults are the approved Thai terms (spec `kc-help-screens.md` §2).
/// Apps that switch language pass [ZeroHelpLabels.en] (or their own `.tr`
/// values through the constructor); content that comes from the server —
/// sheet body, step titles and bodies — is never translated here.
@immutable
class ZeroHelpLabels {
  const ZeroHelpLabels({
    this.helpButton = 'วิธีใช้หน้านี้',
    this.sheetTitle = 'วิธีใช้หน้านี้',
    this.startTour = 'เริ่มพาชม',
    this.replayTour = 'พาชมอีกครั้ง',
    this.demoClip = 'ดูคลิปสาธิต',
    this.contact = 'ยังไม่ชัด? ติดต่อเจ้าหน้าที่',
    this.tourLabel = 'พาชมหน้านี้',
    this.back = 'ย้อนกลับ',
    this.next = 'ถัดไป',
    this.skip = 'ข้าม',
    this.done = 'เสร็จแล้ว',
    this.preparing = 'กำลังเตรียมพาชม…',
    this.cancel = 'ยกเลิก',
    this.autoTourTitle = 'พาชม {n} จุด ใช้ไม่ถึง 1 นาที',
    this.autoTourStart = 'เริ่มเลย',
    this.autoTourLater = 'ไว้ทีหลัง',
    this.clipReplay = 'ดูอีกครั้ง',
    this.clipPlay = 'เล่นคลิป',
    this.clipUnderstood = 'เข้าใจแล้ว',
    this.clipClose = 'ปิด',
    this.clipLoading = 'กำลังโหลดคลิปสาธิต…',
    this.clipError = 'โหลดคลิปสาธิตไม่สำเร็จ',
    this.clipRetry = 'ลองอีกครั้ง',
    this.clipStep = 'ขั้นที่ {n}',
  });

  /// English wording for the customer app (spec §2, column "EN").
  static const ZeroHelpLabels en = ZeroHelpLabels(
    helpButton: 'How to use this screen',
    sheetTitle: 'How to use',
    startTour: 'Start tour',
    replayTour: 'Replay tour',
    demoClip: 'Demo clip',
    contact: 'Still stuck? Contact us',
    tourLabel: 'Quick tour',
    back: 'Back',
    next: 'Next',
    skip: 'Skip',
    done: 'Done',
    preparing: 'Preparing the tour…',
    cancel: 'Cancel',
    autoTourTitle: '{n} stops, under a minute',
    autoTourStart: 'Start',
    autoTourLater: 'Later',
    clipReplay: 'Watch again',
    clipPlay: 'Play clip',
    clipUnderstood: 'Got it',
    clipClose: 'Close',
    clipLoading: 'Loading the demo clip…',
    clipError: "Couldn't load the demo clip",
    clipRetry: 'Try again',
    clipStep: 'Step {n}',
  );

  /// Tooltip and screen-reader label of the `?` button.
  final String helpButton;

  /// Heading of the how-to sheet.
  final String sheetTitle;

  /// Sheet button when the user has not seen this screen's tour yet.
  final String startTour;

  /// Sheet button when the user has already seen (or skipped) the tour.
  final String replayTour;

  /// "Watch the demo clip" link in the sheet and in a tour bubble.
  final String demoClip;

  /// Last row of the sheet, opening the app's own contact sheet.
  final String contact;

  /// Small label at the top of every tour bubble.
  final String tourLabel;

  final String back;
  final String next;
  final String skip;

  /// Primary button on the last step.
  final String done;

  /// Shown while a tour started from a button waits for its anchors.
  final String preparing;

  /// Button that abandons a tour that is still being prepared.
  final String cancel;

  /// Heading of the automatic-tour invitation card; `{n}` becomes the number
  /// of stops that can actually be shown.
  final String autoTourTitle;

  final String autoTourStart;
  final String autoTourLater;

  /// [ZeroGuidePlayer]: replays the clip from the start.
  final String clipReplay;

  /// [ZeroGuidePlayer] under reduced motion, where the clip does not start on
  /// its own: plays it once on request.
  final String clipPlay;

  /// [ZeroGuidePlayer] primary button — closes with "understood".
  final String clipUnderstood;

  /// Tooltip / screen-reader label of the player's ✕.
  final String clipClose;

  /// Screen-reader label while the clip file is loading.
  final String clipLoading;

  /// Shown in place of the clip when it cannot be loaded or decoded.
  final String clipError;

  /// Button under [clipError] that loads the clip again.
  final String clipRetry;

  /// Screen-reader prefix of a step row; `{n}` becomes the step number.
  final String clipStep;

  /// [autoTourTitle] with `{n}` replaced by [stops].
  String autoTourTitleFor(int stops) =>
      autoTourTitle.replaceAll('{n}', '$stops');

  /// [clipStep] with `{n}` replaced by [number].
  String clipStepFor(int number) => clipStep.replaceAll('{n}', '$number');
}
