/// Short protein lessons, readable offline. Plain and factual; awareness, not
/// medical advice. Each point is one or two short sentences.
class Lesson {
  const Lesson(this.title, this.summary, this.points);

  final String title;
  final String summary;
  final List<String> points;
}

const lessons = [
  Lesson('What protein does', 'Why your body needs it every day', [
    'Protein builds and repairs muscle, skin and blood, and helps you fight infection.',
    'Your body does not store much of it, so you need some every day.',
    'A common guide for adults is about 0.8–1 g for each kg you weigh, a little more if you train hard.',
    'Spread it across the day: some at breakfast, lunch and dinner works better than one big meal.',
  ]),
  Lesson('Cheap protein in Nigeria', 'Where the grams per naira are', [
    'Soya chunks, groundnuts, kuli-kuli and soybeans give the most protein for the least money.',
    'Beans, moi-moi, akara, okpa and awara are cheap and sold almost everywhere.',
    'Eggs and sardines cost more per gram but need no cooking.',
    'Rice, garri, yam and swallow fill you up but carry little protein on their own.',
  ]),
  Lesson('Beans and grains together', 'Why rice and beans works', [
    'Plant proteins each miss some building blocks (amino acids).',
    'Beans are low in some that grains have, and grains are low in some that beans have.',
    'Eaten on the same day, they cover each other: rice and beans, bread and akara, eba and egusi.',
    'You do not need to eat them in the same meal.',
  ]),
  Lesson('Reading a takeaway pack', 'How much protein is really in it', [
    'A medium pack of rice and beans has roughly 15–25 g of protein.',
    'Most of a pack is rice. Asking for more beans or a wrap of moi-moi adds more than an extra spoon of stew.',
    'One piece of buka meat is small, often about 30–40 g of meat.',
    'Ponmo looks big but is mostly collagen, with far less protein than beef.',
  ]),
  Lesson('Eating only plants', 'What to watch', [
    'Vitamin B12 is not found in plant foods. Use fortified foods or a supplement.',
    'Iron from beans and greens is absorbed better with vitamin C: oranges, tomatoes, pepper.',
    'Zinc and calcium come from beans, groundnuts, seeds, awara and fortified soy milk.',
    'If you feel tired for weeks, see a health worker rather than guessing.',
  ]),
];
