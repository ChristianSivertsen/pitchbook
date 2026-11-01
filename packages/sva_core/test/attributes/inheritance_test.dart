import 'package:sva_core/sva_core.dart';
import 'package:test/test.dart';

void main() {
  group('M1-2: inheritance from crag to route to ascent resolves', () {
    const crag = {
      'rock_type': ['rock.granite'],
      'hold': ['hold.crimp'],
    };
    const sector = {
      'aspect': ['N'],
    };
    const route = {
      'angle': ['angle.overhang'],
      'hold': ['hold.jug', 'hold.pinch'],
    };
    const ascent = {
      'angle': ['angle.vertical'],
      'tag': ['tag.pumpy'],
    };

    test('each level fills in what the next leaves unset', () {
      expect(resolveAttributes([crag, sector, route, ascent]), {
        'rock_type': ['rock.granite'],
        'aspect': ['N'],
        'hold': ['hold.jug', 'hold.pinch'],
        'angle': ['angle.vertical'],
        'tag': ['tag.pumpy'],
      });
    });

    test('the most specific level replaces values instead of merging', () {
      expect(resolveAttributes([crag, route])['hold'], [
        'hold.jug',
        'hold.pinch',
      ]);
    });

    test('an empty list means not set, so it inherits', () {
      expect(
        resolveAttributes([
          crag,
          {'rock_type': <String>[]},
        ])['rock_type'],
        ['rock.granite'],
      );
    });

    test('no levels resolve to nothing', () {
      expect(resolveAttributes([]), isEmpty);
    });
  });

  test('M1-2: attribute definitions accept only values of their type', () {
    const hold = AttributeDef(
      key: 'hold',
      level: AttributeLevel.route,
      valueType: AttributeValueType.multi,
      valueKeys: ['hold.crimp', 'hold.jug'],
    );
    const feel = AttributeDef(
      key: 'feel',
      level: AttributeLevel.ascent,
      valueType: AttributeValueType.single,
      valueKeys: ['feel.soft', 'feel.hard'],
    );
    const rope = AttributeDef(
      key: 'rope_length_m',
      level: AttributeLevel.route,
      valueType: AttributeValueType.number,
    );
    const tide = AttributeDef(
      key: 'tide_dependent',
      level: AttributeLevel.route,
      valueType: AttributeValueType.bool,
    );

    expect(hold.accepts([]), isTrue);
    expect(hold.accepts(['hold.crimp', 'hold.jug']), isTrue);
    expect(hold.accepts(['hold.crimp', 'hold.crimp']), isFalse);
    expect(hold.accepts(['hold.sloper']), isFalse);
    expect(feel.accepts(['feel.soft']), isTrue);
    expect(feel.accepts(['feel.soft', 'feel.hard']), isFalse);
    expect(rope.accepts(['60']), isTrue);
    expect(rope.accepts(['60.5']), isTrue);
    for (final bad in ['sixty', 'NaN', 'Infinity', ' 60', '0x10', '1e3']) {
      expect(rope.accepts([bad]), isFalse, reason: bad);
    }
    expect(tide.accepts(['true']), isTrue);
    expect(tide.accepts(['yes']), isFalse);
  });
}
