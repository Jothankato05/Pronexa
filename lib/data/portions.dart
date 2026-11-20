import 'models.dart';

class PortionMeta {
  const PortionMeta(this.one, this.many, this.icon, this.uncertainty, {this.container = false, this.hint});

  final String one;
  final String many;
  final String icon;

  /// Relative uncertainty of the grams for this kind of portion.
  final double uncertainty;

  /// Shown as a picture in Portion mode.
  final bool container;
  final String? hint;
}

const Map<PortionId, PortionMeta> portionMeta = {
  PortionId.smPack: PortionMeta('small takeaway', 'small takeaways', 'pack-sm', 0.25, container: true, hint: 'Small pack'),
  PortionId.mdPack: PortionMeta('medium takeaway', 'medium takeaways', 'pack-md', 0.25, container: true, hint: 'Usual pack'),
  PortionId.lgPack: PortionMeta('large takeaway', 'large takeaways', 'pack-lg', 0.25, container: true, hint: 'Big pack'),
  PortionId.plate: PortionMeta('plate', 'plates', 'plate', 0.25, container: true, hint: 'Dinner plate'),
  PortionId.bowl: PortionMeta('bowl', 'bowls', 'bowl', 0.25, container: true, hint: 'Soup bowl'),
  PortionId.wrap: PortionMeta('wrap', 'wraps', 'wrap', 0.2, container: true, hint: 'Swallow, moi-moi, okpa'),
  PortionId.spoon: PortionMeta('serving spoon', 'serving spoons', 'spoon', 0.25),
  PortionId.serving: PortionMeta('serving', 'servings', 'bowl', 0.25),
  PortionId.piece: PortionMeta('piece', 'pieces', 'piece', 0.15),
  PortionId.ball: PortionMeta('ball', 'balls', 'akara', 0.15),
  PortionId.slice: PortionMeta('slice', 'slices', 'bread', 0.15),
  PortionId.tin: PortionMeta('tin', 'tins', 'tin', 0.1),
  PortionId.sachet: PortionMeta('sachet', 'sachets', 'sachet', 0.15),
  PortionId.handful: PortionMeta('handful', 'handfuls', 'handful', 0.25),
  PortionId.cup: PortionMeta('cup', 'cups', 'cup', 0.2),
  PortionId.bottle: PortionMeta('bottle', 'bottles', 'bottle', 0.2),
  PortionId.pack: PortionMeta('pack', 'packs', 'noodles', 0.1),
};

/// Containers offered as pictures in Portion mode, in display order.
const containers = [PortionId.smPack, PortionId.mdPack, PortionId.lgPack, PortionId.plate, PortionId.bowl, PortionId.wrap];

const eatenOptions = <(double, String)>[(1, 'All'), (0.75, '¾'), (0.5, 'Half'), (0.25, '¼')];
