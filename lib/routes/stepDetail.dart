class StepDetail {
  final String travelMode;
  final String instruction;
  final String distanceText;
  final String durationText;
  final int durationSeconds;
  final Map<String, dynamic>? transitInfo;
  final int? startEpoch; // epoch seconds when this step starts (optional)

  StepDetail({
    required this.travelMode,
    required this.instruction,
    required this.distanceText,
    required this.durationText,
    required this.durationSeconds,
    this.transitInfo,
    this.startEpoch,
  });
}

class RouteOption {
  final String depart;
  final String arrive;
  final int durationMinutes;
  final int totalFare;
  final List<String> legs;
  final List<StepDetail> steps;
  final String distanceText;

  RouteOption({
    required this.depart,
    required this.arrive,
    required this.durationMinutes,
    required this.totalFare,
    required this.legs,
    required this.steps,
    required this.distanceText,
  });
}