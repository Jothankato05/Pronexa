import 'package:flutter_test/flutter_test.dart';
import 'package:pronexa/ai/rule_reader.dart';
import 'package:pronexa/ai/validator.dart';

/// Describe-it test set: English, Pidgin and price-based descriptions.
/// This set was written with the rule reader, so it is a regression check,
/// not an accuracy claim. Measure any real AI on fresh descriptions.
class Case {
  const Case(this.text, this.foods, {this.portions = const {}, this.qty = const {}, this.eaten});
  final String text;
  final List<String> foods;
  final Map<String, String> portions;
  final Map<String, double> qty;
  final double? eaten;
}

const cases = [
  Case('₦1,000 rice and beans, medium takeaway', ['rice_beans'], portions: {'rice_beans': 'md_pack'}),
  Case('I chop 2 wraps of eba with egusi and one meat', ['eba', 'egusi', 'beef'], qty: {'eba': 2, 'beef': 1}),
  Case('rice and stew 700 naira', ['white_rice', 'stew'], portions: {'white_rice': 'sm_pack'}),
  Case('jollof rice big pack with chicken', ['jollof_rice', 'chicken'], portions: {'jollof_rice': 'lg_pack'}),
  Case('₦500 beans', ['beans']),
  Case('agege bread and 5 akara', ['bread', 'akara'], qty: {'akara': 5}),
  Case('amala and ewedu with 2 meat', ['amala', 'ewedu', 'beef'], qty: {'beef': 2}),
  Case('small indomie with egg', ['noodles', 'egg']),
  Case('soaked garri with groundnut and milk', ['garri_soaked', 'groundnuts', 'milk']),
  Case('I buy moi moi for 500', ['moi_moi']),
  Case('yam and egg sauce', ['yam', 'egg', 'stew']),
  Case('beans and dodo', ['beans', 'plantain']),
  Case('pounded yam with efo riro and fish', ['pounded_yam', 'efo_riro', 'fish']),
  Case('one okpa', ['okpa'], qty: {'okpa': 1}),
  Case('jollof spaghetti medium pack', ['spaghetti'], portions: {'spaghetti': 'md_pack'}),
  Case('tuwo shinkafa and okra soup', ['tuwo', 'okra']),
  Case('abacha one plate', ['abacha'], portions: {'abacha': 'plate'}),
  Case('fried rice and chicken 2500', ['fried_rice', 'chicken']),
  Case('bread and sardine', ['bread', 'sardine']),
  Case('two boiled eggs and tea', ['egg'], qty: {'egg': 2}),
  Case('soya chunks in my stew with white rice', ['soya_chunks', 'stew', 'white_rice']),
  Case('awara and pap', ['tofu']),
  Case('lentil porridge one bowl', ['lentils'], portions: {'lentils': 'bowl'}),
  Case('soy milk and akara', ['soy_milk', 'akara']),
  Case('ewa agoyin with agege, ₦800', ['beans', 'bread']),
  Case('I chop half plate of rice', ['white_rice'], portions: {'white_rice': 'plate'}, qty: {'white_rice': 0.5}),
  Case('eba 1 wrap and vegetable soup, I no finish am', ['eba', 'efo_riro'], eaten: 0.75),
  Case('groundnut 1 sachet', ['groundnuts'], portions: {'groundnuts': 'sachet'}),
  Case('jolof rice and moimoi', ['jollof_rice', 'moi_moi']),
  Case('1k rice n beans plus 1 meat', ['rice_beans', 'beef']),
  Case('garri and egusi soup', ['eba', 'egusi']),
  Case('soybeans one spoon and boiled yam', ['soybeans', 'yam']),
];

void main() {
  var foodsOk = 0;
  var bothOk = 0;
  for (final c in cases) {
    test(c.text, () {
      final raw = readMeal(c.text);
      final got = raw.items.map((i) => i.foodId).toList()..sort();
      expect(got, [...c.foods]..sort(), reason: 'foods');
      foodsOk++;
      final reading = validate(raw);
      for (final e in c.portions.entries) {
        expect(reading.items.firstWhere((i) => i.item.foodId == e.key).item.portionId.key, e.value, reason: 'portion ${e.key}');
      }
      for (final e in c.qty.entries) {
        expect(raw.items.firstWhere((i) => i.foodId == e.key).qty, e.value, reason: 'qty ${e.key}');
      }
      if (c.eaten != null) {
        expect(raw.items.every((i) => i.eaten == c.eaten), isTrue, reason: 'eaten');
      }
      bothOk++;
    });
  }
  tearDownAll(() {
    // ignore: avoid_print
    print('Describe-it test set: foods $foodsOk/${cases.length}, foods+portion $bothOk/${cases.length}');
  });
}
