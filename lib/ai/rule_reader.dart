import '../data/foods.dart';
import '../data/models.dart';
import 'types.dart';

/// Offline, rule-based meal reader for English and Nigerian Pidgin.
/// Same contract as a remote AI: it may only pick foods from the database.

String normalise(String text) {
  var s = ' ${text.toLowerCase()} ';
  s = s.replaceAll(RegExp('[‘’\']'), '');
  for (var i = 0; i < 2; i++) {
    s = s.replaceAllMapped(RegExp(r'(\d),(\d{3})'), (m) => '${m[1]}${m[2]}');
  }
  s = s.replaceAllMapped(RegExp(r'(\d+(?:\.\d+)?)\s?k\b'), (m) => (double.parse(m[1]!) * 1000).round().toString());
  s = s.replaceAll(RegExp(r'\bn(?=\d)'), '₦').replaceAll(RegExp(r'\bngn\s?(?=\d)'), '₦');
  s = s.replaceAll(RegExp(r'₦\s+'), '₦');
  s = s.replaceAll(RegExp(r'&|\+'), ' and ');
  s = s.replaceAllMapped(RegExp(r'(\d)\s*x\b'), (m) => '${m[1]} ');
  s = s.replaceAllMapped(RegExp(r'(\d)([a-z])'), (m) => '${m[1]} ${m[2]}');
  s = s.replaceAll(RegExp(r'[^\p{L}\p{N}₦.\s]', unicode: true), ' ');
  s = s.replaceAll(RegExp(r'\.(?!\d)'), ' ').replaceAll(RegExp(r'(?<!\d)\.'), ' ');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<String> _tokens(String s) => normalise(s).split(' ').where((t) => t.isNotEmpty).toList();

const _numberWords = {
  'a': 1.0,
  'an': 1.0,
  'one': 1.0,
  'two': 2.0,
  'three': 3.0,
  'four': 4.0,
  'five': 5.0,
  'six': 6.0,
  'seven': 7.0,
  'eight': 8.0,
  'nine': 9.0,
  'ten': 10.0,
  'couple': 2.0,
  'half': 0.5,
  'quarter': 0.25,
};

const _sizeWords = {
  'small': 'sm',
  'smallie': 'sm',
  'mini': 'sm',
  'little': 'sm',
  'tiny': 'sm',
  'medium': 'md',
  'mid': 'md',
  'normal': 'md',
  'regular': 'md',
  'average': 'md',
  'moderate': 'md',
  'big': 'lg',
  'large': 'lg',
  'jumbo': 'lg',
  'huge': 'lg',
  'plenty': 'lg',
  'full': 'lg',
  'extra': 'lg',
};

const _containerWords = {
  'pack': 'pack',
  'packs': 'pack',
  'takeaway': 'pack',
  'takeaways': 'pack',
  'takeout': 'pack',
  'container': 'pack',
  'plastic': 'pack',
  'styrofoam': 'pack',
  'box': 'pack',
  'plate': 'plate',
  'plates': 'plate',
  'bowl': 'bowl',
  'bowls': 'bowl',
  'spoon': 'spoon',
  'spoons': 'spoon',
  'spoonful': 'spoon',
  'spoonfuls': 'spoon',
  'scoop': 'spoon',
  'scoops': 'spoon',
  'wrap': 'wrap',
  'wraps': 'wrap',
  'wrapper': 'wrap',
  'ball': 'ball',
  'balls': 'ball',
  'piece': 'piece',
  'pieces': 'piece',
  'pcs': 'piece',
  'pc': 'piece',
  'slice': 'slice',
  'slices': 'slice',
  'tin': 'tin',
  'tins': 'tin',
  'can': 'tin',
  'cans': 'tin',
  'sachet': 'sachet',
  'sachets': 'sachet',
  'handful': 'handful',
  'handfuls': 'handful',
  'cup': 'cup',
  'cups': 'cup',
  'mudu': 'cup',
  'bottle': 'bottle',
  'bottles': 'bottle',
  'loaf': 'loaf',
  'loaves': 'loaf',
  'serving': 'serving',
  'servings': 'serving',
  'portion': 'serving',
  'portions': 'serving',
};

const _connectors = {'and', 'with', 'plus', 'then', 'n', 'also', 'add', 'added'};

final _stopwords =
    ('i me my we you u im ive id a an the of for from at in on to it its is was were be been am are na dey de don go come wey e o oh ah '
            'abeg sha oya jare like about around roughly approx just only really very too so that this these those today yesterday morning afternoon '
            'evening night tonight breakfast lunch dinner supper snack brunch ate eat eating eaten had have has having chop chopped chopping chopam buy '
            'bought buying got get took take away order ordered cost costs paid pay worth price naira ngn mama put mamaput buka canteen cafeteria caf joint '
            'spot vendor hostel school campus side inside top each per total all everything whole finish finished left fried boiled roasted grilled hot '
            'cold sweet nice local fresh homemade self made cooked rest nothing else not no did didnt dont couldnt could eh some something thing things '
            'kind type sort which what how much many ehn sef said')
        .split(' ')
        .toSet();

class _Alias {
  _Alias(this.foodId, this.tokens, this.alias);
  final String foodId;
  final List<String> tokens;
  final String alias;
}

final List<_Alias> _aliases =
    [
      for (final f in foods)
        for (final a in f.aliases) _Alias(f.id, _tokens(a), a),
    ]..sort((a, b) {
      final byLen = b.tokens.length.compareTo(a.tokens.length);
      return byLen != 0 ? byLen : b.alias.length.compareTo(a.alias.length);
    });

final List<List<String>> _noProtein = noProteinWords.map(_tokens).toList()..sort((a, b) => b.length.compareTo(a.length));

const _generic = {'rice', 'meat', 'garri', 'gari', 'sauce'};
final _soupIds = {
  for (final f in foods)
    if (f.group == FoodGroup.soup) f.id,
};
const _packIds = [PortionId.smPack, PortionId.mdPack, PortionId.lgPack];

int levenshtein(String a, String b) {
  if (a == b) return 0;
  final dp = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    var prev = dp[0];
    dp[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final tmp = dp[j];
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      dp[j] = [dp[j] + 1, dp[j - 1] + 1, prev + cost].reduce((x, y) => x < y ? x : y);
      prev = tmp;
    }
  }
  return dp[b.length];
}

