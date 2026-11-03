import 'package:sva_core/sva_core.dart';
import 'package:test/test.dart';

void main() {
  test('M2-5: season comes from the date and the hemisphere', () {
    const oslo = 59.9;
    const kalymnos = 36.9;
    const arapiles = -36.7;
    Season at(String day, double latitude) =>
        seasonOf(DateTime.parse(day), latitude: latitude);

    expect(at('2026-01-15', oslo), Season.winter);
    expect(at('2026-03-01', oslo), Season.spring);
    expect(at('2026-05-31', oslo), Season.spring);
    expect(at('2026-06-01', kalymnos), Season.summer);
    expect(at('2026-11-02', oslo), Season.autumn);
    expect(at('2026-12-01', oslo), Season.winter);
    // South of the equator the seasons swap.
    expect(at('2026-01-15', arapiles), Season.summer);
    expect(at('2026-07-15', arapiles), Season.winter);
    expect(at('2026-04-10', arapiles), Season.autumn);
    expect(at('2026-10-10', arapiles), Season.spring);
    expect(at('2026-07-15', 0), Season.summer, reason: 'the equator is north');
    expect(Season.autumn.key, 'season.autumn');
  });
}
