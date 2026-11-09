import 'dart:convert';

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
String dayKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
bool sameDay(DateTime a, DateTime b) => dayKey(a) == dayKey(b);
const months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
String shortDate(DateTime date) => '${months[date.month - 1]} ${date.day}';
String longDate(DateTime date) =>
    '${weekdays[date.weekday - 1]}, ${shortDate(date)}, ${date.year}';
String number(num value) => value
    .toStringAsFixed(0)
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
String durationLabel(int seconds) {
  final minutes = seconds ~/ 60;
  return '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}

enum ActivityType { strength, running, cycling, yoga, walking, hiit }

extension ActivityTypeLabel on ActivityType {
  String get label => switch (this) {
    ActivityType.strength => 'Strength',
    ActivityType.running => 'Running',
    ActivityType.cycling => 'Cycling',
    ActivityType.yoga => 'Yoga',
    ActivityType.walking => 'Walking',
    ActivityType.hiit => 'HIIT',
  };
  double get met => switch (this) {
    ActivityType.strength => 5,
    ActivityType.running => 8,
    ActivityType.cycling => 7,
    ActivityType.yoga => 3,
    ActivityType.walking => 3.5,
    ActivityType.hiit => 9,
  };
}

class Workout {
  const Workout({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.seconds,
    required this.calories,
    this.distance = 0,
    this.steps = 0,
    this.notes = '',
  });
  final String id, title, notes;
  final ActivityType type;
  final DateTime date;
  final int seconds, calories, steps;
  final double distance;
  int get minutes => (seconds / 60).ceil();
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'date': date.toIso8601String(),
    'seconds': seconds,
    'calories': calories,
    'distance': distance,
    'steps': steps,
    'notes': notes,
  };
  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: _text(json, 'id', 100),
    title: _text(json, 'title', 80),
    type: ActivityType.values.byName(_text(json, 'type', 20)),
    date: _date(json['date']),
    seconds: _int(json, 'seconds', 1, 86400),
    calories: _int(json, 'calories', 0, 20000),
    distance: _num(json, 'distance', 0, 1000),
    steps: _int(json, 'steps', 0, 200000),
    notes: _text(json, 'notes', 1000, empty: true),
  );
}

enum GoalLevel { easy, regular }

extension GoalTargets on GoalLevel {
  String get label => this == GoalLevel.easy ? 'Easy' : 'Regular';
  String get description => this == GoalLevel.easy
      ? 'For a lighter routine'
      : 'For a more active routine';
  int get weeklyWorkouts => this == GoalLevel.easy ? 3 : 4;
  int get dailyMinutes => this == GoalLevel.easy ? 20 : 45;
  int get dailySteps => this == GoalLevel.easy ? 4000 : 8000;
  int get dailyCalories => this == GoalLevel.easy ? 250 : 500;
  int get waterMl => this == GoalLevel.easy ? 2000 : 2500;
}

class WeightEntry {
  const WeightEntry(this.date, this.kg);
  final DateTime date;
  final double kg;
  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'kg': kg};
  factory WeightEntry.fromJson(Map<String, dynamic> json) =>
      WeightEntry(_date(json['date']), _num(json, 'kg', 20, 400));
}

class Exercise {
  const Exercise(this.name, this.prescription, this.tip);
  final String name, prescription, tip;
}

class WorkoutPlan {
  const WorkoutPlan(
    this.id,
    this.title,
    this.type,
    this.minutes,
    this.level,
    this.description,
    this.exercises,
  );
  final String id, title, level, description;
  final ActivityType type;
  final int minutes;
  final List<Exercise> exercises;
}