bool _tokenEq(String word, String target, {required bool fuzzy}) {
  if (word == target || word == '${target}s') return true;
  if (!fuzzy) return false;
  if ('${word}s' == target || word == '${target}es') return true;
  if (target.length >= 5 && word.length >= 4 && (word.length - target.length).abs() <= 1) return levenshtein(word, target) <= 1;
  return false;
}

/// Foods whose names look like an unknown word ("did you mean").
List<Food> closestFoods(String word, {int limit = 3}) {
  final scored = <String, double>{};
  for (final a in _aliases) {
    final d = levenshtein(word, a.alias) / [word.length, a.alias.length].reduce((x, y) => x > y ? x : y);
    if (!scored.containsKey(a.foodId) || d < scored[a.foodId]!) scored[a.foodId] = d;
  }
  final list = scored.entries.where((e) => e.value <= 0.3).toList()..sort((a, b) => a.value.compareTo(b.value));
  return list.take(limit).map((e) => foodById[e.key]!).toList();
}

class _Span {
  _Span(this.start, this.end, this.foodId, this.matched);
  final int start;
  final int end;
  final String foodId;
  final String matched;
}

enum _ModKind { number, size, container, of, connector }

class _Mod {
  _Mod(this.kind, this.pos, {this.number, this.word});
  final _ModKind kind;
  final int pos;
  final double? number;
  final String? word;
}

