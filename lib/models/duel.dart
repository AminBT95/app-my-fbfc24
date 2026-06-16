class DuelMode {
  final String key;
  final String label;
  final String profile;
  final Map<String, double> weights;
  final String advice;
  const DuelMode(this.key, this.label, this.profile, this.weights, this.advice);
}

class DuelResult {
  final int scoreA;
  final int scoreB;
  final int coreA;
  final int coreB;
  final int bonusA;
  final int bonusB;
  final double percentA;
  final String winner;
  final List<String> reasons;
  const DuelResult({required this.scoreA, required this.scoreB, required this.coreA, required this.coreB, required this.bonusA, required this.bonusB, required this.percentA, required this.winner, required this.reasons});
}
