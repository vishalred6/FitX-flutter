import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitx/controller.dart';
import 'package:fitx/models.dart';

import 'storage_platform_stub.dart'
    if (dart.library.js_interop) 'storage_platform_web.dart';
import 'support.dart';

void main() {
  testWidgets(
    'local migration deletes obsolete account storage and keeps fitness records',
    (tester) async {
      registerBrowserStorage();
      final preferences = SharedPreferencesAsync();
      final original = await preferences.getString(LocalFitnessStorage.key);
      final previous = await preferences.getString(
        LocalFitnessStorage.legacyKey,
      );
      final old = jsonEncode(
        legacySavedData(FitnessData(workouts: [activity('existing')])),
      );
      try {
        await preferences.setString(LocalFitnessStorage.key, old);
        await preferences.setString(LocalFitnessStorage.legacyKey, old);
        final controller = FitnessController(
          LocalFitnessStorage(),
          clock: () => fixtureNow,
        );
        await controller.load();
        expect(controller.data.workouts.single.id, 'existing');
        expect(controller.data.goalLevel, GoalLevel.regular);
        expect(
          await preferences.getString(LocalFitnessStorage.legacyKey),
          isNull,
        );
        final saved = jsonDecode(
          (await preferences.getString(LocalFitnessStorage.key))!,
        ) as Map<String, dynamic>;
        expect(saved['version'], 2);
        expect(saved.containsKey('profile'), isFalse);
        expect(saved.containsKey('dark'), isFalse);
        expect(saved.toString(), isNot(contains('Previous account')));
        await controller.setGoalLevel(GoalLevel.easy);
        final reloaded = FitnessController(
          LocalFitnessStorage(),
          clock: () => fixtureNow,
        );
        await reloaded.load();
        expect(reloaded.data.goalLevel, GoalLevel.easy);
        expect(reloaded.data.workouts.single.id, 'existing');
        controller.dispose();
        reloaded.dispose();
      } finally {
        if (original == null) {
          await preferences.remove(LocalFitnessStorage.key);
        } else {
          await preferences.setString(LocalFitnessStorage.key, original);
        }
        if (previous == null) {
          await preferences.remove(LocalFitnessStorage.legacyKey);
        } else {
          await preferences.setString(LocalFitnessStorage.legacyKey, previous);
        }
      }
    },
    skip: !kIsWeb,
  );

  testWidgets(
    'browser storage retains goals, activities, hydration, weight and active sessions',
    (tester) async {
      registerBrowserStorage();
      final storage = LocalFitnessStorage();
      final original = await storage.read();
      final first = FitnessController(storage, clock: () => fixtureNow);
      final second = FitnessController(
        LocalFitnessStorage(),
        clock: () => fixtureNow.add(const Duration(minutes: 2)),
      );
      try {
        await storage.write(FitnessData().encode());
        await first.load();
        await first.setGoalLevel(GoalLevel.easy);
        await first.addWorkout(activity('browser-workout'));
        await first.addWater(750);
        await first.addWeight(fixtureNow, 72.5);
        await first.startSession(plans.first);
        await first.toggleExercise(1);
        await second.load();
        expect(second.data.goalLevel, GoalLevel.easy);
        expect(second.data.workouts.single.id, 'browser-workout');
        expect(second.waterToday, 750);
        expect(second.currentWeight, 72.5);
        expect(second.data.session!.completed, {1});
        expect(second.data.session!.secondsAt(second.clock()), 120);
        final saved = await second.finishSession();
        expect(saved.seconds, 120);
        final third = FitnessController(
          LocalFitnessStorage(),
          clock: () => fixtureNow,
        );
        await third.load();
        expect(third.data.workouts.length, 2);
        expect(third.data.session, isNull);
        third.dispose();
      } finally {
        first.dispose();
        second.dispose();
        if (original != null) {
          await storage.write(original);
        } else {
          await SharedPreferencesAsync().remove(LocalFitnessStorage.key);
        }
      }
    },
    skip: !kIsWeb,
  );
}
