import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitx/app.dart';
import 'package:fitx/controller.dart';
import 'package:fitx/dialogs.dart';
import 'package:fitx/models.dart';

import 'support.dart';
import 'storage_platform_stub.dart'
    if (dart.library.js_interop) 'storage_platform_web.dart';

bool fontLoaded = false;

Future<FitnessController> mount(
  WidgetTester tester, {
  Size size = const Size(1440, 1000),
  bool sample = true,
  String? savedData,
  DateTime Function()? clock,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  if (!fontLoaded) {
    await tester.runAsync(() async {
      final font = FontLoader('Manrope')..addFont(loadTestFont());
      await font.load();
      fontLoaded = true;
    });
  }
  final controller = FitnessController(
    MemoryStorage(
      savedData ??
          (sample ? FitnessData.sample(fixtureNow) : FitnessData()).encode(),
    ),
    clock: clock,
  );
  await tester.pumpWidget(FitXApp(controller: controller));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> unmount(WidgetTester tester, FitnessController controller) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  controller.dispose();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'FitX stays dark with a light system preference and older saved data',
    (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final legacy = legacySavedData(FitnessData.sample(fixtureNow));
      final controller = await mount(tester, savedData: jsonEncode(legacy));
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        startsWith('FitX'),
      );
      expect(
        Theme.of(tester.element(find.byType(AppShell))).brightness,
        Brightness.dark,
      );
      await controller.setGoalLevel(GoalLevel.easy);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(AppShell))).brightness,
        Brightness.dark,
      );
      expect(controller.data.workouts, isNotEmpty);
      expect(controller.data.toJson().containsKey('profile'), isFalse);
      expect(tester.takeException(), isNull);
      await unmount(tester, controller);
    },
  );
  for (final size in [
    const Size(320, 740),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 1000),
    const Size(1440, 700),
    const Size(740, 390),
  ]) {
    testWidgets(
      'all screens lay out without errors at ${size.width.toInt()} px',
      (tester) async {
        final controller = await mount(tester, size: size);
        expect(find.textContaining('Let’s make today count'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await controller.startSession(plans.first);
        for (final route in [
          '/workouts',
          '/session',
          '/history',
          '/progress',
        ]) {
          final context = tester.element(find.byType(AppShell).last);
          Navigator.of(context).pushReplacementNamed(route);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$route at ${size.width} px',
          );
        }
        await unmount(tester, controller);
      },
    );
  }

  testWidgets('log form rejects invalid input and adds a real activity', (
    tester,
  ) async {
    final controller = await mount(tester, sample: false);
    await tester.tap(find.text('Log activity').first);
    await tester.pumpAndSettle();
    final title = find.widgetWithText(TextFormField, 'Activity name');
    final duration = find.widgetWithText(TextFormField, 'Duration');
    await tester.enterText(title, '');
    await tester.enterText(duration, '-1');
    await tester.ensureVisible(find.text('Save activity'));
    await tester.tap(find.text('Save activity'));
    await tester.pumpAndSettle();
    expect(find.text('Give your activity a name'), findsOneWidget);
    expect(controller.data.workouts, isEmpty);
    await tester.enterText(title, 'Lunch break walk');
    await tester.enterText(duration, '25');
    await tester.ensureVisible(find.text('Save activity'));
    await tester.tap(find.text('Save activity'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutForm), findsNothing);
    expect(controller.data.workouts.single.title, 'Lunch break walk');
    expect(controller.totalMinutes, 25);
    expect(controller.data.workouts.single.calories, greaterThan(0));
    await unmount(tester, controller);
  });

  testWidgets('workout can be started, paused, checked off, and saved', (
    tester,
  ) async {
    final controller = await mount(tester, sample: false);
    Navigator.of(tester.element(find.byType(AppShell))).pushNamed('/workouts');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View workout').first);
    await tester.tap(find.text('View workout').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start this workout'));
    await tester.tap(find.text('Start this workout'));
    await tester.pumpAndSettle();
    expect(controller.data.session, isNotNull);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(controller.data.session!.completed, {0});
    await tester.ensureVisible(find.text('Pause timer'));
    await tester.tap(find.text('Pause timer'));
    await tester.pumpAndSettle();
    expect(controller.data.session!.runningSince, isNull);
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save workout'));
    await tester.pumpAndSettle();
    expect(controller.data.session, isNull);
    expect(controller.data.workouts.length, 1);
    expect(find.text('Every effort has a story.'), findsOneWidget);
    await unmount(tester, controller);
  });

  testWidgets(
    'activity search filters records and detail deletion updates history',
    (tester) async {
      final controller = await mount(tester, sample: false);
      await controller.addWorkout(activity('walk'));
      Navigator.of(tester.element(find.byType(AppShell))).pushNamed('/history');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'nonexistent');
      await tester.pumpAndSettle();
      expect(find.text('No matching activities'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Afternoon walk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete activity'));
      await tester.pumpAndSettle();
      expect(controller.data.workouts, isEmpty);
      await unmount(tester, controller);
    },
  );

  testWidgets(
    'Overview changes both goal levels and has no accounts or Settings links',
    (tester) async {
      final controller = await mount(tester, sample: false);
      expect(destinations.length, 4);
      expect(find.text('Settings'), findsNothing);
      expect(find.textContaining('Alex'), findsNothing);
      expect(find.text('Personal account'), findsNothing);
      expect(find.text('Regular'), findsOneWidget);
      await tester.ensureVisible(find.text('Easy'));
      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();
      expect(controller.data.goalLevel, GoalLevel.easy);
      expect(find.text('of 20 min daily goal'), findsOneWidget);
      expect(find.text('of 4,000 daily goal'), findsOneWidget);
      expect(find.text('/ 2.00 L'), findsOneWidget);
      await tester.ensureVisible(find.text('Regular'));
      await tester.tap(find.text('Regular'));
      await tester.pumpAndSettle();
      expect(controller.data.goalLevel, GoalLevel.regular);
      expect(find.text('of 45 min daily goal'), findsOneWidget);
      expect(find.text('of 8,000 daily goal'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(tester.takeException(), isNull);
      await unmount(tester, controller);
    },
  );

  testWidgets('hydration updates preserve the MaterialApp widget and theme', (
    tester,
  ) async {
    final controller = await mount(tester, sample: false);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    await controller.addWater(250);
    await tester.pumpAndSettle();
    expect(
      identical(app, tester.widget<MaterialApp>(find.byType(MaterialApp))),
      isTrue,
    );
    expect(
      Theme.of(tester.element(find.byType(AppShell))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
    await unmount(tester, controller);
  });

  testWidgets(
    'ticking a session updates its clock without rebuilding exercises',
    (tester) async {
      var now = fixtureNow;
      final controller = await mount(tester, sample: false, clock: () => now);
      await controller.startSession(plans.first);
      Navigator.of(tester.element(find.byType(AppShell))).pushNamed('/session');
      await tester.pumpAndSettle();
      final exercise = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      now = now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('00:00:02'), findsOneWidget);
      expect(
        identical(
          exercise,
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile).first),
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await unmount(tester, controller);
    },
  );
}