(String, double?) _mealEaten(String s) {
  const containers = 'plate|pack|bowl|wrap|spoon|takeaway|loaf|tin|sachet|cup|bottle|portion|serving';
  final rules = <(RegExp, double)>[
    (
      RegExp(
        r'\b(?:i\s+)?(?:only\s+)?(?:ate|chop|chopped|finished|finish|eat)\s+(?:only\s+)?half(?!\s+(?:a\s+|of\s+(?:a\s+|the\s+)?)?(?:' +
            containers +
            r'))(?:\s+of\s+it)?\b',
      ),
      0.5,
    ),
    (RegExp(r'\bhalf\s+of\s+it\b'), 0.5),
    (RegExp(r'\b(?:i\s+)?(?:ate|chop|chopped|finished|eat)\s+(?:a\s+)?quarter(?:\s+of\s+it)?\b'), 0.25),
    (
      RegExp(
        r'\b(?:i\s+)?(?:no\s+finish|didnt\s+finish|did\s+not\s+finish|couldnt\s+finish|could\s+not\s+finish|cant\s+finish|left\s+some|no\s+fit\s+finish)(?:\s+(?:am|it))?\b',
      ),
      0.75,
    ),
    (RegExp(r'\b(?:i\s+)?(?:finish|finished|cleared|chop\s+finish)\s+(?:everything|all|am|it)\b'), 1),
  ];
  for (final (re, v) in rules) {
    if (re.hasMatch(s)) return (s.replaceAll(re, ' ').replaceAll(RegExp(r'\s+'), ' ').trim(), v);
  }
  return (s, null);
}

