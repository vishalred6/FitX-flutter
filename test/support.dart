import 'package:fitx/controller.dart';
import 'package:fitx/models.dart';

class MemoryStorage implements FitnessStorage {
  MemoryStorage([this.value]);
  String? value;
  bool fail = false;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (fail) {
      throw StateError('Storage unavailable');
    }
    writes++;
    this.value = value;
  }
}

final fixtureNow = DateTime(2025, 6, 18, 12);
Workout activity(
  String id, {
  DateTime? date,
  int seconds = 1800,
  int calories = 200,
  int steps = 3000,
}) => Workout(
  id: id,
  title: 'Afternoon walk',
  type: ActivityType.walking,
  date: date ?? fixtureNow,
  seconds: seconds,
  calories: calories,
  steps: steps,
  distance: 2.5,
);

Map<String, dynamic> legacySavedData(FitnessData data) => data.toJson()
  ..['version'] = 1
  ..remove('goalLevel')
  ..['profile'] = {
    'name': 'Previous account',
    'dailySteps': 9000,
    'targetWeight': 70,
    'bodyWeight': 75,
  }
  ..['dark'] = false;
