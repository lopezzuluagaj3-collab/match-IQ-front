class MarketSkillDemand {
  const MarketSkillDemand({
    required this.skillName,
    required this.categoryName,
    required this.offerCount,
    this.candidateHasSkill,
    this.candidateLevel,
  });

  final String skillName;
  final String categoryName;
  final int offerCount;
  final bool? candidateHasSkill;
  final int? candidateLevel;
}

class MarketSkillSupply {
  const MarketSkillSupply({
    required this.skillName,
    required this.categoryName,
    required this.candidateCount,
  });

  final String skillName;
  final String categoryName;
  final int candidateCount;
}

class MarketSkillCombination {
  const MarketSkillCombination({
    required this.skillA,
    required this.skillB,
    required this.offerCount,
    this.candidateHasA,
    this.candidateHasB,
    this.candidateHasBoth,
  });

  final String skillA;
  final String skillB;
  final int offerCount;
  final bool? candidateHasA;
  final bool? candidateHasB;
  final bool? candidateHasBoth;
}

class MarketAnalytics {
  const MarketAnalytics({
    required this.topDemand,
    required this.topSupply,
    required this.topCombinations,
    this.skillsInDemand = const [],
    this.skillGaps = const [],
  });

  final List<MarketSkillDemand> topDemand;
  final List<MarketSkillSupply> topSupply;
  final List<MarketSkillCombination> topCombinations;
  final List<String> skillsInDemand;
  final List<String> skillGaps;
}
