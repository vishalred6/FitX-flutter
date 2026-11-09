import 'dart:async';

import 'package:flutter/material.dart';

import 'controller.dart';
import 'dashboard.dart';
import 'history.dart';
import 'models.dart';
import 'progress.dart';
import 'ui.dart';
import 'workouts.dart';

class FitXApp extends StatefulWidget {
  const FitXApp({super.key, this.controller});
  final FitnessController? controller;
  @override
  State<FitXApp> createState() => _FitXAppState();
}

class _FitXAppState extends State<FitXApp> {
  late final FitnessController controller;
  late Future<void> loading;
  Timer? dayTimer;
  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? FitnessController(LocalFitnessStorage());
    loading = controller.load();
    dayTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => controller.refresh(),
    );
  }

  @override
  void dispose() {
    dayTimer?.cancel();
    if (widget.controller == null) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FitnessScope(
    controller: controller,
    child: MaterialApp(
      title: 'FitX · Your everyday fitness companion',
      debugShowCheckedModeBanner: false,
      theme: fitxTheme(),
      themeMode: ThemeMode.dark,
      builder: (context, child) => FutureBuilder<void>(
        future: loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Brand(),
                    SizedBox(height: 28),
                    CircularProgressIndicator(strokeWidth: 2),
                  ],
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Surface(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const IconTile(Icons.storage_rounded, size: 64),
                          const SizedBox(height: 20),
                          const Text(
                            'Let’s recover your space',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your saved data could not be opened. Enable browser storage and retry. Reset only if you want to replace the current saved data.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.7,
                              color: Palette.muted(context),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () =>
                                setState(() => loading = controller.load()),
                            child: const Text('Retry loading'),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (await confirm(
                                context,
                                title: 'Reset saved data?',
                                message: 'This replaces the saved data that could not be loaded. This action cannot be undone.',
                                label: 'Reset data',
                                destructive: true,
                              )) {
                                if (!context.mounted) {
                                  return;
                                }
                                final ok = await runAction(
                                  context,
                                  () => controller.reset(),
                                );
                                if (ok && mounted) {
                                  setState(() => loading = Future.value());
                                }
                              }
                            },
                            child: const Text('Reset saved data'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return child!;
        },
      ),
      onGenerateRoute: (settings) {
        final index = switch (settings.name) {
          '/workouts' || '/session' => 1,
          '/history' => 2,
          '/progress' => 3,
          _ => 0,
        };
        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, _) =>
              AppShell(index: index, session: settings.name == '/session'),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

const destinations = [
  ('Overview', Icons.grid_view_rounded, '/'),
  ('Workouts', Icons.fitness_center_rounded, '/workouts'),
  ('Activity', Icons.history_rounded, '/history'),
  ('Progress', Icons.insights_rounded, '/progress'),
];

class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: Palette.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const CustomPaint(painter: _FitXLogoPainter()),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          const Text(
            'FitX',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.6,
            ),
          ),
        ],
      ],
    ),
  );
}

