import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

abstract interface class FitnessStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class LocalFitnessStorage implements FitnessStorage {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const key = 'fitx.fitness.v1';
  static const legacyKey = 'stride.fitness.v1';

  @override
  Future<String?> read() async {
    final current = await _preferences.getString(key);
    final previous = await _preferences.getString(legacyKey);
    final raw = current ?? previous;
    if (raw == null) {
      return null;
    }
    // Keep tracking records while removing obsolete account and preference data.
    final cleaned = FitnessData.decode(raw).encode();
    if (current != cleaned) {
      await _preferences.setString(key, cleaned);
    }
    if (previous != null) {
      await _preferences.remove(legacyKey);
    }
    return cleaned;
  }

  @override
  Future<void> write(String value) => _preferences.setString(key, value);
}

@immutable
class PersistenceState {
  const PersistenceState({this.unsaved = false, this.error});
  final bool unsaved;
  final String? error;
}

class FitnessController extends ChangeNotifier {
  FitnessController(this.storage, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final FitnessStorage storage;
  final DateTime Function() clock;
  FitnessData data = FitnessData();
  final persistence = ValueNotifier<PersistenceState>(const PersistenceState());
  Future<void> _writes = Future.value();
  int _revision = 0;
  String? _day;
  List<Workout>? _sortedWorkouts;
  Map<String, _DayActivity>? _days;
  List<WeightEntry>? _sortedWeights;
  final _series = <int, List<double>>{};

  bool get unsaved => persistence.value.unsaved;
  String? get storageError => persistence.value.error;

  void _persistence(bool unsaved, String? error) {
    if (this.unsaved != unsaved || storageError != error) {
      persistence.value = PersistenceState(unsaved: unsaved, error: error);
    }
  }

  void _invalidateActivities() {
    _sortedWorkouts = null;
    _days = null;
    _series.clear();
  }

  void _indexActivities() {
    if (_days != null) {
      return;
    }
    final grouped = <String, List<Workout>>{};
    for (final workout in data.workouts) {
      (grouped[dayKey(workout.date)] ??= []).add(workout);
    }
    _days = grouped.map(
      (key, workouts) => MapEntry(key, _DayActivity(workouts)),
    );
  }

  void _checkDay() {
    final day = dayKey(clock());
    if (_day != day) {
      _day = day;
      _series.clear();
    }
  }

  Future<void> load() async {
    final raw = await storage.read();
    data = raw == null ? FitnessData.sample(clock()) : FitnessData.decode(raw);
    _invalidateActivities();
    _sortedWeights = null;
    _checkDay();
    if (raw == null || raw != data.encode()) {
      await save();
    } else {
      notifyListeners();
    }
  }

  Future<void> save() {
    final payload = data.encode();
    final revision = ++_revision;
    _persistence(true, storageError);
    // Notify the application once for a data change. Storage completion only
    // updates the small status widgets, rather than rebuilding every screen.
    notifyListeners();
    final write = _writes.then((_) => storage.write(payload));
    _writes = write.catchError((Object _) {});
    return write.then(
      (_) {
        if (revision == _revision) {
          _persistence(false, null);
        }
      },
      onError: (Object error) {
        _persistence(
          true,
          'Changes are in memory but could not be saved. Check browser storage and retry.',
        );
        throw error;
      },
    );
  }

  List<Workout> get sortedWorkouts => _sortedWorkouts ??= List.unmodifiable(
    [...data.workouts]..sort((a, b) => b.date.compareTo(a.date)),
  );
  List<WeightEntry> get sortedWeights => _sortedWeights ??= List.unmodifiable(
    [...data.weights]..sort((a, b) => a.date.compareTo(b.date)),
  );
  List<Workout> onDay(DateTime date) {
    _indexActivities();
    return _days![dayKey(date)]?.workouts ?? const [];
  }

  _DayActivity? get _today {
    _indexActivities();
    return _days![dayKey(clock())];
  }

  List<Workout> get today => _today?.workouts ?? const [];
  DateTime get weekStart {
    final now = clock();
    return DateTime(now.year, now.month, now.day - now.weekday + 1);
  }

  List<Workout> get thisWeek {
    final now = clock();
    final start = weekStart;
    return [
      for (var i = 0; i < 7; i++)
        ...onDay(DateTime(start.year, start.month, start.day + i))
            .where((w) => !w.date.isAfter(now)),
    ];
  }

  int get totalMinutes => _today?.minutes ?? 0;
  int get totalCalories => _today?.calories ?? 0;
  int get totalSteps => _today?.steps ?? 0;
  int get waterToday => data.water[dayKey(clock())] ?? 0;
  double get currentWeight =>
      sortedWeights.isEmpty ? 75 : sortedWeights.last.kg;
  int get streak {
    _indexActivities();
    var cursor = dateOnly(clock());
    if (!_days!.containsKey(dayKey(cursor))) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var count = 0;
    while (_days!.containsKey(dayKey(cursor))) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  List<double> activitySeries(int days) {
    _checkDay();
    _indexActivities();
    final now = clock();
    return _series.putIfAbsent(
      days,
      () => List.unmodifiable(
        List.generate(
          days,
          (i) =>
              (_days![dayKey(
                            DateTime(
                              now.year,
                              now.month,
                              now.day - days + 1 + i,
                            ),
                          )]
                          ?.minutes ??
                      0)
                  .toDouble(),
        ),
      ),
    );
  }

  Future<void> addWorkout(Workout workout) async {
    if (data.workouts.any((w) => w.id == workout.id)) {
      throw StateError('This workout is already saved.');
    }
    data.workouts.add(workout);
    _invalidateActivities();
    await save();
  }

  Future<void> deleteWorkout(String id) async {
    data.workouts.removeWhere((w) => w.id == id);
    _invalidateActivities();
    await save();
  }

  Future<void> updateWorkout(Workout workout) async {
    final index = data.workouts.indexWhere((w) => w.id == workout.id);
    if (index < 0) {
      throw StateError('Workout not found.');
    }
    data.workouts[index] = workout;
    _invalidateActivities();
    await save();
  }

  void refresh() {
    final previous = _day;
    _checkDay();
    if (previous != _day) {
      notifyListeners();
    }
  }

  Future<void> addWater(int ml) async {
    data.water[dayKey(clock())] = (waterToday + ml).clamp(0, 20000);
    await save();
  }

  Future<void> setGoalLevel(GoalLevel level) async {
    if (data.goalLevel == level) {
      return;
    }
    data.goalLevel = level;
    await save();
  }

  Future<void> addWeight(DateTime date, double kg) async {
    data.weights.removeWhere((w) => sameDay(w.date, date));
    data.weights.add(WeightEntry(dateOnly(date), kg));
    _sortedWeights = null;
    await save();
  }

  Future<void> removeWeight(DateTime date) async {
    data.weights.removeWhere((w) => sameDay(w.date, date));
    _sortedWeights = null;
    await save();
  }

  Future<void> reset() async {
    data = FitnessData(goalLevel: data.goalLevel);
    _invalidateActivities();
    _sortedWeights = null;
    await save();
  }

  Future<void> startSession(WorkoutPlan plan) async {
    if (data.session != null) {
      throw StateError('Finish or discard your current workout first.');
    }
    final now = clock();
    data.session = ActiveSession(
      planId: plan.id,
      startedAt: now,
      runningSince: now,
    );
    await save();
  }

  Future<void> toggleSession() async {
    final session = data.session;
    if (session == null) {
      return;
    }
    if (session.runningSince != null) {
      session.elapsed = session.secondsAt(clock()).clamp(0, 86400);
      session.runningSince = null;
    } else {
      session.runningSince = clock();
    }
    await save();
  }

  Future<void> toggleExercise(int index) async {
    final session = data.session;
    if (session == null ||
        index < 0 ||
        index >= session.plan.exercises.length) {
      return;
    }
    if (!session.completed.add(index)) {
      session.completed.remove(index);
    }
    await save();
  }

  Future<Workout> finishSession({String notes = ''}) async {
    final session = data.session;
    if (session == null) {
      throw StateError('No active workout.');
    }
    final seconds = session.secondsAt(clock()).clamp(1, 86400);
    final workout = Workout(
      id: 'workout-${clock().microsecondsSinceEpoch}',
      title: session.plan.title,
      type: session.plan.type,
      date: clock(),
      seconds: seconds,
      calories:
          (session.plan.type.met * 3.5 * currentWeight / 200 * seconds / 60)
              .round()
              .clamp(0, 20000),
      notes: notes,
    );
    data.workouts.add(workout);
    data.session = null;
    _invalidateActivities();
    await save();
    return workout;
  }

  Future<void> discardSession() async {
    data.session = null;
    await save();
  }

  @override
  void dispose() {
    persistence.dispose();
    super.dispose();
  }
}

class _DayActivity {
  _DayActivity(List<Workout> values) : workouts = List.unmodifiable(values) {
    for (final workout in values) {
      minutes += workout.minutes;
      calories += workout.calories;
      steps += workout.steps;
    }
  }
  final List<Workout> workouts;
  int minutes = 0, calories = 0, steps = 0;
}

class FitnessScope extends InheritedNotifier<FitnessController> {
  const FitnessScope({
    super.key,
    required FitnessController controller,
    required super.child,
  }) : super(notifier: controller);
  static FitnessController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FitnessScope>()!.notifier!;
}