/// Reads a meal description into database foods and portions.
RawReading readMeal(String input) {
  final (text, mealEaten) = _mealEaten(normalise(input));
  final toks = text.split(' ').where((t) => t.isNotEmpty).toList();
  final used = List<bool>.filled(toks.length, false);
  bool free(int i, int n) => !used.sublist(i, i + n).any((u) => u);

  // 1. Food spans: longest aliases first; within a length, exact before typo-tolerant.
  final spans = <_Span>[];
  final lengths = _aliases.map((a) => a.tokens.length).toSet().toList()..sort((a, b) => b.compareTo(a));
  for (final len in lengths) {
    for (final fuzzy in [false, true]) {
      for (final a in _aliases.where((a) => a.tokens.length == len)) {
        for (var i = 0; i + len <= toks.length; i++) {
          if (!free(i, len)) continue;
          var ok = true;
          for (var k = 0; k < len && ok; k++) {
            ok = _tokenEq(toks[i + k], a.tokens[k], fuzzy: fuzzy);
          }
          if (!ok) continue;
          spans.add(_Span(i, i + len, a.foodId, toks.sublist(i, i + len).join(' ')));
          for (var k = i; k < i + len; k++) {
            used[k] = true;
          }
        }
      }
    }
  }
  spans.sort((a, b) => a.start.compareTo(b.start));

  // 2. Things with no protein.
  final skipped = <String>[];
  for (final w in _noProtein) {
    for (var i = 0; i + w.length <= toks.length; i++) {
      if (!free(i, w.length)) continue;
      var ok = true;
      for (var k = 0; k < w.length && ok; k++) {
        ok = toks[i + k] == w[k];
      }
      if (ok) {
        skipped.add(w.join(' '));
        for (var k = i; k < i + w.length; k++) {
          used[k] = true;
        }
      }
    }
  }

  // 3. Modifiers, price and unknown words.
  final mods = <_Mod>[];
  var price = 0.0;
  final unknownRuns = <List<String>>[];
  var run = <String>[];
  void flush() {
    if (run.isNotEmpty) unknownRuns.add(run);
    run = <String>[];
  }

  for (var i = 0; i < toks.length; i++) {
    if (used[i]) {
      flush();
      continue;
    }
    final t = toks[i];
    final next = i + 1 < toks.length ? toks[i + 1] : null;
    if (t.startsWith('₦')) {
      price += double.tryParse(t.substring(1)) ?? 0;
      flush();
      continue;
    }
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(t)) {
      final n = double.parse(t);
      flush();
      if (next == 'naira' || next == 'ngn' || n >= 50) {
        price += n;
      } else if (next == 'g' || next == 'grams' || next == 'ml') {
        i++;
      } else {
        mods.add(_Mod(_ModKind.number, i, number: n));
      }
      continue;
    }
    if (_numberWords.containsKey(t) && t != 'a' && t != 'an') {
      mods.add(_Mod(_ModKind.number, i, number: _numberWords[t]));
      flush();
      continue;
    }
    if ((t == 'a' || t == 'an') && next != null && (_containerWords.containsKey(next) || _sizeWords.containsKey(next))) {
      mods.add(_Mod(_ModKind.number, i, number: 1));
      flush();
      continue;
    }
    if (_sizeWords.containsKey(t)) {
      mods.add(_Mod(_ModKind.size, i, word: _sizeWords[t]));
      flush();
      continue;
    }
    if (t == 'take' && next == 'away') {
      mods.add(_Mod(_ModKind.container, i, word: 'pack'));
      i++;
      flush();
      continue;
    }
    if (_containerWords.containsKey(t)) {
      mods.add(_Mod(_ModKind.container, i, word: _containerWords[t]));
      flush();
      continue;
    }
    if (t == 'of') {
      mods.add(_Mod(_ModKind.of, i));
      flush();
      continue;
    }
    if (_connectors.contains(t)) {
      mods.add(_Mod(_ModKind.connector, i));
      flush();
      continue;
    }
    if (_stopwords.contains(t) || t.length < 3) {
      flush();
      continue;
    }
    run.add(t);
  }
  flush();
  final unknown = unknownRuns.map((r) => r.join(' ')).toList();
  final total = price > 0 ? price.round() : null;
  if (spans.isEmpty) return RawReading(items: const [], unknown: unknown, skipped: skipped, price: total);

  // 4. Give each modifier to a food.
  final owned = List<List<_Mod>>.generate(spans.length, (_) => []);
  for (final m in mods) {
    if (m.kind == _ModKind.connector || m.kind == _ModKind.of) continue;
    owned[_ownerOf(m.pos, spans, mods)].add(m);
  }

  // 5. Containers that don't fit their food move to the first food that takes them.
  for (var s = 0; s < spans.length; s++) {
    final food = foodById[spans[s].foodId]!;
    for (final m in [...owned[s]]) {
      if (m.kind != _ModKind.container || _supports(food, m.word!)) continue;
      final target = spans.indexWhere((sp) => _supports(foodById[sp.foodId]!, m.word!));
      if (target >= 0 && target != s) {
        owned[s].remove(m);
        final size = owned[s].where((x) => x.kind == _ModKind.size && (x.pos - m.pos).abs() <= 2).firstOrNull;
        if (size != null) {
          owned[s].remove(size);
          owned[target].add(size);
        }
        owned[target].add(m);
      }
    }
  }

  // 6. Resolve each food into an item.
  final hasSoup = spans.any((s) => _soupIds.contains(s.foodId));
  final items = <RawItem>[];
  for (var idx = 0; idx < spans.length; idx++) {
    final sp = spans[idx];
    var foodId = sp.foodId;
    // "garri" with soup is eba, not soaked garri.
    if (foodId == 'garri_soaked' && hasSoup && (sp.matched == 'garri' || sp.matched == 'gari')) foodId = 'eba';
    final r = _resolvePortion(foodById[foodId]!, owned[idx]);
    final raw = RawItem(
      foodId: foodId,
      portionKey: r.$1.key,
      qty: r.$2,
      eaten: mealEaten ?? 1,
      source: r.$3,
      matched: sp.matched,
      generic: _generic.contains(sp.matched) && foodId != 'eba',
    );
    final dup = items.indexWhere((x) => x.foodId == raw.foodId && x.portionKey == raw.portionKey);
    if (dup >= 0) {
      final ex = items[dup];
      items[dup] = RawItem(
        foodId: ex.foodId,
        portionKey: ex.portionKey,
        qty: (ex.qty ?? 1) + (raw.qty ?? 1),
        eaten: ex.eaten,
        source: ex.source,
        matched: ex.matched,
        generic: ex.generic,
      );
    } else {
      items.add(raw);
    }
  }
  return RawReading(items: items, unknown: unknown, skipped: skipped, price: total);
}