class _FitXLogoPainter extends CustomPainter {
  const _FitXLogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.31, size.height * 0.295),
      Offset(size.width * 0.69, size.height * 0.705),
      paint..color = const Color(0xFFF0EFF9),
    );
    canvas.drawLine(
      Offset(size.width * 0.69, size.height * 0.295),
      Offset(size.width * 0.31, size.height * 0.705),
      paint..color = Palette.mint,
    );
  }

  @override
  bool shouldRepaint(covariant _FitXLogoPainter oldDelegate) => false;
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.index, this.session = false});
  final int index;
  final bool session;
  void navigate(BuildContext context, int next) {
    if (next == index && !session) {
      return;
    }
    Navigator.of(context)
        .pushNamedAndRemoveUntil(destinations[next].$3, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = FitnessScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 760;
    final compact = width < 1150;
    final page = session
        ? const SessionScreen()
        : switch (index) {
            1 => const WorkoutsScreen(),
            2 => const HistoryScreen(),
            3 => const ProgressScreen(),
            _ => const DashboardScreen(),
          };
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (!mobile)
              Container(
                width: compact ? 86 : 226,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    right: BorderSide(color: Palette.border(context)),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 30,
                                horizontal: compact ? 20 : 28,
                              ),
                              child: Brand(compact: compact),
                            ),
                            if (!compact)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  25,
                                  28,
                                  12,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'YOUR WORKSPACE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1.7,
                                      color: Palette.muted(context),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            ...List.generate(
                              destinations.length,
                              (i) => Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 13 : 16,
                                  vertical: 4,
                                ),
                                child: Tooltip(
                                  message: compact ? destinations[i].$1 : '',
                                  child: Material(
                                    color: i == index
                                        ? Palette.primary.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => navigate(context, i),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: compact ? 16 : 17,
                                          vertical: 15,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: compact
                                              ? MainAxisAlignment.center
                                              : MainAxisAlignment.start,
                                          children: [
                                            Icon(
                                              destinations[i].$2,
                                              size: 20,
                                              color: i == index
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                  : Palette.muted(context),
                                            ),
                                            if (!compact) ...[
                                              const SizedBox(width: 13),
                                              Text(
                                                destinations[i].$1,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: i == index
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  color: i == index
                                                      ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                      : Palette.muted(context),
                                                ),
                                              ),
                                              const Spacer(),
                                              if (i == index)
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Palette.primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (!compact &&
                                MediaQuery.sizeOf(context).height >= 850)
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Palette.soft(context),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        height: 55,
                                        width: double.infinity,
                                        child: OrbitArt(mint: true),
                                      ),
                                      const SizedBox(height: 15),
                                      const Text(
                                        'A little better,\nevery day.',
                                        style: TextStyle(
                                          fontSize: 17,
                                          height: 1.4,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Small steps. Lasting change.',
                                        style: TextStyle(
                                          fontSize: 10,
                                          height: 1.5,
                                          color: Palette.muted(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Divider(height: 1, color: Palette.border(context)),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: compact
                                    ? MainAxisAlignment.center
                                    : MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 19,
                                    color: Palette.muted(context),
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      'Saved on this browser',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Palette.muted(context),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: mobile ? 68 : 80,
                    padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(color: Palette.border(context)),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (mobile)
                          const Brand()
                        else ...[
                          Text(
                            'Your space',
                            style: TextStyle(
                              fontSize: 11,
                              color: Palette.muted(context),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: Palette.muted(context),
                            ),
                          ),
                          Text(
                            session ? 'Active workout' : destinations[index].$1,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (width >= 550) ...[
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Palette.muted(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            longDate(controller.clock()),
                            style: TextStyle(
                              fontSize: 10,
                              color: Palette.muted(context),
                            ),
                          ),
                          const SizedBox(width: 22),
                        ],
                        Tag(
                          'LOCAL',
                          icon: Icons.lock_outline_rounded,
                          color: Palette.muted(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: PageStorageKey('screen-$index-$session'),
                      padding: EdgeInsets.all(mobile ? 20 : 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StorageBanner(controller: controller),
                              if (controller.data.demo) ...[
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    7,
                                    7,
                                    7,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 22),
                                  decoration: BoxDecoration(
                                    color: Palette.primary.withValues(
                                      alpha: 0.07,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_outlined,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          mobile
                                              ? 'Exploring with sample data'
                                              : 'Take a look around. You’re exploring with sample data.',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          if (await confirm(
                                            context,
                                            title:
                                                'Make room for your journey?',
                                            message: 'This clears all activities, weight entries, hydration, and any active workout. Your selected goal level stays with you.',
                                            label: 'Start fresh',
                                          )) {
                                            if (context.mounted) {
                                              await runAction(
                                                context,
                                                controller.reset,
                                                success: 'A fresh start. Let’s make your first move.',
                                              );
                                            }
                                          }
                                        },
                                        child: const Text(
                                          'Start fresh',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              page,
                              const SizedBox(height: 30),
                              _StorageFooter(controller: controller),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: mobile
          ? NavigationBar(
              height: 70,
              selectedIndex: index,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (i) => navigate(context, i),
              destinations: destinations
                  .map(
                    (d) => NavigationDestination(
                      icon: Icon(d.$2, size: 21),
                      label: d.$1,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }
}

class _StorageBanner extends StatelessWidget {
  const _StorageBanner({required this.controller});
  final FitnessController controller;
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<PersistenceState>(
        valueListenable: controller.persistence,
        builder: (context, status, _) => status.error == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Surface(
                  color: Theme.of(context).colorScheme.errorContainer,
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 19),
                      const Text(
                        'Changes haven’t been saved to this browser.',
                        style: TextStyle(fontSize: 12),
                      ),
                      TextButton(
                        onPressed: () => runAction(
                          context,
                          controller.save,
                          success: 'All changes saved.',
                        ),
                        child: const Text('Retry saving'),
                      ),
                    ],
                  ),
                ),
              ),
      );
}

class _StorageFooter extends StatelessWidget {
  const _StorageFooter({required this.controller});
  final FitnessController controller;
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<PersistenceState>(
        valueListenable: controller.persistence,
        builder: (context, status, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status.unsaved ? Icons.sync_rounded : Icons.lock_outline_rounded,
              size: 11,
              color: Palette.muted(context),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status.error != null
                    ? 'Storage needs attention · use Retry above'
                    : status.unsaved
                    ? 'Saving your changes…'
                    : 'Made for your pace. Saved in this browser.',
                style: TextStyle(fontSize: 9, color: Palette.muted(context)),
              ),
            ),
          ],
        ),
      );
}
