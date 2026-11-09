import 'dart:async';

import 'package:flutter/material.dart';

import 'controller.dart';
import 'dialogs.dart';
import 'models.dart';
import 'ui.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});
  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  ActivityType? filter;
  @override
  Widget build(BuildContext context) {
    final controller = FitnessScope.of(context);
    final filtered = plans
        .where((p) => filter == null || p.type == filter)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(
          title: 'Move your way.',
          subtitle: 'Find a workout that fits your energy. We’ll keep track of the rest.',
          eyebrow: 'YOUR WORKOUT SPACE',
          action: OutlinedButton.icon(
            onPressed: () => showWorkoutForm(context),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Log your own'),
          ),
        ),
        const SizedBox(height: 26),
        if (controller.data.session != null) ...[
          Surface(
            color: Palette.primary.withValues(alpha: 0.07),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 20,
              runSpacing: 16,
              children: [
                const IconTile(Icons.play_arrow_rounded),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your workout is waiting',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      controller.data.session!.plan.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Palette.muted(context),
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/session'),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Resume workout'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        Surface(
          padding: const EdgeInsets.all(26),
          child: Row(
            children: [
              const IconTile(
                Icons.favorite_border_rounded,
                color: Color(0xFF3F9B79),
                size: 52,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A good workout starts with you.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Six guided routines. No subscriptions. Just you, showing up. Choose a comfortable pace and take breaks whenever you need.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Palette.muted(context),
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 8,
          runSpacing: 9,
          children: [
            ChoiceChip(
              label: const Text('All workouts', style: TextStyle(fontSize: 11)),
              selected: filter == null,
              onSelected: (_) => setState(() => filter = null),
            ),
            ...ActivityType.values.map(
              (type) => ChoiceChip(
                avatar: Icon(
                  type.icon,
                  size: 15,
                  color: filter == type
                      ? Theme.of(context).colorScheme.primary
                      : Palette.muted(context),
                ),
                label: Text(type.label, style: const TextStyle(fontSize: 11)),
                selected: filter == type,
                onSelected: (_) => setState(() => filter = type),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ResponsiveGrid(
          minWidth: 255,
          maxColumns: 3,
          gap: 22,
          children: filtered.map((p) => _PlanCard(plan: p)).toList(),
        ),
      ],
    );
  }
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({required this.plan});
  final WorkoutPlan plan;
  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, hover ? -4 : 0, 0),
        child: Surface(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 120,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: p.type.color.withValues(alpha: 0.09),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -35,
                      width: 230,
                      height: 190,
                      child: Opacity(opacity: 0.4, child: OrbitArt(mint: true)),
                    ),
                    Positioned(
                      left: 23,
                      top: 25,
                      child: Icon(p.type.icon, size: 68, color: p.type.color),
                    ),
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Tag(
                        p.type.label.toUpperCase(),
                        color: p.type.color,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: Text(
                        p.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.8,
                          color: Palette.muted(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Tag(
                          '${p.minutes} min',
                          color: p.type.color,
                          icon: Icons.timer_outlined,
                        ),
                        Tag(p.level, color: p.type.color),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => showPlan(context, p),
                        label: const Text(
                          'View workout',
                          style: TextStyle(fontSize: 11),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showPlan(BuildContext context, WorkoutPlan plan) async {
  final start = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconTile(plan.type.icon, color: plan.type.color),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                plan.title,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                plan.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Palette.muted(context),
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Tag(
                    '${plan.minutes} minutes',
                    color: plan.type.color,
                    icon: Icons.timer_outlined,
                  ),
                  Tag(plan.level, color: plan.type.color),
                  Tag(
                    '${plan.exercises.length} exercises',
                    color: plan.type.color,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'YOUR SESSION',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ...plan.exercises.indexed.map(
                (pair) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 29,
                        height: 29,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Palette.soft(context),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '${pair.$1 + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pair.$2.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              pair.$2.prescription,
                              style: TextStyle(
                                fontSize: 11,
                                color: Palette.muted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start this workout'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (start != true || !context.mounted) {
    return;
  }
  final controller = FitnessScope.of(context);
  if (controller.data.session != null) {
    toast(
      context,
      'You have a workout in progress. Finish or discard it before starting another.',
    );
    Navigator.pushNamed(context, '/session');
    return;
  }
  final ok = await runAction(context, () => controller.startSession(plan));
  if (ok && context.mounted) {
    Navigator.pushNamed(context, '/session');
  }
}

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  bool busy = false;

  Future<void> finish(FitnessController controller) async {
    final session = controller.data.session;
    if (session == null) {
      return;
    }
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => _FinishDialog(
        completed: session.completed.length,
        total: session.plan.exercises.length,
      ),
    );
    if (notes == null || !mounted) {
      return;
    }
    setState(() => busy = true);
    try {
      final workout = await controller.finishSession(notes: notes);
      if (!mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(context, '/history', (_) => false);
      toast(
        context,
        '${workout.minutes} minutes for a stronger you. Workout saved!',
      );
    } catch (_) {
      if (mounted) {
        setState(() => busy = false);
        toast(
          context,
          'Your workout is in memory. Retry saving using the storage banner.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = FitnessScope.of(context);
    final session = controller.data.session;
    if (session == null) {
      return Surface(
        child: EmptyState(
          icon: Icons.fitness_center_rounded,
          title: 'Ready when you are',
          message: 'Choose a routine to start your next workout.',
          action: FilledButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/workouts'),
            child: const Text('Explore workouts'),
          ),
        ),
      );
    }
    final plan = session.plan;
    final done = session.completed.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(
          title: plan.title,
          subtitle: 'Take your time. Focus on your form. This is your session.',
          eyebrow: 'YOU’RE SHOWING UP',
          action: OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/workouts'),
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('Workout library'),
          ),
        ),
        const SizedBox(height: 26),
        TwoColumn(
          breakpoint: 820,
          left: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeading(
                  'Your session',
                  subtitle: 'Check off each exercise as you go.',
                  action: Tag('$done / ${plan.exercises.length} done'),
                ),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: done / plan.exercises.length,
                    minHeight: 5,
                    backgroundColor: Palette.primary.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(height: 20),
                ...plan.exercises.indexed.map((pair) {
                  final checked = session.completed.contains(pair.$1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: checked
                              ? Palette.primary.withValues(alpha: 0.2)
                              : Palette.border(context),
                        ),
                      ),
                      child: Material(
                        color: checked
                            ? Palette.primary.withValues(alpha: 0.06)
                            : Palette.soft(context),
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: CheckboxListTile(
                          value: checked,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          onChanged: busy
                              ? null
                              : (_) => runAction(
                                  context,
                                  () => controller.toggleExercise(pair.$1),
                                ),
                          title: Text(
                            pair.$2.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              decoration: checked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                pair.$2.prescription,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                pair.$2.tip,
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.7,
                                  color: Palette.muted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          right: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Surface(
                child: Column(
                  children: [
                    Tag(
                      session.runningSince == null ? 'PAUSED' : 'IN PROGRESS',
                      icon: session.runningSince == null
                          ? Icons.pause_rounded
                          : Icons.circle,
                      color: session.runningSince == null
                          ? Palette.orange
                          : const Color(0xFF3F9B79),
                    ),
                    _SessionMetrics(
                      session: session,
                      weight: controller.currentWeight,
                      clock: controller.clock,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () =>
                                  runAction(context, controller.toggleSession),
                        icon: Icon(
                          session.runningSince == null
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          size: 18,
                        ),
                        label: Text(
                          session.runningSince == null
                              ? 'Resume timer'
                              : 'Pause timer',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy ? null : () => finish(controller),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(busy ? 'Saving…' : 'Finish workout'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () async {
                              if (await confirm(
                                context,
                                title: 'Discard this workout?',
                                message: 'Your current timer and exercise progress will be removed. This session won’t be added to your history.',
                                label: 'Discard session',
                                destructive: true,
                              )) {
                                if (!context.mounted) {
                                  return;
                                }
                                final ok = await runAction(
                                  context,
                                  controller.discardSession,
                                );
                                if (ok && context.mounted) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/workouts',
                                  );
                                }
                              }
                            },
                      child: Text(
                        'Discard session',
                        style: TextStyle(
                          fontSize: 10,
                          color: Palette.muted(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Surface(
                color: Palette.primary.withValues(alpha: 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 23,
                      color: Palette.primary,
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Your progress stays with you.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can leave this page or refresh. Your timer and completed exercises are saved locally.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.8,
                        color: Palette.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionMetrics extends StatefulWidget {
  const _SessionMetrics({
    required this.session,
    required this.weight,
    required this.clock,
  });
  final ActiveSession session;
  final double weight;
  final DateTime Function() clock;
  @override
  State<_SessionMetrics> createState() => _SessionMetricsState();
}

class _SessionMetricsState extends State<_SessionMetrics> {
  Timer? _timer;
  void _syncTimer() {
    if (widget.session.runningSince == null) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _SessionMetrics oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = widget.session.secondsAt(widget.clock()).clamp(0, 86400);
    return Column(
      children: [
        const SizedBox(height: 30),
        Text(
          durationLabel(elapsed),
          style: const TextStyle(
            fontSize: 33,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ELAPSED TIME',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.6,
            color: Palette.muted(context),
          ),
        ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department_outlined,
              size: 18,
              color: Palette.orange,
            ),
            const SizedBox(width: 6),
            Text(
              '~${(widget.session.plan.type.met * 3.5 * widget.weight / 200 * elapsed / 60).round()} kcal',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Calories are an estimate.',
          style: TextStyle(fontSize: 9, color: Palette.muted(context)),
        ),
      ],
    );
  }
}

class _FinishDialog extends StatefulWidget {
  const _FinishDialog({required this.completed, required this.total});
  final int completed, total;
  @override
  State<_FinishDialog> createState() => _FinishDialogState();
}

class _FinishDialogState extends State<_FinishDialog> {
  final notes = TextEditingController();
  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(
      'That’s time well spent.',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    ),
    content: SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.completed == widget.total
                ? 'You completed every exercise. Take a moment to appreciate your effort.'
                : '${widget.completed} of ${widget.total} exercises checked off. You can save a partial workout — every effort counts.',
            style: TextStyle(
              fontSize: 12,
              height: 1.8,
              color: Palette.muted(context),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: notes,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'How did it feel? (optional)',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Keep going'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, notes.text.trim()),
        child: const Text('Save workout'),
      ),
    ],
  );
}
