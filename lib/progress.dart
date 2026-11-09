import 'package:flutter/material.dart';

import 'controller.dart';
import 'dialogs.dart';
import 'models.dart';
import 'ui.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int days = 7;
  @override
  Widget build(BuildContext context) {
    final controller = FitnessScope.of(context);
    final cutoff = dateOnly(controller.clock())
        .subtract(Duration(days: days - 1));
    final workouts = controller.data.workouts
        .where((w) => !dateOnly(w.date).isBefore(cutoff))
        .toList();
    final minutes = workouts.fold(0, (sum, w) => sum + w.minutes);
    final calories = workouts.fold(0, (sum, w) => sum + w.calories);
    final activeDays = workouts.map((w) => dayKey(w.date)).toSet().length;
    final total = controller.data.workouts.length;
    final weight = controller.currentWeight;
    final chronologicalWeights = controller.sortedWeights;
    final weights = chronologicalWeights.reversed.toList(growable: false);
    final difference = weights.length < 2
        ? null
        : weights.first.kg - weights.last.kg;
    final achievements = [
      ('First step', 'Log your first workout', Icons.flag_outlined, total >= 1),
      (
        'Finding a rhythm',
        'Complete 10 workouts',
        Icons.bolt_rounded,
        total >= 10,
      ),
      (
        'Making it a habit',
        'Complete 25 workouts',
        Icons.workspace_premium_outlined,
        total >= 25,
      ),
      (
        'Time for yourself',
        'Log 300 active minutes',
        Icons.timer_outlined,
        controller.data.workouts.fold(0, (s, w) => s + w.minutes) >= 300,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(
          title: 'Look how far you’ve come.',
          subtitle: 'Zoom out. See your growth. Celebrate the little wins.',
          eyebrow: 'YOUR PROGRESS',
          action: OutlinedButton.icon(
            onPressed: () => showWeightForm(context),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Log weight'),
          ),
        ),
        const SizedBox(height: 26),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 7,
                label: Text('Last 7 days', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: 28,
                label: Text('Last 28 days', style: TextStyle(fontSize: 11)),
              ),
            ],
            selected: {days},
            onSelectionChanged: (v) => setState(() => days = v.first),
          ),
        ),
        const SizedBox(height: 22),
        ResponsiveGrid(
          minWidth: 145,
          children: [
            MetricCard(
              label: 'Workouts completed',
              value: '$total',
              unit: 'all time',
              icon: Icons.fitness_center_rounded,
              color: Palette.primary,
              progress: total / 25,
              caption: '${workouts.length} in the last $days days',
            ),
            MetricCard(
              label: 'Active time',
              value: number(minutes),
              unit: 'min',
              icon: Icons.timer_outlined,
              color: const Color(0xFF3F9B79),
              progress:
                  minutes / (controller.data.goalLevel.dailyMinutes * days),
              caption: 'In the last $days days',
            ),
            MetricCard(
              label: 'Calories burned',
              value: number(calories),
              unit: 'kcal',
              icon: Icons.local_fire_department_outlined,
              color: Palette.orange,
              progress:
                  calories / (controller.data.goalLevel.dailyCalories * days),
              caption: 'In the last $days days',
            ),
            MetricCard(
              label: 'Days you showed up',
              value: '$activeDays',
              unit: '/ $days days',
              icon: Icons.calendar_today_outlined,
              color: Palette.blue,
              progress: activeDays / days,
              caption: 'Small steps make a difference',
            ),
          ],
        ),
        const SizedBox(height: 24),
        TwoColumn(
          breakpoint: 820,
          left: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  'Consistency looks good on you',
                  subtitle: 'Tap a bar to explore your active minutes.',
                ),
                const SizedBox(height: 28),
                ActivityChart(
                  values: controller.activitySeries(days),
                  endDate: controller.clock(),
                  goal: controller.data.goalLevel.dailyMinutes.toDouble(),
                  height: 210,
                ),
              ],
            ),
          ),
          right: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  'How you like to move',
                  subtitle: 'Active minutes by workout type.',
                ),
                const SizedBox(height: 24),
                if (workouts.isEmpty)
                  const EmptyState(
                    icon: Icons.donut_small_rounded,
                    title: 'Find your mix',
                    message:
                        'Your activity breakdown will grow with every workout.',
                  )
                else
                  ...ActivityType.values
                      .where((type) => workouts.any((w) => w.type == type))
                      .map((type) {
                        final value = workouts
                            .where((w) => w.type == type)
                            .fold(0, (s, w) => s + w.minutes);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 19),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(type.icon, color: type.color, size: 15),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      type.label,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$value min',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Palette.muted(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: value / minutes,
                                  minHeight: 5,
                                  color: type.color,
                                  backgroundColor: type.color.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        TwoColumn(
          breakpoint: 820,
          left: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  'Your weight trend',
                  subtitle: 'All entries · kilograms',
                  action: TextButton(
                    onPressed: () => showWeightForm(context),
                    child: const Text(
                      '+ Log weight',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                WeightChart(entries: chronologicalWeights),
                const SizedBox(height: 15),
                const Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    Tag(
                      'Your weight',
                      icon: Icons.circle,
                      color: Palette.primary,
                    ),
                  ],
                ),
                if (weights.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(
                      'Weight history (${weights.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    children: weights
                        .map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              '${entry.kg.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              longDate(entry.date),
                              style: const TextStyle(fontSize: 10),
                            ),
                            trailing: IconButton(
                              tooltip: 'Delete weight entry',
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 17,
                              ),
                              onPressed: () async {
                                if (await confirm(
                                  context,
                                  title: 'Delete weight entry?',
                                  message:
                                      '${entry.kg} kg on ${shortDate(entry.date)} will be removed from your trend.',
                                  label: 'Delete entry',
                                  destructive: true,
                                )) {
                                  if (context.mounted) {
                                    await runAction(
                                      context,
                                      () => controller.removeWeight(entry.date),
                                      success: 'Weight entry deleted.',
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          right: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconTile(
                  Icons.monitor_weight_outlined,
                  color: Palette.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Latest weight',
                  style: TextStyle(fontSize: 11, color: Palette.muted(context)),
                ),
                const SizedBox(height: 8),
                Text(
                  weights.isEmpty ? '— kg' : '${weight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 13),
                if (difference != null)
                  Tag(
                    '${difference > 0 ? '+' : ''}${difference.toStringAsFixed(1)} kg since first entry',
                    color: Palette.primary,
                  ),
                const SizedBox(height: 25),
                Divider(color: Palette.border(context)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      'First logged weight',
                      style: TextStyle(
                        fontSize: 11,
                        color: Palette.muted(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      weights.isEmpty
                          ? '—'
                          : '${weights.last.kg.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  weights.isEmpty
                      ? 'Log your weight to start seeing your trend.'
                      : 'Small changes add up. Keep tracking your progress at your own pace.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Palette.muted(context),
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 18),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/'),
                  icon: const Icon(Icons.tune_rounded, size: 15),
                  label: const Text(
                    'View activity goals',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const SectionHeading(
          'Little wins. Real momentum.',
          subtitle: 'Milestones earned through your activity.',
        ),
        const SizedBox(height: 20),
        ResponsiveGrid(
          minWidth: 180,
          children: achievements
              .map(
                (a) => Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTile(
                        a.$3,
                        color: a.$4 ? Palette.primary : Palette.muted(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        a.$1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        a.$2,
                        style: TextStyle(
                          fontSize: 10,
                          color: Palette.muted(context),
                        ),
                      ),
                      const SizedBox(height: 13),
                      Tag(
                        a.$4 ? 'Earned' : 'Keep going',
                        icon: a.$4
                            ? Icons.check_rounded
                            : Icons.lock_outline_rounded,
                        color: a.$4
                            ? const Color(0xFF3F9B79)
                            : Palette.muted(context),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
