import 'package:flutter_test/flutter_test.dart';
import 'package:laufen/models/km_split.dart';
import 'package:laufen/utils/formatters.dart';

void main() {
  test('5 km at a steady 5:00/km gives 5 splits of 300 s', () {
    final tracker = KmSplitTracker();
    // 10 m segments every 3 s = 5:00 /km.
    for (var i = 1; i <= 500; i++) {
      tracker.addSegment(10, i * 3.0);
    }
    final splits = tracker.finish(1500);
    expect(splits.length, 5);
    expect(splits.every((s) => s.durationSeconds == 300 && !s.isPartial), isTrue);
  });

  test('km boundary crossed mid-segment is interpolated', () {
    final tracker = KmSplitTracker();
    tracker.addSegment(900, 270); // 0.9 km at 5:00/km
    tracker.addSegment(200, 330); // crosses 1 km halfway through → at 300 s
    expect(tracker.completed.single.durationSeconds, 300);

    final splits = tracker.finish(330);
    expect(splits.length, 2);
    expect(splits.last.isPartial, isTrue);
    expect(splits.last.distanceKm, closeTo(0.1, 1e-9));
    expect(splits.last.durationSeconds, 30);
    expect(splits.last.paceMinPerKm, closeTo(5, 1e-9));
  });

  test('one long segment can close several splits', () {
    final tracker = KmSplitTracker();
    tracker.addSegment(2500, 750);
    expect(tracker.completed.map((s) => s.durationSeconds), [300, 300]);
  });

  test('pace formatter never shows :60', () {
    expect(RunFormatters.pace(5.999), '6:00 /km');
    expect(RunFormatters.pace(5.5), '5:30 /km');
  });
}
