class DailySaving {
  final DateTime date;
  final double amount;
  final double potential;
  final double temperature;

  DailySaving({
    required this.date,
    required this.amount,
    required this.potential,
    required this.temperature,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'amount': amount,
        'potential': potential,
        'temperature': temperature,
      };

  factory DailySaving.fromJson(Map<String, dynamic> json) => DailySaving(
        date: DateTime.parse(json['date']),
        amount: json['amount'],
        potential: json['potential'],
        temperature: json['temperature'],
      );
}