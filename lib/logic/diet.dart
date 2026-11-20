import '../data/models.dart';

const dietLabels = {
  Diet.none: ('No restrictions', 'I eat everything'),
  Diet.vegetarian: ('Vegetarian', 'No meat or fish'),
  Diet.vegan: ('Vegan', 'No animal products'),
  Diet.pescatarian: ('Pescatarian', 'Fish, no other meat'),
  Diet.dairyFree: ('Dairy-free', 'No milk products'),
  Diet.eggFree: ('Egg-free', 'No eggs'),
};

const allergenLabels = {
  Allergen.peanut: 'Groundnut',
  Allergen.soy: 'Soy',
  Allergen.egg: 'Egg',
  Allergen.milk: 'Milk',
  Allergen.fish: 'Fish',
  Allergen.shellfish: 'Shellfish / crayfish',
  Allergen.gluten: 'Wheat / gluten',
  Allergen.sesame: 'Sesame (beniseed)',
};

const _excludes = {
  Diet.none: <AnimalKind>[],
  Diet.vegetarian: [AnimalKind.meat, AnimalKind.fish],
  Diet.vegan: [AnimalKind.meat, AnimalKind.fish, AnimalKind.egg, AnimalKind.dairy],
  Diet.pescatarian: [AnimalKind.meat],
  Diet.dairyFree: [AnimalKind.dairy],
  Diet.eggFree: [AnimalKind.egg],
};

class Fit {
  const Fit.ok([this.caveat]) : ok = true;
  const Fit.no() : ok = false, caveat = null;

  final bool ok;
  final String? caveat;
}

/// Can Pronexa suggest this food to this person? Strict: a vegan never sees an
/// animal product. Foods that may contain animal ingredients are shown only if a
/// plain version is easy to ask for, and then with a caveat.
Fit suggestionFit(Food food, Diet diet, List<Allergen> allergies) {
  final excluded = _excludes[diet]!;
  if (food.animal != null && excluded.contains(food.animal)) return const Fit.no();
  if (food.allergens.any(allergies.contains)) return const Fit.no();
  if (food.mayContainAllergens.any(allergies.contains)) return const Fit.no();
  final mayAnimal = food.mayContain.where(excluded.contains).toList();
  if (mayAnimal.isNotEmpty) {
    if (!food.plainAvailable) return const Fit.no();
    final words = mayAnimal.map(
      (k) => switch (k) {
        AnimalKind.meat => 'meat',
        AnimalKind.fish => 'fish or crayfish',
        AnimalKind.egg => 'egg',
        AnimalKind.dairy => 'milk',
      },
    );
    return Fit.ok('Ask for plain ${food.name.toLowerCase()}. Some vendors add ${words.join(' or ')}.');
  }
  return const Fit.ok();
}
