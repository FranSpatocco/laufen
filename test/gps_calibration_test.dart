import 'package:flutter_test/flutter_test.dart';
import 'package:laufen/models/gps_calibration.dart';

void main() {
  const s = Duration(seconds: 1);

  test('needs consecutive good fixes, not just one', () {
    final c = GpsCalibration()..addFix(8);
    expect(c.isReady(s * 5), isFalse);
    c.addFix(9);
    expect(c.isReady(s * 5), isTrue);
  });

  test('a bad fix resets the streak', () {
    final c = GpsCalibration()
      ..addFix(8)
      ..addFix(40)
      ..addFix(8);
    expect(c.isReady(s * 5), isFalse);
    c.addFix(10);
    expect(c.isReady(s * 5), isTrue);
  });

  test('never starts before the minimum calibration time', () {
    final c = GpsCalibration()
      ..addFix(5)
      ..addFix(5)
      ..addFix(5);
    expect(c.isReady(s * 2), isFalse);
    expect(c.isReady(GpsCalibration.minDuration), isTrue);
  });

  test('the web version accepts a single good fix', () {
    final c = GpsCalibration(requiredGoodFixes: 1)..addFix(10);
    expect(c.isReady(s * 3), isTrue);
  });

  test('offers starting anyway only after the fallback time', () {
    final c = GpsCalibration()..addFix(60);
    expect(c.canStartAnyway(s * 29), isFalse);
    expect(c.canStartAnyway(GpsCalibration.fallbackAfter), isTrue);
  });

  test('signal quality goes from 0 (no fix) to 1 (good enough)', () {
    final c = GpsCalibration();
    expect(c.quality, 0);
    c.addFix(100);
    expect(c.quality, 0);
    c.addFix(57.5);
    expect(c.quality, closeTo(0.5, 0.01));
    c.addFix(12);
    expect(c.quality, 1);
  });
}
