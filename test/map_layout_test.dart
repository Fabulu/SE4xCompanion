import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/pages/map_page.dart';

const double _kHexRadius = 34.0;
final double _kXSpacing = _kHexRadius * math.sqrt(3); // ~58.8897
const double _kYSpacing = _kHexRadius * 1.5; // 51.0
const double _kTol = 0.01;

MapHexState _hex(int q, int r) =>
    MapHexState(coord: HexCoord(q, r), terrain: HexTerrain.deepSpace);

Offset _posOf(MapLayoutMetrics m, int q, int r) {
  final pos = m.positions['$q,$r'];
  expect(pos, isNotNull, reason: 'Expected position for hex ($q,$r) to exist');
  return pos!;
}

void main() {
  group('computeLayoutMetrics formula correctness (pointy-top)', () {
    test('single hex at (0,0) has expected center, hexWidth, hexHeight', () {
      final metrics = computeLayoutMetrics([_hex(0, 0)]);
      final pos = _posOf(metrics, 0, 0);

      expect(pos.dx, closeTo(0.0, _kTol),
          reason: 'Lone hex x should be at origin (rowIndex 0, even)');
      expect(pos.dy, closeTo(0.0, _kTol),
          reason: 'Lone hex y should be at origin');
      expect(metrics.hexWidth, closeTo(_kXSpacing, _kTol),
          reason: 'hexWidth = sqrt(3) * R');
      expect(metrics.hexHeight, closeTo(2 * _kHexRadius, _kTol),
          reason: 'hexHeight = 2 * R');
    });

    test('two same-row hexes have x-pitch = sqrt(3)*R', () {
      final metrics = computeLayoutMetrics([_hex(0, 0), _hex(1, 0)]);
      final a = _posOf(metrics, 0, 0);
      final b = _posOf(metrics, 1, 0);

      expect(b.dx - a.dx, closeTo(_kXSpacing, _kTol),
          reason: 'Same-row horizontal pitch must equal sqrt(3)*R (~58.89)');
      expect(b.dy - a.dy, closeTo(0.0, _kTol),
          reason: 'Same-row hexes share the same y');
      expect(_kXSpacing, closeTo(58.89, 0.01),
          reason: 'sqrt(3)*34 should be ~58.89 (sanity check)');
    });

    test('adjacent rows have y-pitch = 1.5*R and odd row offset by +0.5*xSpacing', () {
      final metrics = computeLayoutMetrics([_hex(0, 0), _hex(0, 1)]);
      final even = _posOf(metrics, 0, 0);
      final odd = _posOf(metrics, 0, 1);

      expect(odd.dy - even.dy, closeTo(_kYSpacing, _kTol),
          reason: 'Vertical pitch between adjacent rows = 1.5*R (51.0 at R=34)');
      expect(_kYSpacing, closeTo(51.0, _kTol),
          reason: '1.5*34 should be 51.0 (sanity check)');
      expect(odd.dx - even.dx, closeTo(0.5 * _kXSpacing, _kTol),
          reason: 'Odd row x must be offset by +0.5*sqrt(3)*R from even row');
    });

    test('even-row hexes share x for same q; odd-row hexes share x (offset by half xSpacing)', () {
      // minR normalization: choose minR = -2 so rowIndex values are 0,1,2,3,4,5 for r=-2..3
      final hexes = <MapHexState>[
        _hex(0, -2), _hex(0, 0), _hex(0, 2), // rowIndex 0,2,4 -> even
        _hex(0, -1), _hex(0, 1), _hex(0, 3), // rowIndex 1,3,5 -> odd
      ];
      final metrics = computeLayoutMetrics(hexes);

      final eRm2 = _posOf(metrics, 0, -2);
      final eR0 = _posOf(metrics, 0, 0);
      final eR2 = _posOf(metrics, 0, 2);
      expect(eR0.dx, closeTo(eRm2.dx, _kTol),
          reason: 'Even-index rows share x for same q (r=-2 vs r=0)');
      expect(eR2.dx, closeTo(eRm2.dx, _kTol),
          reason: 'Even-index rows share x for same q (r=-2 vs r=2)');

      final oRm1 = _posOf(metrics, 0, -1);
      final oR1 = _posOf(metrics, 0, 1);
      final oR3 = _posOf(metrics, 0, 3);
      expect(oR1.dx, closeTo(oRm1.dx, _kTol),
          reason: 'Odd-index rows share x for same q (r=-1 vs r=1)');
      expect(oR3.dx, closeTo(oRm1.dx, _kTol),
          reason: 'Odd-index rows share x for same q (r=-1 vs r=3)');

      expect(oRm1.dx - eRm2.dx, closeTo(0.5 * _kXSpacing, _kTol),
          reason: 'Odd rows are offset by 0.5*xSpacing from even rows');
    });
  });

  group('MapLayoutPreset.special5p structural tests', () {
    final hexes = GameMapState.defaultHexesFor(MapLayoutPreset.special5p);
    const expectedRowCounts = [
      3, 5, 8, 10, 12, 14, 15, 16, 16, 15, 15, 14, 13, 12, 13, 12, 11, 10,
    ];
    const expectedStartCols = [
      -1, -2, -3, -5, -5, -7, -7, -8, -8, -8, -7, -7, -6, -6, -6, -6, -5, -5,
    ];

    test('has 214 hexes across 18 rows', () {
      expect(hexes, hasLength(214), reason: 'special5p should have 214 hexes');
      final distinctRows = hexes.map((h) => h.coord.r).toSet();
      expect(distinctRows, hasLength(18),
          reason: 'special5p should have 18 distinct r values');
    });

    test('row counts match the expected pentagon row-lengths', () {
      final state =
          GameMapState(layoutPreset: MapLayoutPreset.special5p, hexes: hexes);
      expect(state.rowLengths, expectedRowCounts,
          reason: 'Row counts must match the measured pentagon layout');
    });

    test('per-row leftmost q matches measured startCols', () {
      final rows = _rowsByR(hexes);
      final sortedRKeys = rows.keys.toList()..sort();
      for (var rowIndex = 0; rowIndex < sortedRKeys.length; rowIndex++) {
        final r = sortedRKeys[rowIndex];
        final qs = rows[r]!..sort();
        expect(qs.first, expectedStartCols[rowIndex],
            reason:
                'Row $rowIndex (r=$r) startCol should be ${expectedStartCols[rowIndex]}');
      }
    });

    test('per-row rightmost q = startCol + rowLength - 1', () {
      final rows = _rowsByR(hexes);
      final sortedRKeys = rows.keys.toList()..sort();
      for (var rowIndex = 0; rowIndex < sortedRKeys.length; rowIndex++) {
        final r = sortedRKeys[rowIndex];
        final qs = rows[r]!..sort();
        final expectedRightmost =
            expectedStartCols[rowIndex] + expectedRowCounts[rowIndex] - 1;
        expect(qs.last, expectedRightmost,
            reason:
                'Row $rowIndex (r=$r) rightmost q should be startCol+length-1 = $expectedRightmost');
      }
    });

    test('each row has consecutive q values with no gaps', () {
      final rows = _rowsByR(hexes);
      for (final entry in rows.entries) {
        final qs = entry.value..sort();
        for (var i = 1; i < qs.length; i++) {
          expect(qs[i], qs[i - 1] + 1,
              reason:
                  'Row r=${entry.key} has a gap between q=${qs[i - 1]} and q=${qs[i]}');
        }
      }
    });
  });

  group('Pentagon silhouette validation', () {
    final hexes = GameMapState.defaultHexesFor(MapLayoutPreset.special5p);
    final metrics = computeLayoutMetrics(hexes);

    test('pixel centers computed for all 214 hexes', () {
      expect(metrics.positions, hasLength(214),
          reason: 'Every hex must have a computed pixel position');
    });

    test('bounding box dimensions are reasonable', () {
      // 18 rows -> (18-1) rowIndex span => 17 * ySpacing between centers
      // Expected height = 17 * ySpacing + padding*2 + 2*R
      final expectedHeight = 17 * _kYSpacing + metrics.padding * 2 + 2 * _kHexRadius;
      expect(metrics.height, closeTo(expectedHeight, _kTol),
          reason:
              'height should equal 17*ySpacing + 2*padding + 2*R for 18-row layout');

      // The widest pixel extent comes from the union of left/right edges
      // across all rows (plus the odd-row half-shift). The dominant terms
      // are (maxX - minX) + 2*padding + xSpacing. Empirically this is on
      // the order of ~16 * xSpacing for this layout. Allow a loose window.
      expect(metrics.width, greaterThan(15 * _kXSpacing),
          reason: 'width must exceed the widest row extent');
      expect(metrics.width, lessThan(20 * _kXSpacing + metrics.padding * 2),
          reason: 'width should not vastly exceed 17 rows of xSpacing + padding');
    });

    test('left edge descends-then-rises horizontally (pentagon shape)', () {
      // Leftmost x per row should first decrease (board widens going down)
      // and eventually increase (board narrows toward the bottom).
      final rows = _rowsByR(hexes);
      final sortedRKeys = rows.keys.toList()..sort();
      final leftmostXPerRow = <double>[];
      for (final r in sortedRKeys) {
        double minX = double.infinity;
        for (final q in rows[r]!) {
          final p = _posOf(metrics, q, r);
          if (p.dx < minX) minX = p.dx;
        }
        leftmostXPerRow.add(minX);
      }

      // Find index of minimum leftmost x (widest point on the left edge).
      var widestIdx = 0;
      var widestX = leftmostXPerRow.first;
      for (var i = 1; i < leftmostXPerRow.length; i++) {
        if (leftmostXPerRow[i] < widestX) {
          widestX = leftmostXPerRow[i];
          widestIdx = i;
        }
      }
      expect(widestIdx, greaterThan(0),
          reason: 'Leftmost edge should push outward from the first row');
      expect(widestIdx, lessThan(leftmostXPerRow.length - 1),
          reason:
              'Leftmost edge should eventually retreat back inward (pentagon bottom)');

      // Rightmost x per row should mirror: grow outward, then pull back in.
      final rightmostXPerRow = <double>[];
      for (final r in sortedRKeys) {
        double mX = double.negativeInfinity;
        for (final q in rows[r]!) {
          final p = _posOf(metrics, q, r);
          if (p.dx > mX) mX = p.dx;
        }
        rightmostXPerRow.add(mX);
      }
      var rightIdx = 0;
      var rightMax = rightmostXPerRow.first;
      for (var i = 1; i < rightmostXPerRow.length; i++) {
        if (rightmostXPerRow[i] > rightMax) {
          rightMax = rightmostXPerRow[i];
          rightIdx = i;
        }
      }
      expect(rightIdx, greaterThan(0),
          reason: 'Right edge should push outward from the first row');
      expect(rightIdx, lessThan(rightmostXPerRow.length - 1),
          reason: 'Right edge should also pull back in toward the bottom');
    });
  });

  group('MapLayoutPreset.standard4p regression guard', () {
    test('standard4p still produces 144 hexes across 12 rows of 12', () {
      final hexes = GameMapState.defaultHexesFor(MapLayoutPreset.standard4p);
      expect(hexes, hasLength(144),
          reason: 'standard4p must remain a 144-hex (12x12) layout');
      final state =
          GameMapState(layoutPreset: MapLayoutPreset.standard4p, hexes: hexes);
      expect(state.rowLengths, List<int>.filled(12, 12),
          reason: 'standard4p must have 12 rows of 12 hexes each');
    });

    test('standard4p layout metrics contain all 144 positions', () {
      final hexes = GameMapState.defaultHexesFor(MapLayoutPreset.standard4p);
      final metrics = computeLayoutMetrics(hexes);
      expect(metrics.positions, hasLength(144),
          reason: 'Every 4p hex should have a pixel position');
    });
  });
}

Map<int, List<int>> _rowsByR(List<MapHexState> hexes) {
  final rows = <int, List<int>>{};
  for (final h in hexes) {
    rows.putIfAbsent(h.coord.r, () => <int>[]).add(h.coord.q);
  }
  return rows;
}
