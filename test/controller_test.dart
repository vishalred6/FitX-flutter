import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitx/controller.dart';
import 'package:fitx/models.dart';

import 'support.dart';

void main() {
  group('Local data and calculations', () {
    late MemoryStorage storage;
    late FitnessController controller;
    late DateTime now;
    setUp(() {
      now = fixtureNow;
      storage = MemoryStorage(FitnessData().encode());
      controller = FitnessController(storage, clock: () => now);
    });
    tearDown(() => controller.dispose());

    test(
      'first launch creates explicitly labeled sample data and persists it',
      () async {
        storage.value = null;
        await controller.load();
        expect(controller.data.demo, isTrue);
        expect(controller.data.workouts, isNotEmpty);
        expect(FitnessData.decode(storage.value!).demo, isTrue);
      },
    );
    test(
      'activity create, edit, delete and reload update derived totals',
      () async {
        await controller.load();
        await controller.addWorkout(activity('one'));
        expect(controller.totalMinutes, 30);
        expect(controller.totalCalories, 200);
        expect(controller.totalSteps, 3000);
        await controller.updateWorkout(
          activity('one', seconds: 3600, calories: 400),
        );
        expect(controller.totalMinutes, 60);
        final reloaded = FitnessController(storage, clock: () => now);
        await reloaded.load();
        expect(reloaded.totalCalories, 400);
        expect(reloaded.data.workouts.single.id, 'one');
        reloaded.dispose();
        await controller.deleteWorkout('one');
        expect(controller.totalMinutes, 0);
        expect(FitnessData.decode(storage.value!).workouts, isEmpty);
      },
    );
    test('duplicate activity is rejected', () async {
      await controller.load();
      await controller.addWorkout(activity('one'));
      await expectLater(
        controller.addWorkout(activity('one')),
        throwsStateError,
      );
      expect(controller.data.workouts.length, 1);
    });
    test(
      'daily metrics, weekly totals and activity chart respect dates',
      () async {
        await controller.load();
        await controller.addWorkout(activity('today'));
        await controller.addWorkout(
          activity('yesterday', date: now.subtract(const Duration(days: 1))),
        );
        await controller.addWorkout(
          activity('last-week', date: now.subtract(const Duration(days: 8))),
        );
        expect(controller.totalMinutes, 30);
        expect(controller.thisWeek.length, 2);
        expect(controller.activitySeries(7), [0, 0, 0, 0, 0, 30, 30]);
      },
    );
    test('streak counts unique consecutive days and tolerates today not yet logged', () async {
      await controller.load();
      for (var i = 1; i <= 3; i++) {
        await controller.addWorkout(
          activity('$i', date: now.subtract(Duration(days: i))),
        );
      }
      expect(controller.streak, 3);
      await controller.addWorkout(activity('today'));
      await controller.addWorkout(activity('today-again'));
      expect(controller.streak, 4);
      now = now.add(const Duration(days: 2));
      expect(controller.streak, 0);
    });
    test(
      'hydration persists, clamps at zero, and resets across midnight',
      () async {
        await controller.load();
        await controller.addWater(250);
        await controller.addWater(250);
        expect(controller.waterToday, 500);
        await controller.addWater(-1000);
        expect(controller.waterToday, 0);
        await controller.addWater(750);
        now = now.add(const Duration(days: 1));
        expect(controller.waterToday, 0);
        expect(controller.data.water[dayKey(fixtureNow)], 750);
      },
    );
    test(
      'weight check-ins replace the same date and use the latest date',
      () async {
        await controller.load();
        await controller.addWeight(now, 74.2);
        await controller.addWeight(now, 74.0);
        await controller.addWeight(now.subtract(const Duration(days: 10)), 80);
        expect(controller.data.weights.length, 2);
        expect(controller.currentWeight, 74);
        await controller.removeWeight(now);
        expect(controller.currentWeight, 80);
      },
    );
    test(
      'tracking reset keeps goals and removes sample and session data',
      () async {
        await controller.load();
        await controller.setGoalLevel(GoalLevel.easy);
        await controller.startSession(plans.first);
        await controller.addWorkout(activity('one'));
        await controller.addWeight(now, 75);
        await controller.addWater(250);
        await controller.reset();
        expect(controller.data.goalLevel, GoalLevel.easy);
        expect(controller.data.toJson().containsKey('profile'), isFalse);
        expect(controller.data.session, isNull);
        expect(controller.data.workouts, isEmpty);
        expect(controller.data.weights, isEmpty);
        expect(controller.data.water, isEmpty);
        expect(controller.data.demo, isFalse);
      },
    );
    test('local data round trip retains tracking records and rejects invalid values', () async {
      await controller.load();
      await controller.addWorkout(activity('one'));
      await controller.addWater(500);
      await controller.startSession(plans.first);
      await controller.toggleExercise(0);
      final saved = controller.data.encode();
      final reloaded = FitnessData.decode(saved);
      expect(reloaded.workouts.single.id, 'one');
      expect(reloaded.water[dayKey(now)], 500);
      expect(reloaded.session!.completed, {0});
      expect(() => FitnessData.decode('{"version":99}'), throwsA(anything));
      final broken = jsonDecode(saved) as Map<String, dynamic>;
      broken['workouts'][0]['seconds'] = -2;
      expect(() => FitnessData.decode(jsonEncode(broken)), throwsA(anything));
    });
    test('old local data keeps activities but removes all account and preference fields', () async {
      storage.value = jsonEncode(
        legacySavedData(FitnessData(workouts: [activity('existing')])),
      );
      await controller.load();
      expect(controller.data.workouts.single.id, 'existing');
      expect(controller.data.goalLevel, GoalLevel.regular);
      final saved = jsonDecode(storage.value!) as Map<String, dynamic>;
      expect(saved['version'], 2);
      expect(saved.containsKey('profile'), isFalse);
      expect(saved.containsKey('dark'), isFalse);
      expect(saved.toString(), isNot(contains('Previous account')));
    });
    test('only two goal levels exist and both survive a reload', () async {
      expect(GoalLevel.values.length, 2);
      expect(GoalLevel.regular.weeklyWorkouts, 4);
      expect(GoalLevel.regular.dailyMinutes, 45);
      expect(GoalLevel.regular.dailySteps, 8000);
      expect(GoalLevel.regular.dailyCalories, 500);
      expect(GoalLevel.regular.waterMl, 2500);
      await controller.load();
      await controller.setGoalLevel(GoalLevel.easy);
      final reloaded = FitnessController(storage, clock: () => now);
      await reloaded.load();
      expect(reloaded.data.goalLevel, GoalLevel.easy);
      expect(reloaded.data.goalLevel.dailyMinutes, 20);
      expect(reloaded.data.goalLevel.dailySteps, 4000);
      await reloaded.setGoalLevel(GoalLevel.regular);
      expect(FitnessData.decode(storage.value!).goalLevel, GoalLevel.regular);
      reloaded.dispose();
    });
    test('cached activity results stay correct after edits, deletion and a new day', () async {
      await controller.load();
      await controller.addWorkout(activity('first'));
      final series = controller.activitySeries(28);
      final sorted = controller.sortedWorkouts;
      await controller.addWater(250);
      await controller.setGoalLevel(GoalLevel.easy);
      expect(identical(series, controller.activitySeries(28)), isTrue);
      expect(identical(sorted, controller.sortedWorkouts), isTrue);
      await controller.updateWorkout(activity('first', seconds: 2400));
      expect(controller.activitySeries(28).last, 40);
      expect(controller.totalMinutes, 40);
      expect(identical(series, controller.activitySeries(28)), isFalse);
      now = now.add(const Duration(days: 1));
      expect(controller.activitySeries(28).last, 0);
      expect(controller.activitySeries(28)[26], 40);
      expect(controller.totalMinutes, 0);
      await controller.deleteWorkout('first');
      expect(
        controller.activitySeries(28).every((value) => value == 0),
        isTrue,
      );
    });
    test('save completion and unchanged clock refreshes do not rebuild application data', () async {
      await controller.load();
      var changes = 0;
      controller.addListener(() => changes++);
      await controller.addWater(250);
      expect(changes, 1);
      controller.refresh();
      expect(changes, 1);
      now = now.add(const Duration(days: 1));
      controller.refresh();
      expect(changes, 2);
    });
    test('corrupt saved data is preserved and reported during load', () async {
      storage.value = 'corrupt';
      await expectLater(controller.load(), throwsA(anything));
      expect(storage.value, 'corrupt');
    });
    test(
      'failed write remains visible and retry persists in-memory changes',
      () async {
        await controller.load();
        storage.fail = true;
        await expectLater(controller.addWater(250), throwsStateError);
        expect(controller.unsaved, isTrue);
        expect(controller.storageError, isNotNull);
        expect(controller.waterToday, 250);
        storage.fail = false;
        await controller.save();
        expect(controller.unsaved, isFalse);
        expect(controller.storageError, isNull);
        expect(FitnessData.decode(storage.value!).water[dayKey(now)], 250);
      },
    );
  });

  test(
    'running workout resumes after reload and excludes paused time',
    () async {
      var now = fixtureNow;
      final storage = MemoryStorage(FitnessData().encode());
      final controller = FitnessController(storage, clock: () => now);
      await controller.load();
      await controller.startSession(plans.first);
      await expectLater(controller.startSession(plans[1]), throwsStateError);
      now = now.add(const Duration(seconds: 90));
      await controller.toggleSession();
      expect(controller.data.session!.secondsAt(now), 90);
      now = now.add(const Duration(minutes: 5));
      expect(controller.data.session!.secondsAt(now), 90);
      await controller.toggleExercise(0);
      await controller.toggleSession();
      now = now.add(const Duration(seconds: 30));
      final reloaded = FitnessController(storage, clock: () => now);
      await reloaded.load();
      expect(reloaded.data.session!.secondsAt(now), 120);
      expect(reloaded.data.session!.completed, {0});
      final workout = await reloaded.finishSession(notes: 'Feeling great');
      expect(workout.seconds, 120);
      expect(workout.notes, 'Feeling great');
      expect(workout.calories, greaterThan(0));
      expect(reloaded.data.session, isNull);
      expect(FitnessData.decode(storage.value!).workouts.single.seconds, 120);
      await expectLater(reloaded.finishSession(), throwsStateError);
      controller.dispose();
      reloaded.dispose();
    },
  );

  test(
    'queued writes cannot overwrite a newer snapshot with older data',
    () async {
      final storage = _DelayedStorage();
      final controller = FitnessController(storage, clock: () => fixtureNow);
      final first = controller.addWater(250);
      final second = controller.addWater(250);
      await Future<void>.delayed(Duration.zero);
      expect(storage.calls.length, 1);
      storage.calls.first.complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(controller.unsaved, isTrue);
      expect(storage.calls.length, 2);
      storage.calls.last.complete();
      await second;
      expect(FitnessData.decode(storage.value!).water[dayKey(fixtureNow)], 500);
      expect(controller.unsaved, isFalse);
      controller.dispose();
    },
  );
}

class _DelayedStorage implements FitnessStorage {
  String? value;
  final calls = <Completer<void>>[];
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    final done = Completer<void>();
    calls.add(done);
    await done.future;
    this.value = value;
  }
}