const plans = [
  WorkoutPlan(
    'strength',
    'Full body strength',
    ActivityType.strength,
    35,
    'Intermediate',
    'Build a stronger you. A balanced session for your whole body.',
    [
      Exercise(
        'Dynamic warm-up',
        '3 minutes',
        'March in place, roll your shoulders, and move gently.',
      ),
      Exercise(
        'Bodyweight squats',
        '3 sets × 12 reps',
        'Keep your chest lifted and knees in line with your toes.',
      ),
      Exercise(
        'Push-ups',
        '3 sets × 10 reps',
        'Keep a straight line from head to heels. Use your knees if needed.',
      ),
      Exercise(
        'Reverse lunges',
        '3 sets × 10 per side',
        'Step back slowly. Keep your front foot grounded.',
      ),
      Exercise(
        'Forearm plank',
        '3 sets × 30 seconds',
        'Brace your core and breathe steadily.',
      ),
      Exercise(
        'Cool-down stretch',
        '3 minutes',
        'Gently stretch the muscles you worked. Never force a stretch.',
      ),
    ],
  ),
  WorkoutPlan(
    'run',
    'Find your running rhythm',
    ActivityType.running,
    30,
    'All levels',
    'Find a comfortable pace and make a little time for yourself.',
    [
      Exercise(
        'Brisk walk',
        '5 minutes',
        'Start slowly and gradually increase your pace.',
      ),
      Exercise(
        'Easy run',
        '10 minutes',
        'Choose a pace where you can still talk.',
      ),
      Exercise(
        'Steady run',
        '10 minutes',
        'Relax your shoulders and keep your steps light.',
      ),
      Exercise(
        'Walk & stretch',
        '5 minutes',
        'Slow to a walk and finish with gentle stretches.',
      ),
    ],
  ),
  WorkoutPlan(
    'yoga',
    'Slow down & stretch',
    ActivityType.yoga,
    20,
    'Beginner',
    'A little less tension. A little more balance. Your daily reset.',
    [
      Exercise(
        'Mindful breathing',
        '2 minutes',
        'Sit comfortably and take slow, relaxed breaths.',
      ),
      Exercise(
        'Cat-cow flow',
        '3 minutes',
        'Move with your breath and avoid forcing your spine.',
      ),
      Exercise(
        'Downward dog',
        '3 × 30 seconds',
        'Bend your knees as needed and lengthen your back.',
      ),
      Exercise(
        'Warrior flow',
        '5 minutes',
        'Keep your front knee above your ankle.',
      ),
      Exercise(
        'Child’s pose',
        '3 minutes',
        'Rest your forehead and release your shoulders.',
      ),
      Exercise(
        'Rest & breathe',
        '4 minutes',
        'Lie comfortably and let your breathing settle.',
      ),
    ],
  ),
  WorkoutPlan(
    'hiit',
    'The energy boost',
    ActivityType.hiit,
    15,
    'Advanced',
    'A short, energetic circuit. Work at your own pace and rest as needed.',
    [
      Exercise(
        'Warm-up',
        '3 minutes',
        'Start with gentle movement and build up gradually.',
      ),
      Exercise(
        'Jumping jacks',
        '3 × 40 seconds',
        'Step out instead of jumping for a low-impact option.',
      ),
      Exercise(
        'Mountain climbers',
        '3 × 30 seconds',
        'Keep your core firm and your hands beneath your shoulders.',
      ),
      Exercise(
        'Squat to reach',
        '3 × 40 seconds',
        'Sit your hips back and stand tall.',
      ),
      Exercise(
        'Rest between rounds',
        '30 seconds each',
        'Take additional rest whenever you need it.',
      ),
      Exercise(
        'Cool down',
        '3 minutes',
        'Slow your breathing with easy walking and stretching.',
      ),
    ],
  ),
  WorkoutPlan(
    'cycle',
    'The scenic route',
    ActivityType.cycling,
    40,
    'All levels',
    'Turn the pedals, clear your mind, and enjoy the journey.',
    [
      Exercise(
        'Easy spin',
        '5 minutes',
        'Check your equipment and begin at an easy pace.',
      ),
      Exercise(
        'Comfortable ride',
        '15 minutes',
        'Keep an even cadence and a relaxed upper body.',
      ),
      Exercise(
        'Steady effort',
        '15 minutes',
        'Increase effort slightly while staying in control.',
      ),
      Exercise(
        'Easy finish',
        '5 minutes',
        'Reduce your effort gradually before stopping.',
      ),
    ],
  ),
  WorkoutPlan(
    'walk',
    'A little fresh air',
    ActivityType.walking,
    25,
    'Beginner',
    'Small steps count. Head outside or walk indoors at a comfortable pace.',
    [
      Exercise(
        'Easy start',
        '5 minutes',
        'Relax your arms and find your natural walking rhythm.',
      ),
      Exercise(
        'Brisk walk',
        '15 minutes',
        'Walk with purpose at a pace that feels comfortable.',
      ),
      Exercise(
        'Slow down',
        '5 minutes',
        'Ease your pace and finish with a gentle calf stretch.',
      ),
    ],
  ),
];

class ActiveSession {
  ActiveSession({
    required this.planId,
    required this.startedAt,
    this.elapsed = 0,
    this.runningSince,
    Set<int>? completed,
  }) : completed = completed ?? {};
  final String planId;
  final DateTime startedAt;
  int elapsed;
  DateTime? runningSince;
  final Set<int> completed;
  WorkoutPlan get plan => plans.firstWhere((p) => p.id == planId);
  int secondsAt(DateTime now) =>
      elapsed +
      (runningSince == null
          ? 0
          : now.difference(runningSince!).inSeconds.clamp(0, 86400));
  Map<String, dynamic> toJson() => {
    'planId': planId,
    'startedAt': startedAt.toIso8601String(),
    'elapsed': elapsed,
    'runningSince': runningSince?.toIso8601String(),
    'completed': completed.toList(),
  };
  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    final planId = _text(json, 'planId', 40);
    final plan = plans.firstWhere((p) => p.id == planId);
    final done = (json['completed'] as List).map((v) {
      if (v is! int || v < 0 || v >= plan.exercises.length) {
        throw const FormatException('Invalid exercise');
      }
      return v;
    }).toSet();
    return ActiveSession(
      planId: planId,
      startedAt: _date(json['startedAt']),
      elapsed: _int(json, 'elapsed', 0, 86400),
      runningSince: json['runningSince'] == null
          ? null
          : _date(json['runningSince']),
      completed: done,
    );
  }
}

