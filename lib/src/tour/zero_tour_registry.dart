import 'dart:async';

import 'package:flutter/widgets.dart';

import 'zero_tour_step.dart';

/// The book of anchors a tour can point at.
///
/// Normally created by a [ZeroTourRegistry] widget and found with
/// [ZeroTourRegistry.of]; [ZeroTourAnchor]s add themselves to the nearest one.
/// Plain Dart — no GetX, no network.
class ZeroTourAnchorBook {
  final Map<String, List<GlobalKey>> _keys = <String, List<GlobalKey>>{};

  /// Called by [ZeroTourAnchor]; apps do not need it.
  void register(String id, GlobalKey key) {
    final List<GlobalKey> keys = _keys.putIfAbsent(id, () => <GlobalKey>[]);
    if (!keys.contains(key)) keys.add(key);
  }

  /// Called by [ZeroTourAnchor]; apps do not need it.
  void unregister(String id, GlobalKey key) {
    final List<GlobalKey>? keys = _keys[id];
    if (keys == null) return;
    keys.remove(key);
    if (keys.isEmpty) _keys.remove(id);
  }

  /// Ids that currently have at least one registered anchor.
  Iterable<String> get ids => _keys.keys;

  /// The context of the first anchor [id] that is mounted and laid out with a
  /// non-empty size, or null.
  BuildContext? contextOf(String id) {
    final List<GlobalKey>? keys = _keys[id];
    if (keys == null) return null;
    for (final GlobalKey key in keys) {
      final BuildContext? context = key.currentContext;
      if (context == null || !context.mounted) continue;
      final RenderObject? box = context.findRenderObject();
      if (box is RenderBox &&
          box.attached &&
          box.hasSize &&
          !box.size.isEmpty) {
        return context;
      }
    }
    return null;
  }

  /// Whether anchor [id] is on screen right now.
  bool isShown(String id) => contextOf(id) != null;

  /// Completes with true as soon as anchor [id] is on screen, or with false
  /// after [timeout] (spec §6.3: wait ≤ 1.5 s).
  Future<bool> waitFor(
    String id, {
    Duration timeout = kZeroTourAnchorWait,
    Duration pollEvery = const Duration(milliseconds: 100),
  }) {
    if (isShown(id)) return Future<bool>.value(true);
    final Completer<bool> done = Completer<bool>();
    late final Timer poll;
    final Timer limit = Timer(timeout, () {
      poll.cancel();
      if (!done.isCompleted) done.complete(isShown(id));
    });
    poll = Timer.periodic(pollEvery, (Timer t) {
      if (isShown(id)) {
        t.cancel();
        limit.cancel();
        if (!done.isCompleted) done.complete(true);
      }
    });
    return done.future;
  }
}

/// Holds the [ZeroTourAnchorBook] for everything below it.
///
/// Put it once near the root, above the navigator, e.g. through
/// `GetMaterialApp(builder: (context, child) => ZeroTourRegistry(child: child!))`
/// next to any other app-wide overlay. Without one, [ZeroTourAnchor] does
/// nothing and every tour step counts as missing.
class ZeroTourRegistry extends StatefulWidget {
  const ZeroTourRegistry({super.key, this.book, required this.child});

  /// Supply your own book (e.g. in tests); null = the widget owns one.
  final ZeroTourAnchorBook? book;

  final Widget child;

  /// The nearest book, or null when there is no [ZeroTourRegistry] above.
  static ZeroTourAnchorBook? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ZeroTourRegistryScope>()?.book;

  /// The nearest book. Asserts that a [ZeroTourRegistry] exists above.
  static ZeroTourAnchorBook of(BuildContext context) {
    final ZeroTourAnchorBook? book = maybeOf(context);
    assert(book != null, 'ไม่พบ ZeroTourRegistry เหนือ context นี้');
    return book!;
  }

  @override
  State<ZeroTourRegistry> createState() => _ZeroTourRegistryState();
}

class _ZeroTourRegistryState extends State<ZeroTourRegistry> {
  late final ZeroTourAnchorBook _ownBook = ZeroTourAnchorBook();

  @override
  Widget build(BuildContext context) => _ZeroTourRegistryScope(
    book: widget.book ?? _ownBook,
    child: widget.child,
  );
}

class _ZeroTourRegistryScope extends InheritedWidget {
  const _ZeroTourRegistryScope({required this.book, required super.child});

  final ZeroTourAnchorBook book;

  @override
  bool updateShouldNotify(_ZeroTourRegistryScope oldWidget) =>
      oldWidget.book != book;
}

/// Marks [child] as the spot a tour step with `anchor == id` points at.
///
/// Wrap only what a tour should highlight; ids come from the screen registry
/// on the server (e.g. `job_step_on.navigate`). Several anchors may share an
/// id — the first one on screen wins. Does not change layout or semantics.
class ZeroTourAnchor extends StatefulWidget {
  const ZeroTourAnchor({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  State<ZeroTourAnchor> createState() => _ZeroTourAnchorState();
}

class _ZeroTourAnchorState extends State<ZeroTourAnchor> {
  final GlobalKey _key = GlobalKey();
  ZeroTourAnchorBook? _book;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ZeroTourAnchorBook? book = ZeroTourRegistry.maybeOf(context);
    if (!identical(book, _book)) {
      _book?.unregister(widget.id, _key);
      _book = book;
      _book?.register(widget.id, _key);
    }
  }

  @override
  void didUpdateWidget(ZeroTourAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _book?.unregister(oldWidget.id, _key);
      _book?.register(widget.id, _key);
    }
  }

  @override
  void dispose() {
    _book?.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