int _ownerOf(int pos, List<_Span> spans, List<_Mod> mods) {
  final after = spans.indexWhere((s) => s.start > pos);
  if (after == -1) return spans.length - 1;
  if (after == 0) return 0;
  final prev = after - 1;
  final between = mods.where((m) => m.pos > spans[prev].end - 1 && m.pos < spans[after].start).toList();
  final lastConnector = between.lastWhere((m) => m.kind == _ModKind.connector, orElse: () => _Mod(_ModKind.size, -1));
  if (lastConnector.pos >= 0) return pos > lastConnector.pos ? after : prev;
  if (between.any((m) => m.kind == _ModKind.of)) return after;
  if (between.isNotEmpty) {
    final last = between.last;
    if (last.pos == spans[after].start - 1 && (last.kind == _ModKind.number || last.kind == _ModKind.size)) {
      return pos >= last.pos ? after : prev;
    }
  }
  return prev;
}

bool _supports(Food food, String c) {
  if (c == 'pack') return food.portions.any((p) => _packIds.contains(p.id) || p.id == PortionId.pack);
  if (c == 'loaf') return food.hasPortion(PortionId.slice);
  if (c == 'piece' || c == 'serving') return true;
  final id = PortionId.fromKey(c);
  return id != null && food.hasPortion(id);
}

PortionId? _nearestPack(Food food, String size) {
  final order = switch (size) {
    'sm' => [PortionId.smPack, PortionId.mdPack, PortionId.lgPack],
    'lg' => [PortionId.lgPack, PortionId.mdPack, PortionId.smPack],
    _ => [PortionId.mdPack, PortionId.smPack, PortionId.lgPack],
  };
  return order.where(food.hasPortion).firstOrNull;
}

(PortionId, double, PortionSource) _resolvePortion(Food food, List<_Mod> mods) {
  final nums = mods.where((m) => m.kind == _ModKind.number).toList();
  final size = mods.where((m) => m.kind == _ModKind.size).firstOrNull?.word;
  final container = mods.where((m) => m.kind == _ModKind.container).firstOrNull?.word;
  final half = nums.where((n) => n.number! < 1).firstOrNull?.number;
  final whole = nums.where((n) => n.number! >= 1).firstOrNull?.number;
  double qtyFrom(double fallback) => (whole ?? 1) * (half ?? 1) * (whole != null || half != null ? 1 : fallback);

  if (container == 'pack') {
    if (food.hasPortion(PortionId.pack)) return (PortionId.pack, qtyFrom(1), PortionSource.stated);
    final id = _nearestPack(food, size ?? 'md');
    if (id != null) return (id, qtyFrom(1), size != null ? PortionSource.stated : PortionSource.sizeDefault);
  }
  if (container == 'loaf' && food.hasPortion(PortionId.slice)) {
    return (PortionId.slice, (10 * (half ?? 1) * (whole ?? 1)).roundToDouble(), PortionSource.stated);
  }
  if (container != null && container != 'pack' && container != 'loaf') {
    final id = PortionId.fromKey(container);
    if (id != null && food.hasPortion(id)) {
      final factor = (id == PortionId.plate || id == PortionId.bowl)
          ? (size == 'sm'
                ? 0.75
                : size == 'lg'
                ? 1.3
                : 1.0)
          : 1.0;
      return (id, double.parse((qtyFrom(1) * factor).toStringAsFixed(2)), PortionSource.stated);
    }
    if (container == 'piece' || container == 'serving') {
      return (food.defaultPortion, qtyFrom(food.defaultQty), whole != null ? PortionSource.stated : PortionSource.defaulted);
    }
  }
  if (size != null) {
    final id = _nearestPack(food, size);
    if (id != null) return (id, qtyFrom(1), PortionSource.stated);
  }
  if (whole != null || half != null) return (food.defaultPortion, qtyFrom(1), PortionSource.stated);
  return (food.defaultPortion, food.defaultQty, PortionSource.defaulted);
}