class FitnessData {
  FitnessData({
    this.goalLevel = GoalLevel.regular,
    List<Workout>? workouts,
    List<WeightEntry>? weights,
    Map<String, int>? water,
    this.demo = false,
    this.session,
  }) : workouts = workouts ?? [],
       weights = weights ?? [],
       water = water ?? {};
  GoalLevel goalLevel;
  final List<Workout> workouts;
  final List<WeightEntry> weights;
  final Map<String, int> water;
  bool demo;
  ActiveSession? session;
  Map<String, dynamic> toJson() => {
    'version': 2,
    'goalLevel': goalLevel.name,
    'workouts': workouts.map((w) => w.toJson()).toList(),
    'weights': weights.map((w) => w.toJson()).toList(),
    'water': water,
    'demo': demo,
    'session': session?.toJson(),
  };
  String encode() => jsonEncode(toJson());
  factory FitnessData.decode(String raw) {
    if (raw.length > 5000000) {
      throw const FormatException('Saved data is too large');
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if ((json['version'] != 1 && json['version'] != 2) ||
        json['demo'] is! bool) {
      throw const FormatException('Unsupported FitX data');
    }
    final water = (json['water'] as Map<String, dynamic>).map((key, value) {
      if (dayKey(DateTime.parse(key)) != key ||
          value is! int ||
          value < 0 ||
          value > 20000) {
        throw const FormatException('Invalid hydration entry');
      }
      return MapEntry(key, value);
    });
    final workouts = (json['workouts'] as List)
        .map((w) => Workout.fromJson(w as Map<String, dynamic>))
        .toList();
    if (workouts.map((w) => w.id).toSet().length != workouts.length) {
      throw const FormatException('Duplicate workout IDs');
    }
    return FitnessData(
      goalLevel: json['version'] == 1
          ? GoalLevel.regular
          : GoalLevel.values.byName(_text(json, 'goalLevel', 20)),
      workouts: workouts,
      weights: (json['weights'] as List)
          .map((w) => WeightEntry.fromJson(w as Map<String, dynamic>))
          .toList(),
      water: water,
      demo: json['demo'] as bool,
      session: json['session'] == null
          ? null
          : ActiveSession.fromJson(json['session'] as Map<String, dynamic>),
    );
  }
  factory FitnessData.sample(DateTime now) {
    final workouts = <Workout>[];
    for (var day = 0; day < 28; day++) {
      if (day % 7 == 5 || day % 7 == 3) {
        continue;
      }
      final type = ActivityType.values[day % ActivityType.values.length];
      workouts.add(
        Workout(
          id: 'sample-$day',
          title: switch (type) {
            ActivityType.strength => 'Full body strength',
            ActivityType.running => 'Morning run',
            ActivityType.yoga => 'Evening yoga flow',
            ActivityType.cycling => 'Neighborhood ride',
            ActivityType.walking => 'Afternoon walk',
            ActivityType.hiit => 'Quick HIIT session',
          },
          type: type,
          date: day == 0
              ? now
              : DateTime(now.year, now.month, now.day - day, 7, 30),
          seconds: (25 + (day * 7) % 25) * 60,
          calories: 160 + (day * 43) % 300,
          distance: type == ActivityType.running
              ? 4.2
              : type == ActivityType.cycling
              ? 12.5
              : type == ActivityType.walking
              ? 2.4
              : 0,
          steps: type == ActivityType.running
              ? 5600
              : type == ActivityType.walking
              ? 3400
              : 0,
          notes: 'Sample activity. Start fresh when you’re ready to track your own progress.',
        ),
      );
    }
    return FitnessData(
      demo: true,
      workouts: workouts,
      weights: List.generate(
        8,
        (i) => WeightEntry(
          dateOnly(now).subtract(Duration(days: (7 - i) * 4)),
          76.8 - i * 0.25,
        ),
      ),
      water: {dayKey(now): 1500},
    );
  }
}

String _text(
  Map<String, dynamic> json,
  String key,
  int max, {
  bool empty = false,
}) {
  final value = json[key];
  if (value is! String ||
      value.length > max ||
      (!empty && value.trim().isEmpty)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

double _num(Map<String, dynamic> json, String key, double min, double max) {
  final value = json[key];
  if (value is! num || !value.isFinite || value < min || value > max) {
    throw FormatException('Invalid $key');
  }
  return value.toDouble();
}

int _int(Map<String, dynamic> json, String key, int min, int max) {
  if (json[key] is! int) {
    throw FormatException('Invalid $key');
  }
  return _num(json, key, min.toDouble(), max.toDouble()).toInt();
}

DateTime _date(dynamic value) {
  if (value is! String) {
    throw const FormatException('Invalid date');
  }
  final date = DateTime.parse(value).toLocal();
  if (date.year < 2000 ||
      date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
    throw const FormatException('Date is out of range');
  }
  return date;
}
