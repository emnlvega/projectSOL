class UserSettings {
  String customLocation;
  double panelCapacity; // kW
  int panelCount;
  double panelAngle;

  UserSettings({
    this.customLocation = '',
    this.panelCapacity = 5.0,
    this.panelCount = 1,
    this.panelAngle = 30.0,
  });

  Map<String, dynamic> toJson() => {
        'customLocation': customLocation,
        'panelCapacity': panelCapacity,
        'panelCount': panelCount,
        'panelAngle': panelAngle,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        customLocation: json['customLocation'] ?? '',
        panelCapacity: json['panelCapacity']?.toDouble() ?? 5.0,
        panelCount: json['panelCount'] ?? 1,
        panelAngle: json['panelAngle']?.toDouble() ?? 30.0,
      );
}