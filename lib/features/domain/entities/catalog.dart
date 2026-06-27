import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({required this.id, required this.name});
  final int id;
  final String name;
  @override
  List<Object?> get props => [id, name];
}

class CatalogSkill extends Equatable {
  const CatalogSkill({
    required this.id,
    required this.name,
    required this.categoryId,
  });
  final int id;
  final String name;
  final int categoryId;
  @override
  List<Object?> get props => [id, name, categoryId];
}

class OfferTier extends Equatable {
  const OfferTier({
    required this.id,
    required this.name,
    required this.minCandidates,
    required this.maxCandidates,
    required this.priceCop,
  });
  final int id;
  final String name;
  final int minCandidates;
  final int maxCandidates;
  final int priceCop;

  String get priceLabel {
    final k = (priceCop / 1000).toStringAsFixed(0);
    return '\$$k.000 COP';
  }

  String get candidatesLabel => '$minCandidates–$maxCandidates candidates';

  @override
  List<Object?> get props => [id];
}

class SelectedSkill extends Equatable {
  const SelectedSkill({
    required this.skillId,
    required this.name,
    required this.level,
  });
  final int skillId;
  final String name;
  final int level;

  SelectedSkill copyWith({int? level}) =>
      SelectedSkill(skillId: skillId, name: name, level: level ?? this.level);

  Map<String, dynamic> toJson() => {'skillId': skillId, 'level': level};

  @override
  List<Object?> get props => [skillId, name, level];
}
